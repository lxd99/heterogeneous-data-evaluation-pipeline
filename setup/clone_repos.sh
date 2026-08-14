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
patch="$ROOT/patches/SEQ_HGNN.patch"
if git -C "$ROOT/repos/SEQ_HGNN" apply --check "$patch" 2>/dev/null; then
  git -C "$ROOT/repos/SEQ_HGNN" apply "$patch"
elif git -C "$ROOT/repos/SEQ_HGNN" apply --reverse --check "$patch" 2>/dev/null; then
  echo "[SKIP] Seq-HGNN patch already applied."
else
  echo "[ERROR] Seq-HGNN patch cannot be applied." >&2
  exit 1
fi
mkdir -p "$ROOT/repos/SEQ_HGNN/dataset"
echo "[READY] Module 3.1 repositories prepared."
