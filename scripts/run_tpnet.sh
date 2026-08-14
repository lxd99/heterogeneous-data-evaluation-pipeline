#!/usr/bin/env bash
set -u -o pipefail
ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
REPO="$ROOT/repos/TPNet"
PY="$ROOT/envs/graph/bin/python"
DATASET=${DATASET:-enron}
GPU=${GPU:-2}
EPOCHS=${EPOCHS:-1}
RUN_KIND=${RUN_KIND:-smoke}
PREFIX="test_report_${RUN_KIND}_${DATASET}"
OUT="$ROOT/logs/TPNet/${DATASET}_${RUN_KIND}_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$ROOT/logs/TPNet"
cd "$REPO"
{
  echo "[TEST_REPORT] method=TPNet dataset=$DATASET run=$RUN_KIND"
  echo "timestamp=$(date -Iseconds)"
  echo "repo=$REPO"
  echo "commit=$(git rev-parse HEAD)"
  echo "python=$PY"
  echo "gpu_physical=$GPU"
  echo "epochs=$EPOCHS"
  echo "command=$PY train_link_prediction.py --prefix $PREFIX --dataset_name $DATASET --model_name TPNet --num_runs 1 --num_epochs $EPOCHS --gpu 0 --use_random_projection --load_best_configs"
} | tee "$OUT"
set +e
CUDA_VISIBLE_DEVICES="$GPU" "$PY" train_link_prediction.py \
  --prefix "$PREFIX" --dataset_name "$DATASET" --model_name TPNet \
  --num_runs 1 --num_epochs "$EPOCHS" --gpu 0 \
  --use_random_projection --load_best_configs \
  2>&1 | tee -a "$OUT"
code=${PIPESTATUS[0]}
set -e
internal="logs/${PREFIX}_link_${DATASET}_TPNet.log"
if [[ -f "$internal" ]]; then
  printf "\n[INTERNAL_LOG] %s\n" "$internal" | tee -a "$OUT"
  cat "$internal" | tee -a "$OUT"
fi
printf "\n[EXIT] code=%s timestamp=%s\n" "$code" "$(date -Iseconds)" | tee -a "$OUT"
printf "%s\tTPNet-%s\t%s\t%s\t%s\n" "$(date -Iseconds)" "$DATASET" "$RUN_KIND" "$code" "$OUT" >> "$ROOT/results/run_status.tsv"
exit "$code"
