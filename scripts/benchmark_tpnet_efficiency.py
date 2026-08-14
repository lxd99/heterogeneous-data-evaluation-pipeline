import argparse
import json
import logging
import statistics
import sys
import time
from pathlib import Path

import numpy as np
import torch

REPO = Path(__file__).resolve().parents[1] / "repos/TPNet"
sys.path.insert(0, str(REPO))

from models.CAWN import CAWN
from models.DyGFormer import DyGFormer
from models.TPNet import RandomProjectionModule, TPNet
from utils.DataLoader import get_link_prediction_data
from utils.load_configs import get_link_prediction_args
from utils.utils import get_neighbor_sampler, set_random_seed, set_thread


def configured_args(dataset, model):
    argv = [
        "benchmark_tpnet_efficiency.py",
        "--dataset_name",
        dataset,
        "--model_name",
        model,
        "--gpu",
        "0",
        "--load_best_configs",
    ]
    if model == "TPNet":
        argv.append("--use_random_projection")
    original = sys.argv
    try:
        sys.argv = argv
        return get_link_prediction_args(is_evaluation=False)
    finally:
        sys.argv = original


def build_model(args, node_features, edge_features, sampler, train_data):
    if args.model_name == "TPNet":
        projections = RandomProjectionModule(
            node_num=node_features.shape[0],
            edge_num=edge_features.shape[0],
            dim_factor=args.rp_dim_factor,
            num_layer=args.rp_num_layer,
            time_decay_weight=args.rp_time_decay_weight,
            device=args.device,
            use_matrix=args.rp_use_matrix,
            beginning_time=train_data.node_interact_times[0],
            not_scale=args.rp_not_scale,
            enforce_dim=args.enforce_dim,
        ).to(args.device)
        # Build the same cached temporal representation used by TPNet inference.
        for start in range(0, train_data.num_interactions, 4096):
            end = min(start + 4096, train_data.num_interactions)
            projections.update(
                train_data.src_node_ids[start:end],
                train_data.dst_node_ids[start:end],
                train_data.node_interact_times[start:end],
            )
        model = TPNet(
            node_raw_features=node_features,
            edge_raw_features=edge_features,
            neighbor_sampler=sampler,
            time_feat_dim=args.time_feat_dim,
            random_projections=None if args.encode_not_rp else projections,
            num_neighbors=args.num_neighbors,
            num_layers=args.num_layers,
            dropout=args.dropout,
            device=args.device,
        )
    elif args.model_name == "CAWN":
        model = CAWN(
            node_raw_features=node_features,
            edge_raw_features=edge_features,
            neighbor_sampler=sampler,
            time_feat_dim=args.time_feat_dim,
            position_feat_dim=args.position_feat_dim,
            walk_length=args.walk_length,
            num_walk_heads=args.num_walk_heads,
            dropout=args.dropout,
            device=args.device,
        )
    elif args.model_name == "DyGFormer":
        model = DyGFormer(
            node_raw_features=node_features,
            edge_raw_features=edge_features,
            neighbor_sampler=sampler,
            time_feat_dim=args.time_feat_dim,
            channel_embedding_dim=args.channel_embedding_dim,
            patch_size=args.patch_size,
            num_layers=args.num_layers,
            num_heads=args.num_heads,
            dropout=args.dropout,
            max_input_sequence_length=args.max_input_sequence_length,
            device=args.device,
        )
    else:
        raise ValueError(args.model_name)
    return model.to(args.device).eval()


def forward(model_name, model, src, dst, neg_dst, timestamps, num_neighbors):
    if model_name == "CAWN":
        positive = model.compute_src_dst_node_temporal_embeddings(
            src_node_ids=src,
            dst_node_ids=dst,
            node_interact_times=timestamps,
            num_neighbors=num_neighbors,
        )
        negative = model.compute_src_dst_node_temporal_embeddings(
            src_node_ids=src,
            dst_node_ids=neg_dst,
            node_interact_times=timestamps,
            num_neighbors=num_neighbors,
        )
    else:
        positive = model.compute_src_dst_node_temporal_embeddings(
            src_node_ids=src,
            dst_node_ids=dst,
            node_interact_times=timestamps,
        )
        negative = model.compute_src_dst_node_temporal_embeddings(
            src_node_ids=src,
            dst_node_ids=neg_dst,
            node_interact_times=timestamps,
        )
    return positive[0].sum() + positive[1].sum() + negative[0].sum() + negative[1].sum()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", choices=["lastfm", "mooc"], required=True)
    parser.add_argument("--model", choices=["TPNet", "CAWN", "DyGFormer"], required=True)
    parser.add_argument("--warmup", type=int, default=2)
    parser.add_argument("--repeats", type=int, default=5)
    parser.add_argument("--batches", type=int, default=3)
    parser.add_argument("--output", required=True)
    bench = parser.parse_args()

    set_random_seed(0, deterministic_alg=False)
    set_thread(3)
    args = configured_args(bench.dataset, bench.model)
    logger = logging.getLogger("tpnet-efficiency")
    node_features, edge_features, full_data, train_data, _, test_data, _, _ = get_link_prediction_data(
        dataset_name=bench.dataset,
        val_ratio=args.val_ratio,
        test_ratio=args.test_ratio,
        logger=logger,
        convert_time=(args.use_random_projection or args.model_name == "PINT"),
    )
    sampler = get_neighbor_sampler(
        data=full_data,
        sample_neighbor_strategy=args.sample_neighbor_strategy,
        time_scaling_factor=args.time_scaling_factor,
        seed=1,
    )
    model = build_model(args, node_features, edge_features, sampler, train_data)

    batch_size = args.batch_size
    batches = []
    for index in range(bench.batches):
        start = index * batch_size
        end = min(start + batch_size, test_data.num_interactions)
        src = test_data.src_node_ids[start:end]
        dst = test_data.dst_node_ids[start:end]
        timestamps = test_data.node_interact_times[start:end]
        neg_dst = np.roll(dst, 1)
        batches.append((src, dst, neg_dst, timestamps))

    with torch.inference_mode():
        for _ in range(bench.warmup):
            for batch in batches:
                forward(bench.model, model, *batch, args.num_neighbors)
        torch.cuda.synchronize()

        per_batch_seconds = []
        for _ in range(bench.repeats):
            start = time.perf_counter()
            for batch in batches:
                forward(bench.model, model, *batch, args.num_neighbors)
            torch.cuda.synchronize()
            per_batch_seconds.append((time.perf_counter() - start) / len(batches))

    result = {
        "dataset": bench.dataset,
        "model": bench.model,
        "batch_size": batch_size,
        "timed_batches": len(batches),
        "warmup_rounds": bench.warmup,
        "repeat_rounds": bench.repeats,
        "seconds_per_batch": per_batch_seconds,
        "median_seconds_per_batch": statistics.median(per_batch_seconds),
        "min_seconds_per_batch": min(per_batch_seconds),
        "max_seconds_per_batch": max(per_batch_seconds),
        "num_neighbors": args.num_neighbors,
        "device": torch.cuda.get_device_name(0),
    }
    with open(bench.output, "w", encoding="utf-8") as handle:
        json.dump(result, handle, indent=2)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
