#!/usr/bin/env bash
set -Eeuo pipefail
MODULE_ROOT="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$MODULE_ROOT/.." && pwd)"
REPO="$ROOT/repos/SMP"
PY="$ROOT/envs/smp/bin/python"
COMMIT=c89634ae79c7845066e33cc48cee96cd4dbc1d89
MODE="${1:-eval}"

prepare() {
  mkdir -p "$ROOT/repos" "$ROOT/envs" "$ROOT/data/models" "$MODULE_ROOT/logs" "$MODULE_ROOT/results"
  if [[ ! -d "$REPO/.git" ]]; then git clone https://github.com/kongds/SMP.git "$REPO"; fi
  git -C "$REPO" fetch --all --tags
  git -C "$REPO" checkout --detach "$COMMIT"
  PYTHON_BIN="${PYTHON_BIN:-python3.9}"
  [[ -x "$PY" ]] || "$PYTHON_BIN" -m venv "$ROOT/envs/smp"
  "$PY" -m pip install --upgrade pip setuptools wheel
  "$PY" -m pip install -r "$ROOT/requirements/smp.txt"
  (cd "$ROOT" && "$PY" - <<'PY'
from pathlib import Path
from transformers import AutoModelForSequenceClassification, AutoTokenizer
out=Path('data/models/bert-base-uncased'); out.mkdir(parents=True,exist_ok=True)
AutoTokenizer.from_pretrained('bert-base-uncased').save_pretrained(out)
AutoModelForSequenceClassification.from_pretrained('bert-base-uncased',num_labels=3).save_pretrained(out)
PY
  )
  zip="$ROOT/data/mnli_0.50_kd_mag.npy.zip"
  [[ -s "$zip" ]] || curl -fL --retry 3 https://github.com/kongds/SMP/releases/download/SMP-S/mnli_0.50_kd_mag.npy.zip -o "$zip"
  unzip -o "$zip" -d "$ROOT/data"
}

train() {
  [[ -x "$PY" && -d "$REPO" ]] || { echo "Run prepare first." >&2; exit 2; }
  echo "[TRAIN] Upstream SMP pruning: mnli_0.50_kd_mag"
  (cd "$REPO" && PATH="$(dirname "$PY"):$PATH" bash run.sh mnli_0.50_kd_mag)
}

eval_three() {
  [[ -x "$PY" && -f "$ROOT/data/mnli_0.50_kd_mag.npy" ]] || { echo "Run prepare first." >&2; exit 2; }
  mkdir -p "$MODULE_ROOT/logs" "$MODULE_ROOT/results"
  for run in 1 2 3; do
    echo "[SMP][RUN $run/3]"
    TRANSFORMERS_VERBOSITY=error CUDA_VISIBLE_DEVICES="${GPU:-0}" \
      "$PY" "$ROOT/scripts/smp_profile.py" 2>&1 | tee "$MODULE_ROOT/logs/run_${run}.log"
  done
  "$PY" "$MODULE_ROOT/summarize.py" --logs "$MODULE_ROOT/logs" --output "$MODULE_ROOT/results/summary.json"
}

case "$MODE" in
  prepare) prepare ;;
  train) train ;;
  eval) eval_three ;;
  all) prepare; train; eval_three ;;
  help|-h|--help) echo "Usage: bash 启动.sh {prepare|train|eval|all|help}" ;;
  *) echo "Unknown mode: $MODE" >&2; exit 2 ;;
esac
