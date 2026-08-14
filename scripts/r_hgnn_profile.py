import copy
import os
import sys
import time
from pathlib import Path

import dgl
import torch


ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT / "repos/R-HGNN"
os.chdir(REPO)
sys.path.insert(0, str(REPO))

from model.R_HGNN import R_HGNN
from utils.Classifier import Classifier


torch.manual_seed(20260730)
node_count = 128
edge_count = 1024


def edges():
    return (
        torch.randint(0, node_count, (edge_count,)),
        torch.randint(0, node_count, (edge_count,)),
    )


relations = {
    ("author", "affiliated_with", "institution"): edges(),
    ("institution", "rev_affiliated_with", "author"): edges(),
    ("author", "writes", "paper"): edges(),
    ("paper", "rev_writes", "author"): edges(),
    ("paper", "cites", "paper"): edges(),
    ("paper", "rev_cites", "paper"): edges(),
    ("paper", "has_topic", "field_of_study"): edges(),
    ("field_of_study", "rev_has_topic", "paper"): edges(),
}
graph = dgl.heterograph(
    relations,
    num_nodes_dict={
        "author": node_count,
        "institution": node_count,
        "paper": node_count,
        "field_of_study": node_count,
    },
)
input_dims = {
    "author": 128,
    "institution": 128,
    "paper": 256,
    "field_of_study": 128,
}
for node_type, dimension in input_dims.items():
    graph.nodes[node_type].data["feat"] = torch.randn(node_count, dimension)

backbone = R_HGNN(
    graph=graph,
    input_dim_dict=input_dims,
    hidden_dim=64,
    relation_input_dim=8,
    relation_hidden_dim=8,
    num_layers=2,
    n_heads=8,
    dropout=0.5,
    residual=True,
)
model = torch.nn.Sequential(backbone, Classifier(n_hid=512, n_out=349))
parameter_count = sum(parameter.numel() for parameter in model.parameters())

print("[TEST_REPORT] method=R-HGNN test=synthetic_ogb_mag_profile")
print(f"timestamp={time.strftime('%Y-%m-%dT%H:%M:%S%z')}")
print(f"repo={REPO}")
print("commit=" + os.popen("git rev-parse HEAD").read().strip())
print("input_schema=OGB-MAG 4 node types, 8 directed relation types")
print(f"synthetic_nodes_per_type={node_count}")
print(f"synthetic_edges_per_relation={edge_count}")
print(f"model_parameters={parameter_count}")
print(f"reference_parameter_count=5638053")
print(f"parameter_count_match={parameter_count == 5_638_053}")

device = torch.device("cpu")
timing_device = "cpu"
if torch.cuda.is_available():
    try:
        graph = graph.to("cuda:0")
        device = torch.device("cuda:0")
        timing_device = "cuda:0"
    except dgl.DGLError as error:
        print("gpu_profile_fallback=CPU")
        print(f"fallback_reason={str(error).splitlines()[0]}")

model = model.to(device).train()
optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)


def step():
    relation_features = {
        canonical_type: graph.nodes[canonical_type[2]].data["feat"]
        for canonical_type in graph.canonical_etypes
    }
    representations, _ = model[0]([graph, graph], copy.deepcopy(relation_features))
    logits = model[1](representations["paper"])
    loss = logits.square().mean()
    optimizer.zero_grad(set_to_none=True)
    loss.backward()
    optimizer.step()
    return loss


for _ in range(2):
    step()
if device.type == "cuda":
    torch.cuda.synchronize()
start = time.perf_counter()
steps = 10
for _ in range(steps):
    final_loss = step()
if device.type == "cuda":
    torch.cuda.synchronize()
elapsed = time.perf_counter() - start

print(f"profile_device={timing_device}")
print(f"profile_steps={steps}")
print(f"profile_elapsed_seconds={elapsed:.6f}")
print(f"mean_train_step_ms={elapsed / steps * 1000:.3f}")
print(f"final_synthetic_loss={final_loss.item():.6f}")
if device.type == "cuda":
    print(
        f"peak_cuda_memory_mb="
        f"{torch.cuda.max_memory_allocated(device) / 1024**2:.3f}"
    )
else:
    print("peak_cuda_memory_mb=NOT_APPLICABLE_CPU_DGL_BUILD")
print("paper_accuracy_reproduction=SKIPPED_NO_PUBLIC_OGB_MAG_PREPROCESS")
print("[EXIT] code=0")
