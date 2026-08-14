#!/usr/bin/env bash
set -u -o pipefail

ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
REPO="$ROOT/repos/DyGKT"
PY="$ROOT/envs/graph/bin/python"
GPU=${GPU:?GPU is required}
RUNS=${RUNS:-5}
EPOCHS=${EPOCHS:-100}
RUN_KIND=full_readme
OUT="$ROOT/logs/DyGKT/${RUN_KIND}_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$ROOT/logs/DyGKT" "$REPO/saved_models" "$REPO/saved_results"
cd "$REPO"

COMMAND=(
  "$PY" train_link_classification_full_test_report.py
  --dataset_name assist17
  --model_name DyGKT
  --num_neighbors 100
  --num_epochs "$EPOCHS"
  --num_runs "$RUNS"
  --test_interval_epochs 10
  --gpu 0
)

{
  echo "[TEST_REPORT] method=DyGKT dataset=assist17 run=$RUN_KIND"
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
CUDA_VISIBLE_DEVICES="$GPU" PYTHONUNBUFFERED=1 \
  "${COMMAND[@]}" 2>&1 | tee -a "$OUT"
code=${PIPESTATUS[0]}
set -e

printf "\n[INTERNAL_LOGS]\n" | tee -a "$OUT"
find "$REPO/logs/DyGKT/assist17" -path "*full_readme*" -type f \
  -name "*.log" -print | sort | tee -a "$OUT"
printf "\n[EXIT] code=%s timestamp=%s\n" "$code" "$(date -Iseconds)" | tee -a "$OUT"
printf "%s\tDyGKT\t%s\t%s\t%s\n" \
  "$(date -Iseconds)" "$RUN_KIND" "$code" "$OUT" \
  >> "$ROOT/results/full_run_status.tsv"
exit "$code"
