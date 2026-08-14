#!/usr/bin/env bash
set -u -o pipefail

ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
OUT="$ROOT/logs/SMP/profile_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$OUT")" "$ROOT/results"

set +e
CUDA_VISIBLE_DEVICES=${GPU:-1} \
  "$ROOT/envs/smp/bin/python" "$ROOT/scripts/smp_profile.py" 2>&1 | tee "$OUT"
code=${PIPESTATUS[0]}
set -e

printf "%s\tSMP\tprofile\t%s\t%s\n" \
  "$(date -Iseconds)" "$code" "$OUT" >> "$ROOT/results/run_status.tsv"
exit "$code"
