#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$ROOT/repos"

while IFS=$'\t' read -r repo commit origin; do
  [[ "$repo" == repo ]] && continue
  target="$ROOT/repos/$repo"
  if [[ ! -d "$target/.git" ]]; then
    git clone "$origin" "$target"
  fi
  git -C "$target" fetch --all --tags
  git -C "$target" checkout --detach "$commit"
done < "$ROOT/UPSTREAMS.tsv"

for repo in SEQ_HGNN TPNet; do
  patch="$ROOT/patches/$repo.patch"
  [[ ! -s "$patch" ]] && continue
  if git -C "$ROOT/repos/$repo" apply --check "$patch" 2>/dev/null; then
    git -C "$ROOT/repos/$repo" apply "$patch"
  elif git -C "$ROOT/repos/$repo" apply --reverse --check "$patch" 2>/dev/null; then
    echo "[SKIP] $repo patch already applied"
  else
    echo "[ERROR] $repo patch cannot be applied cleanly" >&2
    exit 1
  fi
done

cp "$ROOT/overrides/E5-V/"*.py "$ROOT/repos/E5-V/"
mkdir -p "$ROOT/repos/TPNet"/{processed_data,logs,saved_results,saved_models,wandb}
echo "[READY] Repositories cloned at fixed commits and evaluation changes applied."
