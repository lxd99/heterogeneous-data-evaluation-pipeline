#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SMP_PY="$ROOT/envs/smp/bin/python"
E5V_PY="$ROOT/envs/e5v/bin/python"
[[ -x "$SMP_PY" && -x "$E5V_PY" ]] || { echo "Run setup/create_envs.sh first." >&2; exit 1; }
mkdir -p "$ROOT/data/models" "$ROOT/data/huggingface"
cd "$ROOT"

"$SMP_PY" - <<'PY'
from pathlib import Path
from transformers import AutoModelForSequenceClassification, AutoTokenizer
out = Path.cwd() / "data/models/bert-base-uncased"
out.mkdir(parents=True, exist_ok=True)
AutoTokenizer.from_pretrained("bert-base-uncased").save_pretrained(out)
AutoModelForSequenceClassification.from_pretrained("bert-base-uncased", num_labels=3).save_pretrained(out)
PY
curl -fL --retry 3 https://github.com/kongds/SMP/releases/download/SMP-S/mnli_0.50_kd_mag.npy.zip -o "$ROOT/data/mnli_0.50_kd_mag.npy.zip"
unzip -o "$ROOT/data/mnli_0.50_kd_mag.npy.zip" -d "$ROOT/data"

HF_HOME="$ROOT/data/huggingface" \
HF_DATASETS_CACHE="$ROOT/data/huggingface/e5v_datasets" \
"$E5V_PY" - <<'PY'
from pathlib import Path
from datasets import load_dataset
from huggingface_hub import snapshot_download
root = Path.cwd()
snapshot_download("royokong/e5-v", local_dir=root / "data/models/e5-v-full")
for name in ("flickr30k", "coco"):
    load_dataset(f"royokong/{name}_test", split="test")
PY
echo "[READY] SMP and E5-V data/model files prepared."
