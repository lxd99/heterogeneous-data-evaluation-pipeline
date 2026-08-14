#!/usr/bin/env bash
set -u -o pipefail

ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
REPO="$ROOT/repos/E5-V"
PY="$ROOT/envs/e5v/bin/python"
ACCELERATE="$ROOT/envs/e5v/bin/accelerate"
MODEL="$ROOT/data/models/e5-v-full"
WAIT_PIDS=${WAIT_PIDS:-}
GPU_LIST=${GPU_LIST:-1,2}
RUN_KIND=full_readme_eval
OUT="$ROOT/logs/E5-V/${RUN_KIND}_$(date +%Y%m%d_%H%M%S).log"
RESULT="$ROOT/results/E5-V/e5v_full_metrics.txt"

mkdir -p "$ROOT/logs/E5-V" "$ROOT/results/E5-V"

for wait_pid in $WAIT_PIDS; do
  echo "[WAIT] pid=$wait_pid timestamp=$(date -Iseconds)" >> "$OUT"
  while kill -0 "$wait_pid" 2>/dev/null; do
    sleep 30
  done
done

if ! "$PY" -c "import datasets, fire, pyarrow" >> "$OUT" 2>&1; then
  echo "[PRECONDITION_FAILED] E5-V evaluation dependencies are unavailable." >> "$OUT"
  code=4
elif [[ $(find "$MODEL" -maxdepth 1 -name 'model-*-of-00004.safetensors' | wc -l) -ne 4 ]]; then
  echo "[PRECONDITION_FAILED] The four official E5-V weight shards are incomplete." >> "$OUT"
  code=5
else
  cd "$REPO"
  COMMAND=(
    "$ACCELERATE" launch
    --num_machines 1
    --num_processes 2
    --machine_rank 0
    --main_process_port 29677
    retrieval_full_test_report.py
    --use_e5v
    --data flickr30k,coco
    --batch_size 1
    --name "$RESULT"
  )

  {
    echo "[TEST_REPORT] method=E5-V datasets=Flickr30K,COCO run=$RUN_KIND"
    echo "timestamp=$(date -Iseconds)"
    echo "repo=$REPO"
    echo "commit=$(git rev-parse HEAD)"
    echo "model=$MODEL"
    echo "gpu_physical=$GPU_LIST"
    printf "command="
    printf "%q " "${COMMAND[@]}"
    printf "\n"
  } | tee -a "$OUT"

  set +e
  E5V_MODEL_PATH="$MODEL" \
  HF_HOME="$ROOT/data/huggingface" \
  HF_DATASETS_CACHE="$ROOT/data/huggingface/e5v_datasets" \
  TRANSFORMERS_CACHE="$ROOT/data/huggingface/transformers" \
  CUDA_VISIBLE_DEVICES="$GPU_LIST" \
  PYTHONUNBUFFERED=1 \
  OMP_NUM_THREADS=4 \
    "${COMMAND[@]}" 2>&1 | tee -a "$OUT"
  code=${PIPESTATUS[0]}
  set -e
fi

if [[ -f "$RESULT" ]]; then
  printf "\n[RESULT_FILE] %s\n" "$RESULT" | tee -a "$OUT"
  cat "$RESULT" | tee -a "$OUT"
fi
printf "\n[EXIT] code=%s timestamp=%s\n" "$code" "$(date -Iseconds)" | tee -a "$OUT"
printf "%s\tE5-V\t%s\t%s\t%s\n" \
  "$(date -Iseconds)" "$RUN_KIND" "$code" "$OUT" \
  >> "$ROOT/results/full_run_status.tsv"
exit "$code"
