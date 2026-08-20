# 模块2：TPNet 与 DyGKT 动态图性能

## 验收指标

两种方法均固定 seed 0、1、2 测试3次，每一次都必须满足：

- TPNet 在 UN Trade 上的 AP 不低于 **85.9%**；
- DyGKT 在 ASSISTment17 上的 AP 不低于 **71.6%**、AUC 不低于 **80.1%**。

## 准备、训练与评测

```bash
cd module_2_tpnet
bash 启动.sh prepare
GPU=0 bash 启动.sh train
GPU=0 bash 启动.sh eval
```

`prepare` 会克隆固定版本 TPNet 和 DyGKT，应用复现改动，并从 Zenodo 下载 UN Trade。`train` 对两种方法分别训练 seed 0、1、2；`eval` 加载六个 checkpoint，完成 TPNet 的 UN Trade 推理和 DyGKT 的 ASSISTment17 推理，然后逐次验收性能指标。

ASSISTment17 受数据使用条款约束，不在本仓库重复发布。接受其条款后，按 `docs/DATA.md` 构造以下文件：

```text
repos/DyGKT/processed_data/assist17/ml_assist17.csv
repos/DyGKT/processed_data/assist17/ml_assist17.npy
repos/DyGKT/processed_data/assist17/ml_assist17_node.npy
```

如果 checkpoint 已由其他机器训练，可跳过 `train`，将文件放到以下仓库相对路径：

```text
test_report_full_readme_untrade_seed0_UNtrade_link_UNtrade_TPNet_seed0.pkl
test_report_full_readme_untrade_seed1_UNtrade_link_UNtrade_TPNet_seed1.pkl
test_report_full_readme_untrade_seed2_UNtrade_link_UNtrade_TPNet_seed2.pkl

repos/DyGKT/saved_models/DyGKT/assist17/DyGKT_full_readme_seed0/DyGKT_full_readme_seed0.pkl
repos/DyGKT/saved_models/DyGKT/assist17/DyGKT_full_readme_seed1/DyGKT_full_readme_seed1.pkl
repos/DyGKT/saved_models/DyGKT/assist17/DyGKT_full_readme_seed2/DyGKT_full_readme_seed2.pkl
```

结构化结果保存在 `module_2_tpnet/results/summary.json`。

## 固定上游版本

- TPNet: `7dd0cf49695a581c5c541baeda47c1b5e98e8748`
- TPNet source: https://github.com/lxd99/TPNet
- DyGKT: `88e364881397e3dcfd266c387e8bcde666ab06cc`
- DyGKT source: https://github.com/PengLinzhi/DyGKT
- UN Trade: https://zenodo.org/records/7213796/files/UNtrade.zip?download=1
