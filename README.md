# Heterogeneous Data Evaluation Pipeline

This pipeline reproduces the three modules in the final test report:

- 3.1 heterogeneous graph representation: Seq-HGNN and R-HGNN
- 3.2 dynamic graph representation: TPNet and DyGKT
- 3.3 efficient large-model training: SMP and E5-V

Third-party repositories, datasets, weights and environments are not copied into this
repository. Setup scripts clone fixed commits, apply the evaluation changes and fetch
public data/model files from their original sources.

## Validated hardware

Ubuntu, Python 3.9, CUDA 11.8 and two RTX 3090 GPUs. One GPU is sufficient for
smoke tests; the complete E5-V retrieval task uses two GPUs.

## Quick start

```bash
git clone https://github.com/lxd99/heterogeneous-data-evaluation-pipeline.git
cd heterogeneous-data-evaluation-pipeline

bash setup/clone_repos.sh
PYTHON_BIN=python3.9 bash setup/create_envs.sh
bash setup/prepare_data.sh
bash verify_setup.sh
GPU=0 bash run.sh smoke
```

One-command setup:

```bash
PYTHON_BIN=python3.9 bash setup/all.sh
```

## Full evaluation

```bash
CONFIRM_FULL=1 GPU0=0 GPU1=1 bash run.sh full-3.1
CONFIRM_FULL=1 GPU0=0 GPU1=1 bash run.sh full-3.2
CONFIRM_FULL=1 GPU0=0 GPU1=1 bash run.sh full-3.3
```

Run all three modules sequentially:

```bash
CONFIRM_FULL=1 GPU0=0 GPU1=1 bash run.sh full-all
```

Full runs can take hours. The explicit `CONFIRM_FULL=1` guard prevents accidental
submission of expensive jobs.

## Output files

- outer command logs: `runs/`
- per-method logs: `logs/`
- structured metrics: `results/`
- expected report values: `EXPECTED_RESULTS.md`
- fixed upstream revisions: `UPSTREAMS.tsv`

Each outer log records the command, timestamps and exit code. Retain the timestamped
logs when submitting test evidence.

## Layout

- `setup/`: repository, environment and data construction
- `scripts/`: portable evaluation entry points
- `patches/`: modifications applied to tracked upstream files
- `overrides/`: new evaluator files copied into upstream repositories
- `requirements/`: validated package versions
- `docs/DATA.md`: public data/model sources and path layout
- `docs/ENVIRONMENT.md`: validated environment

The fixed commits make source provenance explicit and avoid republishing third-party
repositories that do not declare a redistribution license.
