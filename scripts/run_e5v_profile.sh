#!/usr/bin/env bash
set -u -o pipefail

ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
OUT="$ROOT/logs/E5-V/profile_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$OUT")" "$ROOT/results"

set +e
"$ROOT/envs/e5v/bin/python" "$ROOT/scripts/e5v_profile.py" 2>&1 | tee "$OUT"
code=${PIPESTATUS[0]}
set -e

printf "%s\tE5-V\tprofile\t%s\t%s\n" \
  "$(date -Iseconds)" "$code" "$OUT" >> "$ROOT/results/run_status.tsv"
exit "$code"
