#!/usr/bin/env bash
set -euo pipefail

ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
REPO="$ROOT/repos/SEQ_HGNN"
PYTHON="$ROOT/envs/graph/bin/python"
STAMP=$(date +%Y%m%d_%H%M%S)
LOG="$ROOT/logs/SEQ_HGNN/ogb_mag_sampled_${STAMP}.log"

mkdir -p "$ROOT/logs/SEQ_HGNN" "$ROOT/results"
SEED_VALUE=${SEED:-42}
LOCK="$ROOT/results/seq_hgnn_ogb_mag_seed${SEED_VALUE}.lock"
exec 9>"$LOCK"
if ! flock -n 9; then
  echo "[SKIP] Seq-HGNN OGB-MAG seed ${SEED_VALUE} is already running."
  exit 0
fi
if [[ "${FORCE_RERUN:-0}" != "1" ]]; then
for previous in "$ROOT"/logs/SEQ_HGNN/ogb_mag_sampled_*.log; do
  if [[ -f "$previous" ]] && grep -q "Namespace(seed=${SEED_VALUE}," "$previous" \
      && grep -q "epochs=100" "$previous" && grep -q "\[BEST\]" "$previous"; then
    echo "[SKIP] Seq-HGNN OGB-MAG seed ${SEED_VALUE} already completed in $previous."
    exit 0
  fi
done
fi
cd "$REPO"

set +e
CUDA_VISIBLE_DEVICES=${GPU:-1} "$PYTHON" -m seq_hgnn.train \
  --dataset ogbn-mag \
  --num-hidden 512 \
  --num-heads 8 \
  --num-layers 2 \
  --dropout 0.5 \
  --epochs "${EPOCHS:-20}" \
  --batch-size "${BATCH_SIZE:-256}" \
  --n-batch "${N_BATCH:-20}" \
  --num-samples "${NUM_SAMPLES:-256}" \
  --lr 0.0005 \
  --weight-decay 0.01 \
  --workers 0 \
  --seed "$SEED_VALUE" \
  --device 0 \
  --amp \
  --logsubfix "test_report_ogb_mag_sampled_seed${SEED_VALUE}" \
  --off-wandb 2>&1 | tee "$LOG"
code=${PIPESTATUS[0]}
set -e

printf "%s\tSeq-HGNN-OGB-MAG\tsampled\t%s\t%s\n" \
  "$(date -Iseconds)" "$code" "$LOG" >> "$ROOT/results/run_status.tsv"
exit "$code"
