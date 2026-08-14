# Validated environment

- Ubuntu Linux
- 2 x NVIDIA RTX 3090 (24 GiB); extra GPUs are optional
- CUDA 11.8
- Python 3.9
- PyTorch 2.0.1
- DGL 1.1.2
- Transformers 4.17.0 for SMP
- Transformers 4.41.2 and Accelerate 0.27.2 for E5-V

Separate environments are required because SMP and E5-V use incompatible versions
of Transformers and Datasets. On a different CUDA version, install its matching
PyTorch wheel first, then install the remaining requirements.
