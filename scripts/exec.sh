#!/usr/bin/env bash

set -euo pipefail

print_help() {
    cat <<'EOF'
Usage: ./scripts/exec.sh [container-name]

Open a shell in an existing container. Defaults to tmp.

Options:
  -h, --help            Show this help message and exit.
EOF
}

case "${1:-}" in
    -h|--help)
        print_help
        exit 0
        ;;
esac

CONTAINER_NAME="${1:-tmp}"

if [[ -z "$(docker ps -q -f "name=^${CONTAINER_NAME}$")" ]]; then
    docker start "${CONTAINER_NAME}"
fi

docker exec -it "${CONTAINER_NAME}" /bin/bash
