#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GRAPH_PY="$ROOT/envs/graph/bin/python"
SMP_PY="$ROOT/envs/smp/bin/python"
E5V_PY="$ROOT/envs/e5v/bin/python"
[[ -x "$GRAPH_PY" ]] || { echo "Run setup/create_envs.sh first." >&2; exit 1; }

mkdir -p "$ROOT/data/models" "$ROOT/data/huggingface" "$ROOT/repos/SEQ_HGNN/dataset"
"$GRAPH_PY" "$ROOT/scripts/prepare_seq_hgnn_acm.py"
"$GRAPH_PY" "$ROOT/scripts/prepare_seq_hgnn_dblp.py"
"$GRAPH_PY" "$ROOT/scripts/prepare_seq_hgnn_ogb_mag.py"
EVAL_ROOT="$ROOT" bash "$ROOT/scripts/fetch_tpnet_selected.sh"

if [[ ! -f "$ROOT/repos/DyGKT/processed_data/assist17/ml_assist17.csv" ]]; then
  cat >&2 <<'NOTICE'
[MANUAL] DyGKT ASSISTment17 preprocessing files are not redistributed.
Download ASSISTment17 under its data-use terms and construct:
  repos/DyGKT/processed_data/assist17/ml_assist17.csv
  repos/DyGKT/processed_data/assist17/ml_assist17.npy
  repos/DyGKT/processed_data/assist17/ml_assist17_node.npy
See docs/DATA.md for the required schema.
NOTICE
fi

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

HF_HOME="$ROOT/data/huggingface" HF_DATASETS_CACHE="$ROOT/data/huggingface/e5v_datasets" "$E5V_PY" - <<'PY'
from huggingface_hub import snapshot_download
from datasets import load_dataset
from pathlib import Path
root = Path.cwd()
snapshot_download("royokong/e5-v", local_dir=root / "data/models/e5-v-full")
for name in ("flickr30k", "coco"):
    load_dataset(f"royokong/{name}_test", split="test")
PY
echo "[READY] Public datasets and model files prepared."
