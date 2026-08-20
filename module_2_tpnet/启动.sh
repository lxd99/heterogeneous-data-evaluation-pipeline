#!/usr/bin/env bash
set -Eeuo pipefail
MODULE_ROOT="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$MODULE_ROOT/.." && pwd)"
REPO="$ROOT/repos/TPNet"
PY="$ROOT/envs/graph/bin/python"
COMMIT=7dd0cf49695a581c5c541baeda47c1b5e98e8748
MODE="${1:-eval}"

prepare() {
  mkdir -p "$ROOT/repos" "$ROOT/envs" "$MODULE_ROOT/logs" "$MODULE_ROOT/results"
  if [[ ! -d "$REPO/.git" ]]; then git clone https://github.com/lxd99/TPNet.git "$REPO"; fi
  git -C "$REPO" fetch --all --tags
  git -C "$REPO" checkout --detach "$COMMIT"
  if git -C "$REPO" apply --check "$ROOT/patches/TPNet.patch" 2>/dev/null; then
    git -C "$REPO" apply "$ROOT/patches/TPNet.patch"
  fi
  PYTHON_BIN="${PYTHON_BIN:-python3.9}"
  [[ -x "$PY" ]] || "$PYTHON_BIN" -m venv "$ROOT/envs/graph"
  "$PY" -m pip install --upgrade pip setuptools wheel
  "$PY" -m pip install -r "$ROOT/requirements/graph.txt"
  mkdir -p "$REPO/DG_data" "$REPO/processed_data" "$REPO/saved_models" "$REPO/saved_results" "$REPO/logs" "$REPO/wandb"
  zip="$REPO/DG_data/UNtrade.zip"
  [[ -s "$zip" ]] || curl -fL --retry 5 'https://zenodo.org/records/7213796/files/UNtrade.zip?download=1' -o "$zip"
  echo "b7b59f4606e25588612d96403690c306  $zip" | md5sum -c -
  [[ -d "$REPO/DG_data/UNtrade" ]] || unzip -q "$zip" -d "$REPO/DG_data"
  (cd "$REPO/preprocess_data" && "$PY" preprocess_data.py --dataset_name UNtrade)
  EVAL_ROOT="$ROOT" bash "$ROOT/scripts/fetch_tpnet_selected.sh"
}

train_three() {
  [[ -x "$PY" && -d "$REPO/processed_data/UNtrade" ]] || { echo "Run prepare first." >&2; exit 2; }
  for seed in 0 1 2; do
    echo "[TRAIN] TPNet UN Trade seed=$seed"
    EVAL_ROOT="$ROOT" DATASET=UNtrade GPU="${GPU:-0}" RUNS=1 RUN_OFFSET="$seed" EPOCHS="${EPOCHS:-100}" \
      PREFIX_SUFFIX="_untrade_seed${seed}" bash "$ROOT/scripts/run_tpnet_full.sh"
  done
}

eval_three() {
  [[ -x "$PY" ]] || { echo "Run prepare first." >&2; exit 2; }
  mkdir -p "$MODULE_ROOT/logs" "$MODULE_ROOT/results/tpnet" "$MODULE_ROOT/results/efficiency"
  for seed in 0 1 2; do
    prefix="test_report_full_readme_untrade_seed${seed}_UNtrade"
    checkpoint="$REPO/saved_models/${prefix}_link_UNtrade_TPNet_seed${seed}.pkl"
    [[ -f "$checkpoint" ]] || { echo "Missing checkpoint: $checkpoint" >&2; exit 2; }
    echo "[EVAL] TPNet UN Trade seed=$seed"
    (cd "$REPO" && CUDA_VISIBLE_DEVICES="${GPU:-0}" WANDB_MODE=disabled PYTHONPATH="$REPO" \
      TPNET_EVAL_RUN_OFFSET="$seed" TPNET_EVAL_RESULT_DIR="$MODULE_ROOT/results/tpnet" \
      "$PY" "$MODULE_ROOT/evaluate_fixed_seeds.py" --prefix "$prefix" --dataset_name UNtrade \
      --model_name TPNet --num_runs 1 --gpu 0 --use_random_projection --load_best_configs) \
      2>&1 | tee "$MODULE_ROOT/logs/eval_seed${seed}.log"
  done
  EVAL_ROOT="$ROOT" GPU="${GPU:-0}" bash "$ROOT/scripts/run_tpnet_efficiency.sh"
  cp "$ROOT/results/tpnet_efficiency/"*.json "$MODULE_ROOT/results/efficiency/"
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
