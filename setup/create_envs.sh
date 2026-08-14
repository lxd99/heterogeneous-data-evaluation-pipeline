#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PYTHON_BIN=${PYTHON_BIN:-python3.9}
command -v "$PYTHON_BIN" >/dev/null || { echo "Python 3.9 is required." >&2; exit 1; }
[[ -x "$ROOT/envs/graph/bin/python" ]] || "$PYTHON_BIN" -m venv "$ROOT/envs/graph"
"$ROOT/envs/graph/bin/pip" install --upgrade pip setuptools wheel
"$ROOT/envs/graph/bin/pip" install -r "$ROOT/requirements/graph.txt"
echo "[READY] Graph environment created."
