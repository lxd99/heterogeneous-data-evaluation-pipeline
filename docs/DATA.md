# Data construction

## TPNet

`setup/prepare_data.sh` 从 Zenodo record 7213796 下载 Wikipedia、Enron、UCI、
MOOC 和 LastFM，并建立 `repos/TPNet/processed_data/<dataset>`。

Source: https://zenodo.org/records/7213796

## DyGKT ASSISTment17

接受 ASSISTments 数据条款后，按时间排序交互并构造：

```text
repos/DyGKT/processed_data/assist17/ml_assist17.csv
repos/DyGKT/processed_data/assist17/ml_assist17.npy
repos/DyGKT/processed_data/assist17/ml_assist17_node.npy
```

CSV 必须包含 `u,i,ts,label,idx`：学生节点、题目节点、时间戳、0/1 正确性标签
和从 1 开始的交互编号。学生和题目的节点编号空间不能重叠。边特征和节点特征
分别保存在两个 NumPy 文件中；本报告配置允许使用零初始化特征。
