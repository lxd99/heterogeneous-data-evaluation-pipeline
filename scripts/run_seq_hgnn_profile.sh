#!/usr/bin/env bash
set -u -o pipefail

ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
OUT="$ROOT/logs/SEQ_HGNN/profile_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$ROOT/logs/SEQ_HGNN"

set +e
CUDA_VISIBLE_DEVICES=${GPU:-5} \
  "$ROOT/envs/graph/bin/python" "$ROOT/scripts/seq_hgnn_profile.py" 2>&1 | tee "$OUT"
code=${PIPESTATUS[0]}
set -e

printf "%s\tSEQ_HGNN\tprofile\t%s\t%s\n" \
  "$(date -Iseconds)" "$code" "$OUT" >> "$ROOT/results/run_status.tsv"
exit "$code"
