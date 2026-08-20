#!/usr/bin/env bash
set -euo pipefail

ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
REPO="$ROOT/repos/TPNet"
PY="${GRAPH_PY:-$ROOT/envs/graph/bin/python}"
ARCHIVE="$REPO/DG_data/UNtrade.zip"
URL='https://zenodo.org/records/7213796/files/UNtrade.zip?download=1'

mkdir -p "$REPO/DG_data" "$REPO/processed_data"
[[ -s "$ARCHIVE" ]] || curl -fL --retry 5 --connect-timeout 20 "$URL" -o "$ARCHIVE"
echo "b7b59f4606e25588612d96403690c306  $ARCHIVE" | md5sum -c -
[[ -d "$REPO/DG_data/UNtrade" ]] || unzip -q "$ARCHIVE" -d "$REPO/DG_data"
if [[ ! -f "$REPO/processed_data/UNtrade/ml_UNtrade.csv" ]]; then
  (cd "$REPO/preprocess_data" && "$PY" preprocess_data.py --dataset_name UNtrade)
fi
ls -lh "$REPO/processed_data/UNtrade"/ml_UNtrade.*
