# Heterogeneous Data Evaluation Pipeline

本仓库按更新版表6-7拆分为三个独立评测模块。每个目录都有自己的 `README.md`、`启动.sh` 和三次结果汇总脚本；每一次测试都必须满足对应绝对阈值，不采用平均值、最高值或相对提升作为验收结果。

| 目录 | 方法 | 绝对验收指标 |
| --- | --- | --- |
| `module_1_r_hgnn/` | R-HGNN | 模型参数量不超过 5.64M |
| `module_2_tpnet/` | TPNet | UN Trade AP 不低于 85.9%；LastFM 加速比不低于 66x/90x；MOOC 加速比不低于 38x/51x |
| `module_3_smp/` | SMP | 可训练参数量不超过 84,934,656 |

## 运行入口

```bash
git clone https://github.com/lxd99/heterogeneous-data-evaluation-pipeline.git
cd heterogeneous-data-evaluation-pipeline

(cd module_1_r_hgnn && bash 启动.sh help)
(cd module_2_tpnet && bash 启动.sh help)
(cd module_3_smp && bash 启动.sh help)
```

每个模块支持：

- `prepare`：克隆固定版本上游仓库、创建环境并准备公开数据/模型；
- `train`：运行论文训练或剪枝流程，生成 checkpoint；
- `eval`：加载3个固定 checkpoint 或结果，执行三次评测并逐次验收；
- `all`：顺序执行 `prepare`、`train`、`eval`。

直接复现终版测试指标时，进入对应模块后依次执行 `prepare`、`train` 和 `eval`；已有 checkpoint 时可跳过 `train`。R-HGNN 与 SMP 的终版指标是参数量，评测时会重新构造或加载模型3次，不依赖挑选最优训练结果。

每次运行的原始日志保存在模块内的 `logs/`，结构化三次结果和逐项 PASS/FAIL 保存在 `results/summary.json`。验收不使用平均值或挑选最优结果，任何一次未达到阈值都会以非零状态退出。

推荐 Ubuntu 20.04/22.04、Python 3.9、CUDA 11.8 和 RTX 3090。第三方仓库、模型权重和数据不重复提交，固定版本及公开来源见各模块 README。
