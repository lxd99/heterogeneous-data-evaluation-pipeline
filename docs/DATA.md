# Data and model construction

No dataset or model weight is redistributed. `setup/prepare_data.sh` downloads from
the official public sources and constructs the paths consumed by `run.sh`.

| Module | Resource | Public source | Constructed path |
|---|---|---|---|
| Seq-HGNN | ACM, DBLP | THUDM/HGB | `repos/SEQ_HGNN/dataset/HGB_{ACM,DBLP}` |
| Seq-HGNN/R-HGNN | OGB-MAG | Stanford OGB | OGB and Seq-HGNN caches |
| TPNet | UN Trade | Zenodo 7213796 | `repos/TPNet/processed_data/UNtrade` |
| SMP | MNLI | Hugging Face GLUE | Hugging Face datasets cache |
| SMP | BERT base | `bert-base-uncased` | `data/models/bert-base-uncased` |
| SMP | 50% mask | SMP-S release | `data/mnli_0.50_kd_mag.npy` |
| E5-V | model | `royokong/e5-v` | `data/models/e5-v-full` |
| E5-V | Flickr30K, COCO | `royokong/flickr30k_test`, `royokong/coco_test` | Hugging Face cache |

Sources:

- TPNet: https://zenodo.org/records/7213796
- SMP: https://github.com/kongds/SMP/releases/tag/SMP-S
- E5-V: https://huggingface.co/royokong/e5-v
- OGB: https://ogb.stanford.edu/docs/home/

The evaluator must comply with each upstream dataset and model license or terms.
