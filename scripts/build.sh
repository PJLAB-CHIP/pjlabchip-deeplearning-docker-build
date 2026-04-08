#!/usr/bin/env bash

set -euo pipefail

print_help() {
    cat <<'EOF'
Usage: ./scripts/build.sh <dockerfile>

Build one image variant and print the resulting image name.

Options:
  -h, --help            Show this help message and exit.

Examples:
  ./scripts/build.sh Dockerfile.cpu
  TZ=Etc/UTC ./scripts/build.sh Dockerfile.cuda
EOF
}

if [[ $# -eq 0 ]]; then
    echo "[build.sh] ERROR: Dockerfile path is required." >&2
    print_help >&2
    exit 1
fi

case "${1:-}" in
    -h|--help)
        print_help
        exit 0
        ;;
esac

DOCKER_FILE="$1"

if [[ ! -f "${DOCKER_FILE}" ]]; then
    echo "[build.sh] ERROR: Dockerfile not found: ${DOCKER_FILE}" >&2
    exit 1
fi

source ./scripts/image-configs.sh

IMAGE_NAME="$(resolve_image_name "${DOCKER_FILE}")"

DOCKER_BUILD_ARGS=(
    -f "${DOCKER_FILE}"
    --build-arg "IMAGE_VERSION=${IMAGE_VERSION}"
    --build-arg "IMAGE_NAME=${IMAGE_NAME}"
    --build-arg "UBUNTU_VERSION=${UBUNTU_VERSION}"
    --build-arg "LLVM_VERSION=${LLVM_VERSION}"
    --build-arg "CUDA_VERSION=${CUDA_VERSION}"
    -t "${IMAGE_NAME}"
    .
)

if [[ -n "${TZ:-}" ]]; then
    DOCKER_BUILD_ARGS=(--build-arg "TZ=${TZ}" "${DOCKER_BUILD_ARGS[@]}")
fi

docker build "${DOCKER_BUILD_ARGS[@]}"

echo "${IMAGE_NAME}"
