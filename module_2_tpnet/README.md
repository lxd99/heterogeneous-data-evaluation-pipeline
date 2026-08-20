# 模块2：TPNet 动态链接预测与推理效率

## 验收指标

固定 seed 0、1、2 测试3次，每一次都必须同时满足：

- UN Trade AP 不低于 **85.9%**；
- LastFM-DyGFormer 推理加速比不低于 **66x**；
- LastFM-CAWN 推理加速比不低于 **90x**；
- MOOC-DyGFormer 推理加速比不低于 **38x**；
- MOOC-CAWN 推理加速比不低于 **51x**。

## 准备、训练与评测

```bash
cd module_2_tpnet
bash 启动.sh prepare
GPU=0 bash 启动.sh train
GPU=0 bash 启动.sh eval
```

`prepare` 会克隆固定版本 TPNet，应用固定种子补丁，并从 Zenodo 下载 UN Trade、LastFM 和 MOOC。`train` 顺序训练 seed 0、1、2，每个 seed 输出独立 checkpoint。`eval` 加载三个 checkpoint，完成 UN Trade 测试集推理，然后执行三轮加速比测试并逐次验收。

如果 checkpoint 已由其他机器训练，可跳过 `train`，将以下文件放入 `repos/TPNet/saved_models/`：

```text
test_report_full_readme_untrade_seed0_UNtrade_link_UNtrade_TPNet_seed0.pkl
test_report_full_readme_untrade_seed1_UNtrade_link_UNtrade_TPNet_seed1.pkl
test_report_full_readme_untrade_seed2_UNtrade_link_UNtrade_TPNet_seed2.pkl
```

结构化结果保存在 `module_2_tpnet/results/summary.json`。

## 固定上游版本

- TPNet: `7dd0cf49695a581c5c541baeda47c1b5e98e8748`
- Source: https://github.com/lxd99/TPNet
- UN Trade: https://zenodo.org/records/7213796/files/UNtrade.zip?download=1
