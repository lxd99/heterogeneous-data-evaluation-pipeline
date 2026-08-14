#!/usr/bin/env bash
set -u -o pipefail
ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
REPO="$ROOT/repos/DyGKT"
PY="$ROOT/envs/graph/bin/python"
GPU=${GPU:-1}
EPOCHS=${EPOCHS:-1}
RUN_KIND=${RUN_KIND:-smoke}
OUT="$ROOT/logs/DyGKT/${RUN_KIND}_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$ROOT/logs/DyGKT"
cd "$REPO"
printf "[TEST_REPORT] method=DyGKT run=%s\n" "$RUN_KIND" | tee "$OUT"
printf "timestamp=%s\nrepo=%s\ncommit=%s\n" "$(date -Iseconds)" "$REPO" "$(git rev-parse HEAD)" | tee -a "$OUT"
printf "python=%s\ngpu=%s\nepochs=%s\n" "$PY" "$GPU" "$EPOCHS" | tee -a "$OUT"
printf "command=%q " "$PY" train_link_classification_test_report.py --dataset_name assist17 --model_name DyGKT --num_neighbors 100 --num_epochs "$EPOCHS" --num_runs 1 --test_interval_epochs 1 --gpu "$GPU"
printf "\n" | tee -a "$OUT"
set +e
CUDA_VISIBLE_DEVICES="$GPU" "$PY" train_link_classification_test_report.py \
  --dataset_name assist17 --model_name DyGKT --num_neighbors 100 \
  --num_epochs "$EPOCHS" --num_runs 1 --test_interval_epochs 1 --gpu 0 \
  2>&1 | tee -a "$OUT"
code=${PIPESTATUS[0]}
set -e
latest=$(find logs/DyGKT/assist17 -type f -name "*.log" -printf "%T@ %p\n" 2>/dev/null | sort -n | tail -1 | cut -d" " -f2-)
if [[ -n "${latest:-}" && -f "$latest" ]]; then
  printf "\n[INTERNAL_LOG] %s\n" "$latest" | tee -a "$OUT"
  cat "$latest" | tee -a "$OUT"
fi
printf "\n[EXIT] code=%s timestamp=%s\n" "$code" "$(date -Iseconds)" | tee -a "$OUT"
printf "%s\tDyGKT\t%s\t%s\t%s\n" "$(date -Iseconds)" "$RUN_KIND" "$code" "$OUT" >> "$ROOT/results/run_status.tsv"
exit "$code"
