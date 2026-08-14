import os
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[1] / "repos/SEQ_HGNN"
sys.path.insert(0, str(REPO))
os.chdir(REPO)

from data import load_data


data, target_type, label_name, num_classes, threshold = load_data("ogbn-mag")
print(f"target_type={target_type}")
print(f"label_name={label_name}")
print(f"num_classes={num_classes}")
print(f"threshold={threshold}")
print(f"node_types={data.node_types}")
print(f"edge_types={data.edge_types}")
for node_type in data.node_types:
    print(f"nodes[{node_type}]={data[node_type].num_nodes}")
