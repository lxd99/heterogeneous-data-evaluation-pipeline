#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fail=0
check() {
  if [[ -e "$1" ]]; then printf '[OK] %s\n' "$1"; else printf '[MISSING] %s\n' "$1"; fail=1; fi
}
command -v nvidia-smi >/dev/null && nvidia-smi --query-gpu=index,name,memory.total --format=csv,noheader || true
for path in \
  "$ROOT/repos/SEQ_HGNN/seq_hgnn/train.py" \
  "$ROOT/repos/R-HGNN/model/R_HGNN.py" \
  "$ROOT/repos/TPNet/train_link_prediction.py" \
  "$ROOT/repos/DyGKT/train_link_classification_full_test_report.py" \
  "$ROOT/repos/SMP/run_glue.py" \
  "$ROOT/repos/E5-V/retrieval_full_test_report.py" \
  "$ROOT/envs/graph/bin/python" \
  "$ROOT/envs/smp/bin/python" \
  "$ROOT/envs/e5v/bin/python" \
  "$ROOT/repos/SEQ_HGNN/dataset/HGB_ACM/ACM.pkl" \
  "$ROOT/repos/SEQ_HGNN/dataset/HGB_DBLP/DBLP.pkl" \
  "$ROOT/repos/TPNet/processed_data/wikipedia/ml_wikipedia.csv" \
  "$ROOT/repos/DyGKT/processed_data/assist17/ml_assist17.csv" \
  "$ROOT/data/mnli_0.50_kd_mag.npy" \
  "$ROOT/data/models/e5-v-full/config.json"; do check "$path"; done
while IFS=$'\t' read -r repo commit origin; do
  [[ "$repo" == repo ]] && continue
  [[ ! -d "$ROOT/repos/$repo/.git" ]] && continue
  actual=$(git -C "$ROOT/repos/$repo" rev-parse HEAD)
  if [[ "$actual" == "$commit" ]]; then
    echo "[OK] $repo commit=$actual"
  else
    echo "[MISMATCH] $repo expected=$commit actual=$actual"
    fail=1
  fi
done < "$ROOT/UPSTREAMS.tsv"
(( fail == 0 )) || exit 1
echo "[READY] Pipeline code and environments are complete."
