# 最终测试报告对应结果

本文件只记录最终测试报告中的简化验收口径。实际复现结果以新运行日志为准。

## 3.1 异构图表征学习

- Seq-HGNN：
  - DBLP 测试 Macro-F1：92.782 ± 0.289%
  - ACM 测试 Macro-F1：90.888 ± 1.110%
  - OGB-MAG 验证/测试准确率：41.573 ± 0.248% / 41.807 ± 0.287%
- R-HGNN：
  - 实测参数量：5,638,053
  - 相对 HGT 论文报告的 12.06M 参数减少：53.249975%

## 3.2 动态图表征学习

- TPNet：
  - Wikipedia AP/AUC：99.324 / 99.294
  - Enron AP/AUC：93.040 / 94.254
  - UCI AP/AUC：97.358 / 96.806
  - MOOC AP/AUC：96.425 / 97.220
  - 四个数据集平均 AP 相对 TGN 论文基线提升：5.369%
  - LastFM 相对 DyGFormer/CAWN 加速：67.352 / 93.156 倍
  - MOOC 相对 DyGFormer/CAWN 加速：39.115 / 51.295 倍
- DyGKT：
  - ASSISTment17 AP/AUC：71.74 / 80.24
  - 相对论文基线提升：5.236908% / 3.562210%
  - 可训练参数：76,593，FP32 参数存储量约 0.292179 MiB

## 3.3 高效大模型训练

- SMP：
  - 可训练掩码参数：84,934,656
  - 相对 170M 全参数基线减少：50.038438%
- E5-V：
  - Flickr30K Recall@1：79.640%，相对 CLIP ViT-L 提升 18.335811%
  - COCO Recall@1：51.988%，相对 CLIP ViT-L 提升 40.508107%

## 原始证据

- reference/test-evidence/section_3_1_heterogeneous_graph.log
- reference/test-evidence/section_3_2_dynamic_graph.log
- reference/test-evidence/section_3_3_efficient_large_model.log
- reference/test-evidence/dygkt_parameter_count.log
