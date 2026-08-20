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
  if ! "$PY" -c 'import torch_sparse' >/dev/null 2>&1; then
    "$PY" -m pip install torch-scatter torch-sparse \
      -f "${PYG_WHEEL_URL:-https://data.pyg.org/whl/torch-2.0.1+cu117.html}"
  fi
}

prepare_data() {
  [[ -x "$PY" && -d "$REPO" ]] || { echo "Run prepare first." >&2; exit 2; }
  mkdir -p "$MODULE_ROOT/logs" "$MODULE_ROOT/results"
  # The pinned preprocessor hard-codes cuda:1; map it to cuda:0 on the selected GPU.
  sed "s/'cuda': 1,/'cuda': 0,/" "$REPO/preprocess_data/preprocess_ogbn_mag.py" \
    > "$MODULE_ROOT/results/preprocess_ogbn_mag_cuda0.py"
  (cd "$REPO/preprocess_data" && CUDA_VISIBLE_DEVICES="${GPU:-0}" PYTHONPATH="$REPO" \
    "$PY" "$MODULE_ROOT/results/preprocess_ogbn_mag_cuda0.py") \
    2>&1 | tee "$MODULE_ROOT/logs/preprocess.log"
}

train() {
  [[ -x "$PY" && -d "$REPO" ]] || { echo "Run prepare first." >&2; exit 2; }
  if [[ "${PREPROCESS:-0}" == "1" ]]; then prepare_data; fi
  data="$REPO/dataset/OGB_MAG/OGB_MAG.pkl"
  [[ -f "$data" ]] || {
    echo "Missing $data. Run: PREPROCESS=1 GPU=0 bash 启动.sh train" >&2
    exit 2
  }
  mkdir -p "$MODULE_ROOT/logs"
  (cd "$REPO/train" && CUDA_VISIBLE_DEVICES="${GPU:-0}" PYTHONPATH="$REPO" \
    "$PY" train_R_HGNN_ogbn_mag_node_classification.py) \
    2>&1 | tee "$MODULE_ROOT/logs/train.log"
}

checkpoint_eval() {
  checkpoint="$REPO/save_model/OGB_MAG/R_HGNN_lr0.001_dropout0.5_seed_0/R_HGNN_lr0.001_dropout0.5_seed_0.pkl"
  [[ -x "$PY" && -f "$checkpoint" ]] || {
    echo "Missing trained checkpoint: $checkpoint" >&2
    exit 2
  }
  mkdir -p "$MODULE_ROOT/logs"
  (cd "$REPO/test" && CUDA_VISIBLE_DEVICES="${GPU:-0}" PYTHONPATH="$REPO" \
    "$PY" eval_R_HGNN_ogbn_mag_node_classification.py) \
    2>&1 | tee "$MODULE_ROOT/logs/checkpoint_eval.log"
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
  data) prepare_data ;;
  train) train ;;
  checkpoint) checkpoint_eval ;;
  eval) eval_three ;;
  all) prepare; PREPROCESS=1 train; eval_three ;;
  help|-h|--help) echo "Usage: bash 启动.sh {prepare|data|train|checkpoint|eval|all|help}" ;;
  *) echo "Unknown mode: $MODE" >&2; exit 2 ;;
esac
