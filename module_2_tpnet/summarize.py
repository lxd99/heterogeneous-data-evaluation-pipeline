#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--results", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()

ap_runs = []
for seed in range(3):
    path = args.results / "tpnet" / f"test_report_full_readme_untrade_seed{seed}_UNtrade_link_random_UNtrade_TPNet_seed{seed}.json"
    value = float(json.loads(path.read_text())["test metrics"]["average_precision"]) * 100
    passed = value >= 85.9
    ap_runs.append({"run": seed + 1, "seed": seed, "ap_percent": value, "pass": passed})
    print(f"[TPNet][RUN {seed + 1}] UN Trade AP={value:.2f}% >= 85.9%: {'PASS' if passed else 'FAIL'}")

requirements = {"lastfm": {"DyGFormer": 66.0, "CAWN": 90.0}, "mooc": {"DyGFormer": 38.0, "CAWN": 51.0}}
efficiency = {}
for dataset in ("lastfm", "mooc"):
    values = {}
    for model in ("TPNet", "DyGFormer", "CAWN"):
        path = args.results / "efficiency" / f"{dataset}_{model}.json"
        values[model] = json.loads(path.read_text())["seconds_per_batch"][:3]
    runs = []
    for index in range(3):
        dy = values["DyGFormer"][index] / values["TPNet"][index]
        cawn = values["CAWN"][index] / values["TPNet"][index]
        passed = dy >= requirements[dataset]["DyGFormer"] and cawn >= requirements[dataset]["CAWN"]
        runs.append({"run": index + 1, "speedup_vs_DyGFormer": dy, "speedup_vs_CAWN": cawn, "pass": passed})
    efficiency[dataset] = runs

for index in range(3):
    lastfm = efficiency["lastfm"][index]
    mooc = efficiency["mooc"][index]
    passed = lastfm["pass"] and mooc["pass"]
    print(f"[TPNet][EFFICIENCY][RUN {index + 1}] LastFM={lastfm['speedup_vs_DyGFormer']:.3f}x/{lastfm['speedup_vs_CAWN']:.3f}x; MOOC={mooc['speedup_vs_DyGFormer']:.3f}x/{mooc['speedup_vs_CAWN']:.3f}x: {'PASS' if passed else 'FAIL'}")

overall = all(item["pass"] for item in ap_runs) and all(item["pass"] for runs in efficiency.values() for item in runs)
summary = {"requirements": {"UN_Trade_AP_percent_min": 85.9, **requirements}, "ap_runs": ap_runs, "efficiency": efficiency, "overall_pass": overall}
args.output.write_text(json.dumps(summary, indent=2) + "\n")
print(f"[MODULE][RESULT] {'OVERALL PASS' if overall else 'OVERALL FAIL'}")
if not overall:
    raise SystemExit(1)
