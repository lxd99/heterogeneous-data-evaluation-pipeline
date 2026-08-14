#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fail=0
check() { [[ -e "$1" ]] && echo "[OK] $1" || { echo "[MISSING] $1"; fail=1; }; }
for p in \
  "$ROOT/repos/TPNet/train_link_prediction.py" \
  "$ROOT/repos/DyGKT/train_link_classification_full_test_report.py" \
  "$ROOT/envs/graph/bin/python" \
  "$ROOT/repos/TPNet/processed_data/wikipedia/ml_wikipedia.csv" \
  "$ROOT/repos/TPNet/processed_data/enron/ml_enron.csv" \
  "$ROOT/repos/TPNet/processed_data/uci/ml_uci.csv" \
  "$ROOT/repos/TPNet/processed_data/mooc/ml_mooc.csv" \
  "$ROOT/repos/TPNet/processed_data/lastfm/ml_lastfm.csv" \
  "$ROOT/repos/DyGKT/processed_data/assist17/ml_assist17.csv"; do check "$p"; done
while IFS=$'\t' read -r repo commit origin; do
  [[ "$repo" == repo || ! -d "$ROOT/repos/$repo/.git" ]] && continue
  actual=$(git -C "$ROOT/repos/$repo" rev-parse HEAD)
  [[ "$actual" == "$commit" ]] || { echo "[MISMATCH] $repo"; fail=1; }
done < "$ROOT/UPSTREAMS.tsv"
(( fail == 0 )) || exit 1
echo "[READY] Module 3.2 setup is complete."
