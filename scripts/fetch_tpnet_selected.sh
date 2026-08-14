#!/usr/bin/env bash
set -euo pipefail

ROOT=${EVAL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
DATA="$ROOT/data/TPNet"
REPO="$ROOT/repos/TPNet"
BASE=https://zenodo.org/api/records/7213796/files

mkdir -p "$DATA" "$REPO/processed_data"
for name in wikipedia enron uci mooc lastfm; do
  archive="$DATA/${name}.zip"
  if [[ ! -s "$archive" ]]; then
    curl -fL --retry 3 --connect-timeout 20 \
      "$BASE/${name}.zip/content" -o "$archive"
  fi
  mkdir -p "$DATA/$name"
  unzip -n "$archive" -d "$DATA/$name"
  dataset_dir="$DATA/$name/$name"
  if [[ ! -f "$dataset_dir/ml_${name}.csv" ]]; then
    echo "Expected processed dataset not found: $dataset_dir" >&2
    exit 1
  fi
  if [[ ! -e "$REPO/processed_data/$name" ]]; then
    ln -s "$dataset_dir" "$REPO/processed_data/$name"
  fi
  md5sum "$archive"
  ls -lh "$dataset_dir"/ml_${name}.*
done
