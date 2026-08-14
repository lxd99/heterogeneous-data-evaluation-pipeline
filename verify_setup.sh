#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fail=0
check() { [[ -e "$1" ]] && echo "[OK] $1" || { echo "[MISSING] $1"; fail=1; }; }
for p in \
  "$ROOT/repos/SMP/run_glue.py" \
  "$ROOT/repos/E5-V/retrieval_full_test_report.py" \
  "$ROOT/envs/smp/bin/python" \
  "$ROOT/envs/e5v/bin/python" \
  "$ROOT/data/models/bert-base-uncased/config.json" \
  "$ROOT/data/mnli_0.50_kd_mag.npy" \
  "$ROOT/data/models/e5-v-full/config.json"; do check "$p"; done
shards=$(find "$ROOT/data/models/e5-v-full" -maxdepth 1 -name 'model-*-of-00004.safetensors' 2>/dev/null | wc -l | tr -d ' ')
[[ "$shards" == 4 ]] || { echo "[MISSING] E5-V shards: $shards/4"; fail=1; }
while IFS=$'\t' read -r repo commit origin; do
  [[ "$repo" == repo || ! -d "$ROOT/repos/$repo/.git" ]] && continue
  actual=$(git -C "$ROOT/repos/$repo" rev-parse HEAD)
  [[ "$actual" == "$commit" ]] || { echo "[MISMATCH] $repo"; fail=1; }
done < "$ROOT/UPSTREAMS.tsv"
(( fail == 0 )) || exit 1
echo "[READY] Module 3.3 setup is complete."
