#!/usr/bin/env bash
set -euo pipefail

ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
REPO="$ROOT/repos/TPNet"
PY="$ROOT/envs/graph/bin/python"
STAMP=$(date +%Y%m%d_%H%M%S)
LOG="$ROOT/logs/TPNet/efficiency_${STAMP}.log"
OUTDIR="$ROOT/results/tpnet_efficiency"

mkdir -p "$OUTDIR" "$ROOT/logs/TPNet"
cd "$REPO"

for dataset in lastfm mooc; do
  for model in TPNet DyGFormer CAWN; do
    echo "[BENCHMARK] dataset=$dataset model=$model" | tee -a "$LOG"
    CUDA_VISIBLE_DEVICES="${GPU:-2}" "$PY" "$ROOT/scripts/benchmark_tpnet_efficiency.py" \
      --dataset "$dataset" --model "$model" --warmup 2 --repeats 5 --batches 3 \
      --output "$OUTDIR/${dataset}_${model}.json" 2>&1 | tee -a "$LOG"
  done
done

EVAL_ROOT="$ROOT" "$PY" - <<'PY' | tee -a "$LOG" "$OUTDIR/summary.txt"
import json
import os
from pathlib import Path

root = Path(os.environ["EVAL_ROOT"]) / "results/tpnet_efficiency"
for dataset in ("lastfm", "mooc"):
    values = {}
    for model in ("TPNet", "DyGFormer", "CAWN"):
        values[model] = json.loads((root / f"{dataset}_{model}.json").read_text())["median_seconds_per_batch"]
    print(f"dataset={dataset}")
    for model, value in values.items():
        print(f"{model}_median_seconds_per_batch={value:.9f}")
    print(f"speedup_vs_DyGFormer={values['DyGFormer'] / values['TPNet']:.6f}")
    print(f"speedup_vs_CAWN={values['CAWN'] / values['TPNet']:.6f}")
PY

printf "%s\tTPNet-efficiency\tfull\t0\t%s\n" \
  "$(date -Iseconds)" "$LOG" >> "$ROOT/results/full_run_status.tsv"
