# Data construction

- ACM and DBLP are read from the public THUDM/HGB repository and converted by
  `scripts/prepare_seq_hgnn_acm.py` and `scripts/prepare_seq_hgnn_dblp.py`.
- OGB-MAG is downloaded through the official Stanford OGB package on first use.
- Generated Seq-HGNN files are placed under `repos/SEQ_HGNN/dataset/`.

Run `bash setup/prepare_data.sh` after creating the graph environment.
Dataset users must comply with the HGB and OGB terms.
