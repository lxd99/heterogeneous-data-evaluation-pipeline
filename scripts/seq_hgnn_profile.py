import os
import sys
import time
from pathlib import Path

import torch


ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT / "repos/SEQ_HGNN"
os.chdir(REPO)
sys.path.insert(0, str(REPO))

from seq_hgnn.model import SeqHGNN


torch.manual_seed(20260730)
node_types = ["A", "P", "T", "V"]
edge_types = [
    ("A", "AP", "P"),
    ("P", "PA", "A"),
    ("P", "PT", "T"),
    ("T", "TP", "P"),
    ("P", "PV", "V"),
    ("V", "VP", "P"),
]
node_count = 128
edge_count = 1024
feature_dimension = 128
features = {
    node_type: torch.randn(node_count, feature_dimension)
    for node_type in node_types
}
edge_indices = {
    edge_type: torch.randint(0, node_count, (2, edge_count))
    for edge_type in edge_types
}
model = SeqHGNN(
    graph_meta=(node_types, edge_types),
    targe_node_type="A",
    hidden_channels=256,
    out_channels=4,
    num_heads=8,
    num_layers=3,
    dropout=0.2,
)

# Initialize the repository's lazy input and output projections.
model(features, edge_indices)
parameter_count = sum(parameter.numel() for parameter in model.parameters())

print("[TEST_REPORT] method=Seq-HGNN test=synthetic_hgb_dblp_profile")
print(f"timestamp={time.strftime('%Y-%m-%dT%H:%M:%S%z')}")
print(f"repo={REPO}")
print("commit=" + os.popen("git rev-parse HEAD").read().strip())
print("input_schema=HGB-DBLP 4 node types, 6 directed relation types")
print(f"synthetic_nodes_per_type={node_count}")
print(f"synthetic_edges_per_relation={edge_count}")
print(f"synthetic_feature_dimension={feature_dimension}")
print(f"model_parameters_for_synthetic_features={parameter_count}")

if not torch.cuda.is_available():
    print("[SKIP] CUDA unavailable; parameter test completed")
    raise SystemExit(0)

device = torch.device("cuda:0")
features = {key: value.to(device) for key, value in features.items()}
edge_indices = {key: value.to(device) for key, value in edge_indices.items()}
model = model.to(device).train()
optimizer = torch.optim.AdamW(model.parameters(), lr=5e-4)


def step():
    logits = model(features, edge_indices)
    loss = logits.square().mean()
    optimizer.zero_grad(set_to_none=True)
    loss.backward()
    optimizer.step()
    return loss


for _ in range(2):
    step()
torch.cuda.synchronize()
start = time.perf_counter()
steps = 10
for _ in range(steps):
    final_loss = step()
torch.cuda.synchronize()
elapsed = time.perf_counter() - start

print(f"profile_steps={steps}")
print(f"profile_elapsed_seconds={elapsed:.6f}")
print(f"mean_train_step_ms={elapsed / steps * 1000:.3f}")
print(f"final_synthetic_loss={final_loss.item():.6f}")
print(f"peak_cuda_memory_mb={torch.cuda.max_memory_allocated(device) / 1024**2:.3f}")
print("paper_accuracy_reproduction=SKIPPED_HGB_DATA_NOT_RELEASED_IN_REPOSITORY")
print("[EXIT] code=0")
