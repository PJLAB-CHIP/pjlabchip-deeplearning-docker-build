# deeplearning-docker-build
Dockerfiles, data and build scripts for creating and maintaining the pjlabchip/deeplearning container image.

## Python environment (uv + PyTorch)

The image standardizes on [uv](https://docs.astral.sh/uv/) for Python — a fast, drop-in replacement for `pip`/`venv`/`pyenv`. There is no bare `pip`; use `uv pip` instead. On the `-torch*` image variants, PyTorch comes preinstalled in a uv-managed virtual environment at `/opt/torch`.

**Add packages** — activate the venv, then install with `uv pip` (uv installs into the active venv automatically):

```bash
source /opt/torch/bin/activate
uv pip install transformers accelerate datasets   # installed into /opt/torch
```

**Just run code** — no activation needed. `/opt/torch/bin` is already on `PATH` at login, so `python` resolves to the torch venv and `import torch` works out of the box. Toggle it for the current shell with `UNLOAD_TORCH` (fall back to the clean system `python`) and `LOAD_TORCH` (switch back).
