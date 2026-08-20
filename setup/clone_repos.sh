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
patch="$ROOT/patches/TPNet.patch"
if git -C "$ROOT/repos/TPNet" apply --check "$patch" 2>/dev/null; then
  git -C "$ROOT/repos/TPNet" apply "$patch"
elif git -C "$ROOT/repos/TPNet" apply --reverse --check "$patch" 2>/dev/null; then
  echo "[SKIP] TPNet patch already applied."
else
  echo "[ERROR] TPNet patch cannot be applied." >&2
  exit 1
fi
mkdir -p "$ROOT/repos/TPNet"/{processed_data,logs,saved_results,saved_models,wandb}
echo "[READY] Module 3.2 repositories prepared."
