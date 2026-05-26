#!/usr/bin/env bash

set -euxo pipefail

print_help() {
    cat <<'EOF'
Usage: /usr/local/bin/install-torch.sh

Optionally install PyTorch into a dedicated uv-managed virtual environment.

The script is a no-op unless INSTALL_TORCH is set to "true".

Environment:
  INSTALL_TORCH         Install torch only when set to "true". Default: false.
  TORCH_VERSION         Torch version to pin, for example 2.11.0. Required when installing.
  TORCH_INDEX_URL       PyTorch wheel index URL. Default: the CPU index.
  TORCH_HOME            Target venv directory. Default: /opt/torch.
  UV_HOME               Directory containing the uv binary. Default: /opt/uv.
EOF
}

case "${1:-}" in
    -h|--help)
        print_help
        exit 0
        ;;
esac

if [[ "${INSTALL_TORCH:-false}" != "true" ]]; then
    echo "[install-torch] INSTALL_TORCH is not 'true'; skipping torch installation."
    exit 0
fi

: "${TORCH_VERSION:?TORCH_VERSION is required when INSTALL_TORCH=true}"

UV_BIN="${UV_HOME:-/opt/uv}/uv"
TORCH_HOME="${TORCH_HOME:-/opt/torch}"
TORCH_INDEX_URL="${TORCH_INDEX_URL:-https://download.pytorch.org/whl/cpu}"

if [[ ! -x "${UV_BIN}" ]]; then
    echo "[install-torch] ERROR: uv not found at ${UV_BIN}." >&2
    exit 1
fi

"${UV_BIN}" venv --python 3.12 "${TORCH_HOME}"
"${UV_BIN}" pip install --python "${TORCH_HOME}/bin/python" --no-cache \
    "torch==${TORCH_VERSION}" torchvision torchaudio \
    --index-url "${TORCH_INDEX_URL}"

echo "[install-torch] Installed torch==${TORCH_VERSION} into ${TORCH_HOME} from ${TORCH_INDEX_URL}"
