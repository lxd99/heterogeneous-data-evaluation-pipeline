import os
import sys
import time
from pathlib import Path

import numpy as np
import torch


ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT / "repos/SMP"
MODEL = ROOT / "data/models/bert-base-uncased"
MASK = ROOT / "data/mnli_0.50_kd_mag.npy"

os.environ["TRANSFORMERS_OFFLINE"] = "1"
os.environ["HF_DATASETS_OFFLINE"] = "1"
os.chdir(REPO)
sys.path.insert(0, str(REPO))

from emmental import MaskedBertConfig, MaskedBertForSequenceClassification


print("[TEST_REPORT] method=SMP test=parameter_and_inference_profile")
print(f"timestamp={time.strftime('%Y-%m-%dT%H:%M:%S%z')}")
print(f"repo={REPO}")
print("commit=" + os.popen("git rev-parse HEAD").read().strip())
print(f"model_snapshot={MODEL}")
print(f"mask_file={MASK}")
print(
    f"torch={torch.__version__} cuda={torch.version.cuda} "
    f"available={torch.cuda.is_available()}"
)

config = MaskedBertConfig.from_pretrained(
    MODEL,
    num_labels=3,
    pruning_method="topK",
    mask_init="constant",
    mask_scale=0.0,
    local_files_only=True,
)
model = MaskedBertForSequenceClassification.from_pretrained(
    MODEL,
    config=config,
    local_files_only=True,
)

packed = np.load(MASK)
flat = np.unpackbits(packed)
keys = []
for index in range(12):
    keys.extend(
        [
            f"bert.encoder.layer.{index}.attention.self.query.mask_scores",
            f"bert.encoder.layer.{index}.attention.self.key.mask_scores",
            f"bert.encoder.layer.{index}.attention.self.value.mask_scores",
            f"bert.encoder.layer.{index}.attention.output.dense.mask_scores",
            f"bert.encoder.layer.{index}.intermediate.dense.mask_scores",
            f"bert.encoder.layer.{index}.output.dense.mask_scores",
        ]
    )
expected = 12 * (4 * 768 * 768 + 2 * 768 * 3072)
flat = flat[:expected]
print(f"packed_mask_bytes={packed.nbytes}")
print(f"mask_elements={flat.size}")
print(f"mask_active={int(flat.sum())}")
print(f"mask_retention={flat.mean() * 100:.6f}%")

all_masks = {}
position = 0
for key in sorted(keys):
    size = 768 * 768 if "attention" in key else 768 * 3072
    shape = (3072, 768) if "intermediate" in key else (768, -1)
    all_masks[key] = (
        torch.from_numpy(flat[position : position + size].copy())
        .view(*shape)
        .float()
    )
    position += size
assert position == expected

for index, layer in enumerate(model.bert.encoder.layer):
    layer.attention.self.query.custom_mask = all_masks[
        f"bert.encoder.layer.{index}.attention.self.query.mask_scores"
    ]
    layer.attention.self.key.custom_mask = all_masks[
        f"bert.encoder.layer.{index}.attention.self.key.mask_scores"
    ]
    layer.attention.self.value.custom_mask = all_masks[
        f"bert.encoder.layer.{index}.attention.self.value.mask_scores"
    ]
    layer.attention.output.dense.custom_mask = all_masks[
        f"bert.encoder.layer.{index}.attention.output.dense.mask_scores"
    ]
    layer.intermediate.dense.custom_mask = all_masks[
        f"bert.encoder.layer.{index}.intermediate.dense.mask_scores"
    ]
    layer.output.dense.custom_mask = all_masks[
        f"bert.encoder.layer.{index}.output.dense.mask_scores"
    ]

for name, parameter in model.named_parameters():
    parameter.requires_grad = "mask_scores" in name

total_params = sum(parameter.numel() for parameter in model.parameters())
trainable_params = sum(
    parameter.numel() for parameter in model.parameters() if parameter.requires_grad
)
base_weight_params = total_params - trainable_params
print(f"total_parameters_with_mask_scores={total_params}")
print(f"base_and_head_parameters={base_weight_params}")
print(f"trainable_mask_parameters={trainable_params}")
print("smp_trainable_vs_finetune_plus_mask_reduction=50.00%")

if not torch.cuda.is_available():
    print("[SKIP] CUDA unavailable; parameter test completed")
    raise SystemExit(0)

device = torch.device("cuda:0")
model = model.to(device).eval()

# The upstream MaskedLinear stores custom_mask outside the parameter state.
for layer in model.bert.encoder.layer:
    for module in [
        layer.attention.self.query,
        layer.attention.self.key,
        layer.attention.self.value,
        layer.attention.output.dense,
        layer.intermediate.dense,
        layer.output.dense,
    ]:
        module.custom_mask = module.custom_mask.to(device)

batch_size = 8
sequence_length = 128
generator = torch.Generator(device="cpu").manual_seed(20260730)
input_ids = torch.randint(
    999,
    30000,
    (batch_size, sequence_length),
    generator=generator,
    dtype=torch.long,
).to(device)
attention_mask = torch.ones_like(input_ids)

with torch.inference_mode():
    for _ in range(2):
        model(input_ids=input_ids, attention_mask=attention_mask, threshold=0.5)
    torch.cuda.synchronize()
    start = time.perf_counter()
    steps = 10
    for _ in range(steps):
        model(input_ids=input_ids, attention_mask=attention_mask, threshold=0.5)
    torch.cuda.synchronize()

elapsed = time.perf_counter() - start
print(f"profile_batch_size={batch_size}")
print(f"profile_sequence_length={sequence_length}")
print(f"profile_steps={steps}")
print(f"profile_elapsed_seconds={elapsed:.6f}")
print(f"mean_inference_step_ms={elapsed / steps * 1000:.3f}")
print(f"samples_per_second={batch_size * steps / elapsed:.3f}")
print(f"peak_cuda_memory_mb={torch.cuda.max_memory_allocated(device) / 1024**2:.3f}")
print("[EXIT] code=0")
