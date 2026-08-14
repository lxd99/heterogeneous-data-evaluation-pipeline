import os
import sys
import time
from collections import defaultdict
from pathlib import Path

import torch
from accelerate import init_empty_weights
from transformers import LlavaNextConfig, LlavaNextForConditionalGeneration


ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT / "repos/E5-V"
CONFIG_DIR = ROOT / "data/models/e5-v-full"
OFFICIAL_PARAMETER_TOTAL = 8_355_276_800

os.chdir(REPO)
sys.path.insert(0, str(REPO))

print("[TEST_REPORT] method=E5-V test=official_config_meta_parameter_profile")
print(f"timestamp={time.strftime('%Y-%m-%dT%H:%M:%S%z')}")
print(f"repo={REPO}")
print("commit=" + os.popen("git rev-parse HEAD").read().strip())
print(f"config={CONFIG_DIR / 'config.json'}")
print(f"torch={torch.__version__} cuda={torch.version.cuda}")

config = LlavaNextConfig.from_pretrained(CONFIG_DIR, local_files_only=True)
with init_empty_weights():
    model = LlavaNextForConditionalGeneration(config)

component_parameters = defaultdict(int)
total_parameters = 0
for name, parameter in model.named_parameters():
    count = parameter.numel()
    total_parameters += count
    if name.startswith("vision_tower"):
        component = "vision_tower"
    elif name.startswith("multi_modal_projector"):
        component = "multimodal_projector"
    elif name.startswith("language_model"):
        component = "language_model"
    elif name.startswith("lm_head"):
        component = "lm_head"
    elif name == "image_newline":
        component = "image_newline"
    else:
        component = name.split(".", 1)[0]
    component_parameters[component] += count

print(f"computed_total_parameters={total_parameters}")
print(f"official_safetensors_parameters={OFFICIAL_PARAMETER_TOTAL}")
print(f"parameter_count_match={total_parameters == OFFICIAL_PARAMETER_TOTAL}")
for component, count in sorted(component_parameters.items()):
    print(f"component_{component}_parameters={count}")

print(f"estimated_fp16_weight_gib={total_parameters * 2 / 1024**3:.3f}")
print(f"estimated_fp32_weight_gib={total_parameters * 4 / 1024**3:.3f}")
weight_shards = sorted(CONFIG_DIR.glob("model-*-of-00004.safetensors"))
print(f"official_weight_shards={len(weight_shards)}/4")
print(f"full_weight_download={'PRESENT' if len(weight_shards) == 4 else 'INCOMPLETE'}")
print("retrieval_execution=SKIPPED_IN_LIGHT_PROFILE_USE_FULL_3_3")
print("[EXIT] code=0")
