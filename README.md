# Module 3.2: TPNet Dynamic Link Prediction

本分支只包含 TPNet 在 UN Trade 上的复现 pipeline。固定 seed 0、1、2 测试3次，每次 AP 均需不低于 85.9%。

- 方法：TPNet
- 数据集：UN Trade
- 指标：Average Precision (AP)

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

## 完整评测

```bash
CONFIRM_FULL=1 GPU=0 bash run.sh full
```

该命令使用 seed 0、1、2 训练并评测 TPNet，结果保存到 `runs/`、`logs/` 和 `results/`。目标结果见 `EXPECTED_RESULTS.md`。
