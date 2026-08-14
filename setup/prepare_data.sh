#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
[[ -x "$ROOT/envs/graph/bin/python" ]] || { echo "Run setup/create_envs.sh first." >&2; exit 1; }
EVAL_ROOT="$ROOT" bash "$ROOT/scripts/fetch_tpnet_selected.sh"
if [[ ! -f "$ROOT/repos/DyGKT/processed_data/assist17/ml_assist17.csv" ]]; then
  cat >&2 <<'NOTICE'
[MANUAL] Prepare ASSISTment17 according to docs/DATA.md before running DyGKT.
NOTICE
fi
echo "[READY] Public TPNet data prepared."
