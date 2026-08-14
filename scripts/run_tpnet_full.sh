#!/usr/bin/env bash
set -u -o pipefail

ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
REPO="$ROOT/repos/TPNet"
PY="$ROOT/envs/graph/bin/python"
DATASET=${DATASET:?DATASET is required}
GPU=${GPU:?GPU is required}
RUNS=${RUNS:-5}
EPOCHS=${EPOCHS:-100}
RUN_OFFSET=${RUN_OFFSET:-0}
RUN_KIND="full_readme${PREFIX_SUFFIX:-}"
PREFIX="test_report_${RUN_KIND}_${DATASET}"
OUT="$ROOT/logs/TPNet/${DATASET}_${RUN_KIND}_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$ROOT/logs/TPNet" "$REPO/logs" "$REPO/saved_results" \
  "$REPO/saved_models" "$REPO/wandb"

if [[ "$DATASET" == "mooc" && "${TPNET_CHILD:-0}" != "1" && "$RUNS" == "5" ]]; then
  TPNET_CHILD=1 RUNS=3 RUN_OFFSET=0 GPU="$GPU" PREFIX_SUFFIX=_part0 \
    "$0" &
  first_pid=$!
  TPNET_CHILD=1 RUNS=2 RUN_OFFSET=3 GPU="${SECOND_GPU:-4}" PREFIX_SUFFIX=_part1 \
    "$0" &
  second_pid=$!
  first_code=0
  second_code=0
  wait "$first_pid" || first_code=$?
  wait "$second_pid" || second_code=$?
  if [[ "$first_code" -ne 0 || "$second_code" -ne 0 ]]; then
    echo "[PARALLEL] mooc child exit codes: $first_code $second_code" >&2
    exit 1
  fi
  touch "$ROOT/results/tpnet_mooc_parallel.complete"
  exit 0
fi

cd "$REPO"

COMMAND=(
  "$PY" train_link_prediction.py
  --prefix "$PREFIX"
  --dataset_name "$DATASET"
  --model_name TPNet
  --num_runs "$RUNS"
  --num_epochs "$EPOCHS"
  --gpu 0
  --use_random_projection
  --load_best_configs
)

{
  echo "[TEST_REPORT] method=TPNet dataset=$DATASET run=$RUN_KIND"
  echo "timestamp=$(date -Iseconds)"
  echo "repo=$REPO"
  echo "commit=$(git rev-parse HEAD)"
  echo "python=$PY"
  echo "gpu_physical=$GPU"
  echo "epochs=$EPOCHS"
  echo "runs=$RUNS"
  printf "command="
  printf "%q " "${COMMAND[@]}"
  printf "\n"
} | tee "$OUT"

set +e
CUDA_VISIBLE_DEVICES="$GPU" WANDB_MODE=disabled PYTHONUNBUFFERED=1 \
  TPNET_RUN_OFFSET="$RUN_OFFSET" \
  "${COMMAND[@]}" 2>&1 | tee -a "$OUT"
code=${PIPESTATUS[0]}
set -e

internal="$REPO/logs/${PREFIX}_link_${DATASET}_TPNet.log"
if [[ -f "$internal" ]]; then
  printf "\n[INTERNAL_LOG] %s\n" "$internal" | tee -a "$OUT"
  cat "$internal" | tee -a "$OUT"
fi
printf "\n[EXIT] code=%s timestamp=%s\n" "$code" "$(date -Iseconds)" | tee -a "$OUT"
printf "%s\tTPNet-%s\t%s\t%s\t%s\n" \
  "$(date -Iseconds)" "$DATASET" "$RUN_KIND" "$code" "$OUT" \
  >> "$ROOT/results/full_run_status.tsv"
exit "$code"
