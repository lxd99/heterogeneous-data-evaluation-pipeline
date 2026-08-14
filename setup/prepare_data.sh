#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PY="$ROOT/envs/graph/bin/python"
[[ -x "$PY" ]] || { echo "Run setup/create_envs.sh first." >&2; exit 1; }
mkdir -p "$ROOT/repos/SEQ_HGNN/dataset"
"$PY" "$ROOT/scripts/prepare_seq_hgnn_acm.py"
"$PY" "$ROOT/scripts/prepare_seq_hgnn_dblp.py"
"$PY" "$ROOT/scripts/prepare_seq_hgnn_ogb_mag.py"
echo "[READY] Heterogeneous graph datasets prepared."
