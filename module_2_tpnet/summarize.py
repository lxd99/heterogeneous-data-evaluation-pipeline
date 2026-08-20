#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--results", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()

tpnet_runs = []
for seed in range(3):
    path = args.results / "tpnet" / f"test_report_full_readme_untrade_seed{seed}_UNtrade_link_random_UNtrade_TPNet_seed{seed}.json"
    value = float(json.loads(path.read_text())["test metrics"]["average_precision"]) * 100
    passed = value >= 85.9
    tpnet_runs.append({"run": seed + 1, "seed": seed, "ap_percent": value, "pass": passed})
    print(f"[TPNet][RUN {seed + 1}] UN Trade AP={value:.2f}% >= 85.9%: {'PASS' if passed else 'FAIL'}")

overall = all(item["pass"] for item in tpnet_runs)
summary = {
    "requirements": {"TPNet_UN_Trade_AP_percent_min": 85.9},
    "tpnet_runs": tpnet_runs,
    "overall_pass": overall,
}
args.output.write_text(json.dumps(summary, indent=2) + "\n")
print(f"[MODULE][RESULT] {'OVERALL PASS' if overall else 'OVERALL FAIL'}")
if not overall:
    raise SystemExit(1)
