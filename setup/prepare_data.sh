#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
[[ -x "$ROOT/envs/graph/bin/python" ]] || { echo "Run setup/create_envs.sh first." >&2; exit 1; }
EVAL_ROOT="$ROOT" bash "$ROOT/scripts/fetch_tpnet_selected.sh"
echo "[READY] Public TPNet data prepared."
