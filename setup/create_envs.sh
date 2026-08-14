#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PYTHON_BIN=${PYTHON_BIN:-python3.9}
command -v "$PYTHON_BIN" >/dev/null || { echo "Python 3.9 is required." >&2; exit 1; }
create_env() {
  local name=$1 req=$2
  [[ -x "$ROOT/envs/$name/bin/python" ]] || "$PYTHON_BIN" -m venv "$ROOT/envs/$name"
  "$ROOT/envs/$name/bin/pip" install --upgrade pip setuptools wheel
  "$ROOT/envs/$name/bin/pip" install -r "$req"
}
mkdir -p "$ROOT/envs"
create_env smp "$ROOT/requirements/smp.txt"
create_env e5v "$ROOT/requirements/e5v.txt"
echo "[READY] SMP and E5-V environments created."
