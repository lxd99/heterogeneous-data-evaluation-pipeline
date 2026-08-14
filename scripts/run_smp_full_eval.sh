#!/usr/bin/env bash
set -u -o pipefail

ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
REPO="$ROOT/repos/SMP"
PY="$ROOT/envs/smp/bin/python"
GPU=${GPU:?GPU is required}
WAIT_PID=${WAIT_PID:-}
MODEL_PATH=${MODEL_PATH:-"$ROOT/data/models/bert-base-uncased"}
EVAL_TAG=${EVAL_TAG:-converted}
RUN_KIND="full_readme_eval_${EVAL_TAG}"
OUT="$ROOT/logs/SMP/${RUN_KIND}_$(date +%Y%m%d_%H%M%S).log"
OUTPUT_DIR="$ROOT/results/SMP/mnli_0.50_kd_mag_eval_${EVAL_TAG}"

mkdir -p "$ROOT/logs/SMP" "$OUTPUT_DIR"

if [[ -n "$WAIT_PID" ]]; then
  echo "[WAIT] pid=$WAIT_PID timestamp=$(date -Iseconds)" > "$OUT"
  while kill -0 "$WAIT_PID" 2>/dev/null; do
    sleep 30
  done
fi

cd "$REPO"
COMMAND=(
  "$PY" run_glue.py
  --model_name_or_path "$MODEL_PATH"
  --task_name mnli
  --do_eval
  --max_seq_length 128
  --report_to none
  --learning_rate 0
  --initial_warmup 0
  --final_warmup 6
  --initial_threshold 1
  --overwrite_cache True
  --pruning_method topK
  --mask_init constant
  --mask_scale 0.
  --regularization l1
  --per_device_eval_batch_size 128
  --warmup_ratio 0.00
  --logging_steps 50
  --save_total_limit 1
  --freeze_bert
  --label_map "{'2':'No','0':'Yes','1':'Maybe'}"
  --output_dir "$OUTPUT_DIR"
  --use_mask_pt "$ROOT/data/mnli_0.50_kd_mag.npy"
)

{
  echo "[TEST_REPORT] method=SMP dataset=MNLI run=$RUN_KIND"
  echo "timestamp=$(date -Iseconds)"
  echo "repo=$REPO"
  echo "commit=$(git rev-parse HEAD)"
  echo "python=$PY"
  echo "model=$MODEL_PATH"
  echo "gpu_physical=$GPU"
  printf "command="
  printf "%q " "${COMMAND[@]}"
  printf "\n"
} | tee -a "$OUT"

set +e
HF_HOME="$ROOT/data/huggingface" \
TRANSFORMERS_CACHE="$ROOT/data/huggingface/transformers" \
HF_DATASETS_CACHE="$ROOT/data/huggingface/datasets" \
CUDA_VISIBLE_DEVICES="$GPU" \
WANDB_DISABLED=true \
PYTHONUNBUFFERED=1 \
  "${COMMAND[@]}" 2>&1 | tee -a "$OUT"
code=${PIPESTATUS[0]}
set -e

printf "\n[RESULT_FILES]\n" | tee -a "$OUT"
find "$OUTPUT_DIR" -maxdepth 1 -type f -print -exec cat {} \; | tee -a "$OUT"
printf "\n[EXIT] code=%s timestamp=%s\n" "$code" "$(date -Iseconds)" | tee -a "$OUT"
printf "%s\tSMP\t%s\t%s\t%s\n" \
  "$(date -Iseconds)" "$RUN_KIND" "$code" "$OUT" \
  >> "$ROOT/results/full_run_status.tsv"
exit "$code"
