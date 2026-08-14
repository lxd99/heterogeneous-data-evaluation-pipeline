#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$ROOT/repos"
while IFS=$'\t' read -r repo commit origin; do
  [[ "$repo" == repo ]] && continue
  target="$ROOT/repos/$repo"
  [[ -d "$target/.git" ]] || git clone "$origin" "$target"
  git -C "$target" fetch --all --tags
  git -C "$target" checkout --detach "$commit"
done < "$ROOT/UPSTREAMS.tsv"
cp "$ROOT/overrides/E5-V/"*.py "$ROOT/repos/E5-V/"
echo "[READY] Module 3.3 repositories prepared."
