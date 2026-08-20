#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path

LIMIT = 84_934_656
parser = argparse.ArgumentParser()
parser.add_argument("--logs", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()

runs = []
for index in range(1, 4):
    path = args.logs / f"run_{index}.log"
    match = re.search(r"^trainable_mask_parameters=(\d+)$", path.read_text(), re.MULTILINE)
    if not match:
        raise SystemExit(f"trainable_mask_parameters missing from {path}")
    value = int(match.group(1))
    passed = value <= LIMIT
    runs.append({"run": index, "trainable_parameters": value, "pass": passed})
    print(f"[SMP][RUN {index}] trainable parameters={value:,} <= {LIMIT:,}: {'PASS' if passed else 'FAIL'}")

summary = {"requirement": {"trainable_parameters_max": LIMIT}, "runs": runs, "overall_pass": all(item["pass"] for item in runs)}
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(summary, indent=2) + "\n")
print(f"[MODULE][RESULT] {'OVERALL PASS' if summary['overall_pass'] else 'OVERALL FAIL'}")
if not summary["overall_pass"]:
    raise SystemExit(1)
