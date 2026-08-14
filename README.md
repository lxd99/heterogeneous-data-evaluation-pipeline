# Module 3.2: Dynamic Graph Representation

本分支只包含动态图表征学习模块的复现 pipeline：

- TPNet：Wikipedia、Enron、UCI、MOOC、LastFM
- DyGKT：ASSISTment17
- TPNet、DyGFormer、CAWN 批次推理效率对比

## 快速开始

```bash
git clone --branch module-3-2-dynamic-graph \
  https://github.com/lxd99/heterogeneous-data-evaluation-pipeline.git
cd heterogeneous-data-evaluation-pipeline

bash setup/clone_repos.sh
PYTHON_BIN=python3.9 bash setup/create_envs.sh
bash setup/prepare_data.sh
bash verify_setup.sh
GPU=0 bash run.sh smoke
```

ASSISTment17 受数据使用条款约束，不能直接随仓库再分发。运行 DyGKT 前，
按 `docs/DATA.md` 将处理后的文件放到指定目录。

## 完整评测

```bash
CONFIRM_FULL=1 GPU0=0 GPU1=1 bash run.sh full
```

结果分别保存到 `runs/`、`logs/` 和 `results/`。
目标结果见 `EXPECTED_RESULTS.md`。
