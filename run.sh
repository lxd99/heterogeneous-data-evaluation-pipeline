#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
STAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$ROOT/runs" "$ROOT/logs" "$ROOT/results"
run_logged() {
  local name=$1
  shift
  local log="$ROOT/runs/${STAMP}_${name}.log"
  set +e
  { echo "[RUN] command=$(printf '%q ' "$@")"; "$@"; code=$?; echo "[RUN] exit_code=$code"; exit "$code"; } 2>&1 | tee "$log"
  local code=${PIPESTATUS[0]}
  set -e
  return "$code"
}
verify() { bash "$ROOT/verify_setup.sh"; }
smoke() {
  verify
  run_logged smp_profile env GPU="${GPU:-0}" bash "$ROOT/scripts/run_smp_profile.sh"
  run_logged e5v_profile bash "$ROOT/scripts/run_e5v_profile.sh"
}
full() {
  [[ "${CONFIRM_FULL:-0}" == 1 ]] || { echo "Set CONFIRM_FULL=1." >&2; exit 2; }
  verify
  run_logged smp_mnli env GPU="${GPU0:-0}" MODEL_PATH="$ROOT/data/models/bert-base-uncased" EVAL_TAG=public_eval bash "$ROOT/scripts/run_smp_full_eval.sh"
  run_logged e5v_retrieval env GPU_LIST="${GPU0:-0},${GPU1:-1}" bash "$ROOT/scripts/run_e5v_full_eval.sh"
}
case "${1:-}" in
  verify) verify ;;
  evidence) cat "$ROOT/EXPECTED_RESULTS.md" ;;
  smoke) smoke ;;
  full) full ;;
  *) echo "Usage: bash run.sh {verify|evidence|smoke|full}"; exit 1 ;;
esac
