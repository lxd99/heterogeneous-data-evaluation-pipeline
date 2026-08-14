#!/usr/bin/env bash
set -euo pipefail

ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
REPO="$ROOT/repos/SEQ_HGNN"
PYTHON="$ROOT/envs/graph/bin/python"
STAMP=$(date +%Y%m%d_%H%M%S)
LOG="$ROOT/logs/SEQ_HGNN/acm_full_${STAMP}.log"

mkdir -p "$ROOT/logs/SEQ_HGNN" "$ROOT/results"
SEED_VALUE=${SEED:-42}
LOCK="$ROOT/results/seq_hgnn_acm_seed${SEED_VALUE}.lock"
exec 9>"$LOCK"
if ! flock -n 9; then
  echo "[SKIP] Seq-HGNN ACM seed ${SEED_VALUE} is already running."
  exit 0
fi
if [[ "${FORCE_RERUN:-0}" != "1" ]]; then
for previous in "$ROOT"/logs/SEQ_HGNN/acm_full_*.log; do
  if [[ -f "$previous" ]] && grep -q "Namespace(seed=${SEED_VALUE}," "$previous" \
      && grep -q "epochs=150" "$previous" && grep -q "\[BEST\]" "$previous"; then
    echo "[SKIP] Seq-HGNN ACM seed ${SEED_VALUE} already completed in $previous."
    exit 0
  fi
done
fi
cd "$REPO"

set +e
CUDA_VISIBLE_DEVICES=${GPU:-0} "$PYTHON" -m seq_hgnn.train \
  --dataset acm \
  --num-hidden 512 \
  --num-heads 8 \
  --num-layers 3 \
  --dropout 0.5 \
  --epochs "${EPOCHS:-150}" \
  --batch-size "${BATCH_SIZE:-64}" \
  --num-samples "${NUM_SAMPLES:-256}" \
  --lr 0.0005 \
  --weight-decay 0.01 \
  --workers 0 \
  --seed "$SEED_VALUE" \
  --device 0 \
  --logsubfix "test_report_acm_seed${SEED_VALUE}" \
  --off-wandb 2>&1 | tee "$LOG"
code=${PIPESTATUS[0]}
set -e

printf "%s\tSeq-HGNN-ACM\tfull\t%s\t%s\n" \
  "$(date -Iseconds)" "$code" "$LOG" >> "$ROOT/results/run_status.tsv"
exit "$code"
