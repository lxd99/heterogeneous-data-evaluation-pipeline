from pathlib import Path
import sys

import dgl
import numpy as np
import torch
from dgl.data.utils import save_graphs


ROOT = Path(__file__).resolve().parents[1]
HGB_ROOT = ROOT / "repos/HGB/NC/benchmark"
HGB_DATA = HGB_ROOT / "data/DBLP"
OUTPUT = ROOT / "repos/SEQ_HGNN/dataset/HGB_DBLP"

sys.path.insert(0, str(HGB_ROOT))
from scripts.data_loader import data_loader  # noqa: E402


NODE_TYPES = {0: "A", 1: "P", 2: "T", 3: "V"}
EDGE_TYPES = {
    0: ("A", "AP", "P"),
    1: ("P", "PT", "T"),
    2: ("P", "PV", "V"),
    3: ("P", "PA", "A"),
    4: ("T", "TP", "P"),
    5: ("V", "VP", "P"),
}


def local_indices(matrix, src_type, dst_type, shifts):
    coo = matrix.tocoo()
    src = torch.from_numpy((coo.row - shifts[src_type]).astype(np.int64))
    dst = torch.from_numpy((coo.col - shifts[dst_type]).astype(np.int64))
    return src, dst


loader = data_loader(str(HGB_DATA))
graph_data = {}
for relation_id, canonical_type in EDGE_TYPES.items():
    src_type, _, dst_type = canonical_type
    src_id = next(key for key, value in NODE_TYPES.items() if value == src_type)
    dst_id = next(key for key, value in NODE_TYPES.items() if value == dst_type)
    graph_data[canonical_type] = local_indices(
        loader.links["data"][relation_id], src_id, dst_id, loader.nodes["shift"]
    )

num_nodes = {
    NODE_TYPES[node_id]: int(loader.nodes["count"][node_id])
    for node_id in NODE_TYPES
}
graph = dgl.heterograph(graph_data, num_nodes_dict=num_nodes)

for node_id, node_type in NODE_TYPES.items():
    features = loader.nodes["attr"][node_id]
    if features is None:
        tensor = torch.eye(num_nodes[node_type], dtype=torch.float32)
    else:
        tensor = torch.from_numpy(features.astype(np.float32))
    graph.nodes[node_type].data[node_type] = tensor

target_count = num_nodes["A"]
labels = torch.full((target_count,), -1, dtype=torch.long)
train_global = np.flatnonzero(loader.labels_train["mask"])
test_global = np.flatnonzero(loader.labels_test["mask"])
labels[train_global] = torch.from_numpy(
    loader.labels_train["data"][train_global].argmax(axis=1).astype(np.int64)
)
labels[test_global] = torch.from_numpy(
    loader.labels_test["data"][test_global].argmax(axis=1).astype(np.int64)
)

rng = np.random.default_rng(42)
shuffled = train_global.copy()
rng.shuffle(shuffled)
validation_size = int(round(0.2 * len(shuffled)))
validation = np.sort(shuffled[:validation_size])
training = np.sort(shuffled[validation_size:])
testing = np.sort(test_global)

OUTPUT.mkdir(parents=True, exist_ok=True)
output_path = OUTPUT / "DBLP.pkl"
save_graphs(
    str(output_path),
    [graph],
    {
        "A": labels,
        "A_train": torch.from_numpy(training),
        "A_val": torch.from_numpy(validation),
        "A_test": torch.from_numpy(testing),
        "A_test_full": torch.from_numpy(testing),
    },
)

print(f"output={output_path}")
print(f"node_counts={num_nodes}")
print(f"edge_count={graph.num_edges()}")
print(
    f"split_sizes=train:{len(training)},val:{len(validation)},test:{len(testing)}"
)
print(f"label_classes={int(labels.max()) + 1}")
