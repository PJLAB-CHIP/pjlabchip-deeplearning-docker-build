# deeplearning-docker-build
Dockerfiles, data and build scripts for creating and maintaining the pjlabchip/deeplearning container image.

## Usage

Use the scripts in `scripts/` rather than long `docker` commands by hand. Every script supports `-h`/`--help` for the full set of options.

**Build**

```bash
bash ./scripts/build.sh Dockerfile.cpu      # build the CPU image and print its tag
bash ./scripts/build.sh Dockerfile.cuda     # build the CUDA image
```

Version values (image repository, CUDA/Torch versions, `IMAGE_VERSION`) live in `scripts/image-configs.sh`. Set `INSTALL_TORCH=true` to also bake PyTorch into the image.

**Run**

```bash
# interactive, removed on exit
bash ./scripts/run.sh -i pjlabchip/deeplearning:v2.5.4-cuda13.0.2 --tmp
# named, long-lived container in the background
bash ./scripts/run.sh -i <image> -c devbox
# open a shell in an existing container (starts it if stopped)
bash ./scripts/exec.sh devbox
```

GPU access is enabled automatically for image names containing `cuda`.

**Release**

```bash
bash ./scripts/next-version.sh --patch --push   # bump IMAGE_VERSION, commit, tag, push
bash ./scripts/next-version.sh --minor --push   # or --major --push for larger bumps
```

Pushing a tag (`v*` / `V*`) triggers the GitHub workflow, which builds and publishes the image variants to Docker Hub.

## Python environment (uv + PyTorch)

The image standardizes on [uv](https://docs.astral.sh/uv/) for Python — a fast, drop-in replacement for `pip`/`venv`/`pyenv`. There is no bare `pip`; use `uv pip` instead. On the `-torch*` image variants, PyTorch comes preinstalled in a uv-managed virtual environment at `/opt/torch`.

**Add packages** — activate the venv, then install with `uv pip` (uv installs into the active venv automatically):

```bash
source /opt/torch/bin/activate
uv pip install transformers accelerate datasets   # installed into /opt/torch
```

**Just run code** — no activation needed. `/opt/torch/bin` is already on `PATH` at login, so `python` resolves to the torch venv and `import torch` works out of the box. Toggle it for the current shell with `UNLOAD_TORCH` (fall back to the clean system `python`) and `LOAD_TORCH` (switch back).
