# Module 3.3: Efficient Large-Model Training

本分支只包含高效大模型训练模块的复现 pipeline：

- SMP：BERT-base、MNLI 和 50% 静态剪枝掩码
- E5-V：8B 多模态模型在 Flickr30K、COCO 上的零样本图文检索

## 快速开始

```bash
git clone --branch module-3-3-efficient-llm \
  https://github.com/lxd99/heterogeneous-data-evaluation-pipeline.git
cd heterogeneous-data-evaluation-pipeline

bash setup/clone_repos.sh
PYTHON_BIN=python3.9 bash setup/create_envs.sh
bash setup/prepare_data.sh
bash verify_setup.sh
GPU=0 bash run.sh smoke
```

SMP 与 E5-V 使用不同版本的 Transformers/Datasets，因此分别创建独立环境。
E5-V 权重约 16GB，完整检索建议使用两张 24GB GPU。

## 完整评测

```bash
CONFIRM_FULL=1 GPU0=0 GPU1=1 bash run.sh full
```

结果保存到 `runs/`、`logs/` 和 `results/`。数据来源见 `docs/DATA.md`，
目标结果见 `EXPECTED_RESULTS.md`。
