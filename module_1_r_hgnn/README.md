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

## 固定上游版本

- R-HGNN: `b6440ed910d6d47b1f6911549c24a0c0644cb0ea`
- Source: https://github.com/yule-BUAA/R-HGNN

本模块的参数评测不依赖训练 checkpoint。`train` 模式给出完整 OGB-MAG 训练入口说明；运行前需按上游 README 准备数据。
