# 模块1：R-HGNN 异质图参数效率

## 验收指标

连续测试3次，每次实际构造的 R-HGNN 模型参数量均不超过 **5.64M**。

## 快速复现

```bash
cd module_1_r_hgnn
bash 启动.sh prepare
GPU=0 bash 启动.sh eval
```

`eval` 会执行3次模型构造与短步运行，分别保存完整日志，并由 `summarize.py` 逐次检查参数量。结果写入 `results/summary.json`，单次日志写入 `logs/run_1.log` 至 `logs/run_3.log`。

## 从数据训练并加载 checkpoint

首次运行时，下面的命令会下载并预处理 OGB-MAG，然后按固定上游超参数训练 R-HGNN。该流程耗时较长，且需要为 OGB-MAG 预留足够磁盘空间。

```bash
PREPROCESS=1 GPU=0 bash 启动.sh train
GPU=0 bash 启动.sh checkpoint
```

已有预处理数据时，直接执行 `GPU=0 bash 启动.sh train`。训练 checkpoint 保存在上游仓库的 `save_model/OGB_MAG/`，`checkpoint` 会加载该文件并运行上游完整测试集评测。终版表6-7只验收参数量，因此用于交付验收的入口仍为 `bash 启动.sh eval`。

## 固定上游版本

- R-HGNN: `b6440ed910d6d47b1f6911549c24a0c0644cb0ea`
- Source: https://github.com/yule-BUAA/R-HGNN

若 PyTorch/CUDA 版本与推荐环境不同，可通过 `PYG_WHEEL_URL` 指定匹配版本的 PyG 扩展 wheel 索引。
