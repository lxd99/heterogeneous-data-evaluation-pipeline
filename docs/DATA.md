# Data and model construction

`setup/prepare_data.sh` 从原始公开来源下载：

- BERT: `bert-base-uncased`
- MNLI: Hugging Face GLUE dataset loader
- SMP 50% mask: https://github.com/kongds/SMP/releases/tag/SMP-S
- E5-V model: https://huggingface.co/royokong/e5-v
- Flickr30K test: `royokong/flickr30k_test`
- COCO test: `royokong/coco_test`

Constructed paths:

```text
data/models/bert-base-uncased
data/mnli_0.50_kd_mag.npy
data/models/e5-v-full
data/huggingface/e5v_datasets
```

Model and dataset users must comply with each upstream license and usage terms.
