# Module 3.1: Heterogeneous Graph Representation

本分支只包含异构图表征学习模块的复现 pipeline：

- Seq-HGNN：ACM、DBLP 和 OGB-MAG
- R-HGNN：OGB-MAG 配置下的参数量与短步执行链路

## 快速开始

```bash
git clone --branch module-3-1-heterogeneous-graph \
  https://github.com/lxd99/heterogeneous-data-evaluation-pipeline.git
cd heterogeneous-data-evaluation-pipeline

bash setup/clone_repos.sh
PYTHON_BIN=python3.9 bash setup/create_envs.sh
bash setup/prepare_data.sh
bash verify_setup.sh
GPU=0 bash run.sh smoke
```

一键准备：

```bash
PYTHON_BIN=python3.9 bash setup/all.sh
```

## 完整评测

```bash
CONFIRM_FULL=1 GPU0=0 GPU1=1 bash run.sh full
```

完整评测运行 Seq-HGNN 的 DBLP、ACM 五种子和 OGB-MAG 三种子实验，
并输出 R-HGNN 参数量。日志保存于 `runs/` 和 `logs/`。

数据来源、目录结构和环境要求见 `docs/DATA.md`、`docs/ENVIRONMENT.md`。
目标结果见 `EXPECTED_RESULTS.md`。
