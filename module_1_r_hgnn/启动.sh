#!/usr/bin/env bash
set -Eeuo pipefail
MODULE_ROOT="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$MODULE_ROOT/.." && pwd)"
REPO="$ROOT/repos/R-HGNN"
PY="$ROOT/envs/graph/bin/python"
COMMIT=b6440ed910d6d47b1f6911549c24a0c0644cb0ea
MODE="${1:-eval}"

prepare() {
  mkdir -p "$ROOT/repos" "$ROOT/envs" "$MODULE_ROOT/logs" "$MODULE_ROOT/results"
  if [[ ! -d "$REPO/.git" ]]; then
    git clone https://github.com/yule-BUAA/R-HGNN.git "$REPO"
  fi
  git -C "$REPO" fetch --all --tags
  git -C "$REPO" checkout --detach "$COMMIT"
  PYTHON_BIN="${PYTHON_BIN:-python3.9}"
  [[ -x "$PY" ]] || "$PYTHON_BIN" -m venv "$ROOT/envs/graph"
  "$PY" -m pip install --upgrade pip setuptools wheel
  "$PY" -m pip install -r "$ROOT/requirements/graph.txt"
}

train() {
  [[ -d "$REPO" ]] || { echo "Run prepare first." >&2; exit 2; }
  cat <<'NOTICE'
R-HGNN full OGB-MAG training uses the upstream entry and preprocessed OGB-MAG data.
Follow https://github.com/yule-BUAA/R-HGNN at the pinned commit.
The Table 6-7 parameter evaluation itself does not require a trained checkpoint.
NOTICE
}

eval_three() {
  [[ -x "$PY" && -d "$REPO" ]] || { echo "Run: bash 启动.sh prepare" >&2; exit 2; }
  mkdir -p "$MODULE_ROOT/logs" "$MODULE_ROOT/results"
  for run in 1 2 3; do
    echo "[R-HGNN][RUN $run/3]"
    EVAL_ROOT="$ROOT" CUDA_VISIBLE_DEVICES="${GPU:-0}" \
      "$PY" "$ROOT/scripts/r_hgnn_profile.py" 2>&1 | tee "$MODULE_ROOT/logs/run_${run}.log"
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
