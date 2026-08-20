# 模块3：SMP 静态剪枝参数效率

## 验收指标

连续测试3次，每次加载 BERT-base 和 SMP 50% 静态剪枝掩码后，可训练参数量均不超过 **84,934,656**。

## 快速复现

```bash
cd module_3_smp
bash 启动.sh prepare
GPU=0 bash 启动.sh eval
```

`prepare` 会克隆固定版本 SMP、创建独立环境、下载 BERT-base 和官方发布的 `mnli_0.50_kd_mag.npy`。`eval` 连续加载3次并逐次统计可训练参数量。

官方 checkpoint 之外，也可重新执行论文剪枝流程：

```bash
bash 启动.sh train
```

该命令调用固定版本上游仓库的 `bash run.sh mnli_0.50_kd_mag`。知识蒸馏训练需要按上游 README 准备 teacher model。训练完成后，将导出的掩码放到 `data/mnli_0.50_kd_mag.npy`，再运行 `eval`。

## 固定上游版本

- SMP: `c89634ae79c7845066e33cc48cee96cd4dbc1d89`
- Source: https://github.com/kongds/SMP
- Official mask: https://github.com/kongds/SMP/releases/download/SMP-S/mnli_0.50_kd_mag.npy.zip
