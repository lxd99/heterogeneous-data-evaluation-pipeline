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
  run_logged seq_hgnn_profile env GPU="${GPU:-0}" bash "$ROOT/scripts/run_seq_hgnn_profile.sh"
  run_logged r_hgnn_profile env GPU="${GPU:-0}" bash "$ROOT/scripts/run_r_hgnn_profile.sh"
}
full() {
  [[ "${CONFIRM_FULL:-0}" == 1 ]] || { echo "Set CONFIRM_FULL=1." >&2; exit 2; }
  verify
  for seed in 42 43 44 45 46; do
    run_logged "seq_dblp_$seed" env GPU="${GPU0:-0}" EPOCHS=150 SEED="$seed" bash "$ROOT/scripts/run_seq_hgnn_dblp.sh"
    run_logged "seq_acm_$seed" env FORCE_RERUN=1 GPU="${GPU1:-1}" EPOCHS=150 SEED="$seed" BATCH_SIZE=64 NUM_SAMPLES=256 bash "$ROOT/scripts/run_seq_hgnn_acm.sh"
  done
  for seed in 42 43 44; do
    run_logged "seq_mag_$seed" env FORCE_RERUN=1 GPU="${GPU0:-0}" SEED="$seed" EPOCHS=100 N_BATCH=50 BATCH_SIZE=256 NUM_SAMPLES=256 bash "$ROOT/scripts/run_seq_hgnn_ogb_mag_sampled.sh"
  done
  run_logged r_hgnn_profile env GPU="${GPU1:-1}" bash "$ROOT/scripts/run_r_hgnn_profile.sh"
}
case "${1:-}" in
  verify) verify ;;
  evidence) cat "$ROOT/EXPECTED_RESULTS.md" ;;
  smoke) smoke ;;
  full) full ;;
  *) echo "Usage: bash run.sh {verify|evidence|smoke|full}"; exit 1 ;;
esac
