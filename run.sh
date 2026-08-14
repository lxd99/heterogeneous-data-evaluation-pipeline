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
  run_logged tpnet_enron env DATASET=enron GPU="${GPU:-0}" EPOCHS=1 RUN_KIND=evaluator_smoke bash "$ROOT/scripts/run_tpnet.sh"
  run_logged dygkt env GPU="${GPU:-0}" EPOCHS=1 RUN_KIND=evaluator_smoke bash "$ROOT/scripts/run_dygkt.sh"
}
full() {
  [[ "${CONFIRM_FULL:-0}" == 1 ]] || { echo "Set CONFIRM_FULL=1." >&2; exit 2; }
  verify
  for dataset in wikipedia enron uci; do
    run_logged "tpnet_$dataset" env DATASET="$dataset" GPU="${GPU0:-0}" RUNS=5 EPOCHS=100 bash "$ROOT/scripts/run_tpnet_full.sh"
  done
  run_logged tpnet_mooc env DATASET=mooc GPU="${GPU0:-0}" RUNS=2 EPOCHS=100 bash "$ROOT/scripts/run_tpnet_full.sh"
  run_logged tpnet_efficiency env GPU="${GPU0:-0}" bash "$ROOT/scripts/run_tpnet_efficiency.sh"
  run_logged dygkt_assist17 env GPU="${GPU1:-1}" RUNS=5 EPOCHS=100 bash "$ROOT/scripts/run_dygkt_full.sh"
}
case "${1:-}" in
  verify) verify ;;
  evidence) cat "$ROOT/EXPECTED_RESULTS.md" ;;
  smoke) smoke ;;
  full) full ;;
  *) echo "Usage: bash run.sh {verify|evidence|smoke|full}"; exit 1 ;;
esac
