#!/usr/bin/env bash
set -euo pipefail

ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
REPO="$ROOT/repos/SEQ_HGNN"
PYTHON="$ROOT/envs/graph/bin/python"
STAMP=$(date +%Y%m%d_%H%M%S)
LOG="$ROOT/logs/SEQ_HGNN/dblp_full_${STAMP}.log"

mkdir -p "$ROOT/logs/SEQ_HGNN" "$ROOT/results"
cd "$REPO"

set +e
CUDA_VISIBLE_DEVICES=${GPU:-0} "$PYTHON" -m seq_hgnn.train \
  --dataset dblp \
  --num-hidden 512 \
  --num-heads 8 \
  --num-layers 2 \
  --dropout 0.5 \
  --epochs "${EPOCHS:-150}" \
  --batch-size 1217 \
  --num-samples "${NUM_SAMPLES:-100000}" \
  --lr 0.0005 \
  --weight-decay 0.01 \
  --workers 0 \
  --seed "${SEED:-42}" \
  --device 0 \
  --logsubfix "test_report_dblp_seed${SEED:-42}" \
  --off-wandb 2>&1 | tee "$LOG"
code=${PIPESTATUS[0]}
set -e

printf "%s\tSeq-HGNN-DBLP\tfull\t%s\t%s\n" \
  "$(date -Iseconds)" "$code" "$LOG" >> "$ROOT/results/run_status.tsv"
exit "$code"
