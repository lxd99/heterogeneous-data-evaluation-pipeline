#!/usr/bin/env bash
set -Eeuo pipefail
MODULE_ROOT="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$MODULE_ROOT/.." && pwd)"
TPNET_REPO="$ROOT/repos/TPNet"
PY="$ROOT/envs/graph/bin/python"
TPNET_COMMIT=7dd0cf49695a581c5c541baeda47c1b5e98e8748
MODE="${1:-eval}"

prepare() {
  mkdir -p "$ROOT/repos" "$ROOT/envs" "$MODULE_ROOT/logs" "$MODULE_ROOT/results"
  if [[ ! -d "$TPNET_REPO/.git" ]]; then git clone https://github.com/lxd99/TPNet.git "$TPNET_REPO"; fi
  git -C "$TPNET_REPO" fetch --all --tags
  git -C "$TPNET_REPO" checkout --detach "$TPNET_COMMIT"
  if git -C "$TPNET_REPO" apply --check "$ROOT/patches/TPNet.patch" 2>/dev/null; then
    git -C "$TPNET_REPO" apply "$ROOT/patches/TPNet.patch"
  fi
  PYTHON_BIN="${PYTHON_BIN:-python3.9}"
  [[ -x "$PY" ]] || "$PYTHON_BIN" -m venv "$ROOT/envs/graph"
  "$PY" -m pip install --upgrade pip setuptools wheel
  "$PY" -m pip install -r "$ROOT/requirements/graph.txt"
  mkdir -p "$TPNET_REPO/DG_data" "$TPNET_REPO/processed_data" "$TPNET_REPO/saved_models" "$TPNET_REPO/saved_results" "$TPNET_REPO/logs" "$TPNET_REPO/wandb"
  zip="$TPNET_REPO/DG_data/UNtrade.zip"
  [[ -s "$zip" ]] || curl -fL --retry 5 'https://zenodo.org/records/7213796/files/UNtrade.zip?download=1' -o "$zip"
  echo "b7b59f4606e25588612d96403690c306  $zip" | md5sum -c -
  [[ -d "$TPNET_REPO/DG_data/UNtrade" ]] || unzip -q "$zip" -d "$TPNET_REPO/DG_data"
  (cd "$TPNET_REPO/preprocess_data" && "$PY" preprocess_data.py --dataset_name UNtrade)
}

train_three() {
  [[ -x "$PY" && -d "$TPNET_REPO/processed_data/UNtrade" ]] || { echo "Run prepare first." >&2; exit 2; }
  for seed in 0 1 2; do
    echo "[TRAIN] TPNet UN Trade seed=$seed"
    EVAL_ROOT="$ROOT" DATASET=UNtrade GPU="${GPU:-0}" RUNS=1 RUN_OFFSET="$seed" EPOCHS="${EPOCHS:-100}" \
      PREFIX_SUFFIX="_untrade_seed${seed}" bash "$ROOT/scripts/run_tpnet_full.sh"
  done
}

eval_three() {
  [[ -x "$PY" ]] || { echo "Run prepare first." >&2; exit 2; }
  mkdir -p "$MODULE_ROOT/logs" "$MODULE_ROOT/results/tpnet"
  for seed in 0 1 2; do
    prefix="test_report_full_readme_untrade_seed${seed}_UNtrade"
    checkpoint="$TPNET_REPO/saved_models/${prefix}_link_UNtrade_TPNet_seed${seed}.pkl"
    [[ -f "$checkpoint" ]] || { echo "Missing checkpoint: $checkpoint" >&2; exit 2; }
    echo "[EVAL] TPNet UN Trade seed=$seed"
    (cd "$TPNET_REPO" && CUDA_VISIBLE_DEVICES="${GPU:-0}" WANDB_MODE=disabled PYTHONPATH="$TPNET_REPO" \
      TPNET_EVAL_RUN_OFFSET="$seed" TPNET_EVAL_RESULT_DIR="$MODULE_ROOT/results/tpnet" \
      "$PY" "$MODULE_ROOT/evaluate_fixed_seeds.py" --prefix "$prefix" --dataset_name UNtrade \
      --model_name TPNet --num_runs 1 --gpu 0 --use_random_projection --load_best_configs) \
      2>&1 | tee "$MODULE_ROOT/logs/eval_seed${seed}.log"
  done
  "$PY" "$MODULE_ROOT/summarize.py" --results "$MODULE_ROOT/results" --output "$MODULE_ROOT/results/summary.json"
}

case "$MODE" in
  prepare) prepare ;;
  train) train_three ;;
  eval) eval_three ;;
  all) prepare; train_three; eval_three ;;
  help|-h|--help) echo "Usage: bash 启动.sh {prepare|train|eval|all|help}" ;;
  *) echo "Unknown mode: $MODE" >&2; exit 2 ;;
esac
