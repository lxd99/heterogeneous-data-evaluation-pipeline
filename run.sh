#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PKG=$ROOT
STAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$PKG/runs"

usage() {
  cat <<'HELP'
Usage:
  bash run.sh verify
  bash run.sh evidence
  GPU=0 bash run.sh smoke
  CONFIRM_FULL=1 GPU0=0 GPU1=1 bash run.sh full-3.1
  CONFIRM_FULL=1 GPU0=0 GPU1=1 bash run.sh full-3.2
  CONFIRM_FULL=1 GPU0=0 GPU1=1 bash run.sh full-3.3
  CONFIRM_FULL=1 GPU0=0 GPU1=1 bash run.sh full-all

Targets:
  verify    Check GPUs, code, datasets, models, environments and commits.
  evidence  Print the result evidence retained by the final test report.
  smoke     Run lightweight executable checks for all six methods.
  full-*    Reproduce a complete module. These jobs can take hours.
HELP
}

environment_value() {
  local name=$1
  local fallback=$2
  local value
  value=$(printenv "$name" 2>/dev/null || true)
  if [[ -z "$value" ]]; then
    value=$fallback
  fi
  printf '%s' "$value"
}

require_full_confirmation() {
  local confirmed
  confirmed=$(environment_value CONFIRM_FULL 0)
  if [[ "$confirmed" != 1 ]]; then
    echo '[STOP] Full evaluation requires CONFIRM_FULL=1.' >&2
    exit 2
  fi
}

run_logged() {
  local name=$1
  shift
  local log=$PKG/runs/$STAMP"_"$name.log
  local code

  set +e
  {
    echo "[RUN] name=$name"
    echo "[RUN] started=$(date -Iseconds)"
    printf '[RUN] command='
    printf '%q ' "$@"
    printf '\n'
    "$@"
    inner_code=$?
    echo "[RUN] exit_code=$inner_code"
    echo "[RUN] finished=$(date -Iseconds)"
    exit "$inner_code"
  } 2>&1 | tee "$log"
  code=$?
  set -e
  return "$code"
}

show_evidence() {
  echo "===== EXPECTED_RESULTS.md ====="
  cat "$ROOT/EXPECTED_RESULTS.md"
}

run_smoke() {
  local gpu
  gpu=$(environment_value GPU 0)
  "$PKG/verify_setup.sh"
  run_logged seq_hgnn_profile env GPU="$gpu" bash "$ROOT/scripts/run_seq_hgnn_profile.sh"
  run_logged r_hgnn_profile env GPU="$gpu" bash "$ROOT/scripts/run_r_hgnn_profile.sh"
  run_logged tpnet_enron_smoke env DATASET=enron GPU="$gpu" EPOCHS=1 RUN_KIND=evaluator_smoke bash "$ROOT/scripts/run_tpnet.sh"
  run_logged dygkt_smoke env GPU="$gpu" EPOCHS=1 RUN_KIND=evaluator_smoke bash "$ROOT/scripts/run_dygkt.sh"
  run_logged smp_profile env GPU="$gpu" bash "$ROOT/scripts/run_smp_profile.sh"
  run_logged e5v_profile bash "$ROOT/scripts/run_e5v_profile.sh"
}

run_full_31() {
  local gpu0
  local gpu1
  require_full_confirmation
  gpu0=$(environment_value GPU0 0)
  gpu1=$(environment_value GPU1 1)
  "$PKG/verify_setup.sh"

  for seed in 42 43 44 45 46; do
    run_logged seq_hgnn_dblp_seed$seed env GPU="$gpu0" EPOCHS=150 SEED="$seed" bash "$ROOT/scripts/run_seq_hgnn_dblp.sh"
    run_logged seq_hgnn_acm_seed$seed env FORCE_RERUN=1 GPU="$gpu1" EPOCHS=150 SEED="$seed" BATCH_SIZE=64 NUM_SAMPLES=256 bash "$ROOT/scripts/run_seq_hgnn_acm.sh"
  done

  for seed in 42 43 44; do
    run_logged seq_hgnn_ogb_mag_seed$seed env FORCE_RERUN=1 GPU="$gpu0" SEED="$seed" EPOCHS=100 N_BATCH=50 BATCH_SIZE=256 NUM_SAMPLES=256 bash "$ROOT/scripts/run_seq_hgnn_ogb_mag_sampled.sh"
  done

  run_logged r_hgnn_profile env GPU="$gpu1" bash "$ROOT/scripts/run_r_hgnn_profile.sh"
}

run_full_32() {
  local gpu0
  local gpu1
  require_full_confirmation
  gpu0=$(environment_value GPU0 0)
  gpu1=$(environment_value GPU1 1)
  "$PKG/verify_setup.sh"

  for dataset in wikipedia enron uci; do
    run_logged tpnet_$dataset env DATASET="$dataset" GPU="$gpu0" RUNS=5 EPOCHS=100 bash "$ROOT/scripts/run_tpnet_full.sh"
  done

  run_logged tpnet_mooc env DATASET=mooc GPU="$gpu0" RUNS=2 EPOCHS=100 bash "$ROOT/scripts/run_tpnet_full.sh"
  run_logged tpnet_efficiency env GPU="$gpu0" bash "$ROOT/scripts/run_tpnet_efficiency.sh"
  run_logged dygkt_assist17 env GPU="$gpu1" RUNS=5 EPOCHS=100 bash "$ROOT/scripts/run_dygkt_full.sh"
}

run_full_33() {
  local gpu0
  local gpu1
  require_full_confirmation
  gpu0=$(environment_value GPU0 0)
  gpu1=$(environment_value GPU1 1)
  "$PKG/verify_setup.sh"

  run_logged smp_mnli env GPU="$gpu0" MODEL_PATH="$ROOT/data/models/bert-base-uncased" EVAL_TAG=evaluator_official_bin bash "$ROOT/scripts/run_smp_full_eval.sh"
  run_logged e5v_retrieval env GPU_LIST="$gpu0,$gpu1" bash "$ROOT/scripts/run_e5v_full_eval.sh"
}

if (( $# == 0 )); then
  usage
  exit 1
fi

target=$1
case "$target" in
  verify)
    exec "$PKG/verify_setup.sh"
    ;;
  evidence)
    show_evidence | tee "$PKG/runs/"$STAMP"_evidence.log"
    ;;
  smoke)
    run_smoke
    ;;
  full-3.1)
    run_full_31
    ;;
  full-3.2)
    run_full_32
    ;;
  full-3.3)
    run_full_33
    ;;
  full-all)
    require_full_confirmation
    run_full_31
    run_full_32
    run_full_33
    ;;
  *)
    usage
    exit 1
    ;;
esac
