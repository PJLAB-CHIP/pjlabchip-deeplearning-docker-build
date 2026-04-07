#!/bin/bash
set -e

IMAGE_NAME=""
CONTAINER_NAME="tmp"
TMP="false"
PROXY_URL=""
SYS_ADMIN="false"

function print_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help             Show this help message and exit"
    echo "  -i, --image-name       Name of the Docker image to use (required)"
    echo "  -c, --container-name   Name of the Docker container (default: tmp)"
    echo "  --tmp                  Create a temporary container and attach to it;"
    echo "                         The container would be removed after exit"
    echo "  --proxy <url>          Set http_proxy, https_proxy, and all_proxy"
    echo "  --sys-admin              Add SYS_ADMIN capability to the container"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--image-name)
            IMAGE_NAME="$2"; shift ;;
        -c|--container-name)
            CONTAINER_NAME="$2"; shift ;;
        --tmp)
            TMP="true" ;;
        --proxy)
            PROXY_URL="$2"; shift ;;
        --sys-admin)
            SYS_ADMIN="true" ;;
        -h|--help)
            print_help; exit 0 ;;
        *)
            echo "[build.sh] ERROR: Unknown argument: $1"
            print_help; exit 1 ;;
    esac
    shift
done

if [ -z "$IMAGE_NAME" ]; then
    echo "[run.sh] ERROR: Image name is required. Use -i or --image-name to specify it."
    exit 1
fi

if [ -n "$PROXY_URL" ]; then
    PROXY_ARGS=(
        -e "http_proxy=$PROXY_URL"
        -e "https_proxy=$PROXY_URL"
        -e "all_proxy=$PROXY_URL"
    )
else
    PROXY_ARGS=()
fi

if [ "$SYS_ADMIN" = "true" ]; then
    SYS_ADMIN_ARGS=(--cap-add SYS_ADMIN)
else
    SYS_ADMIN_ARGS=()
fi

DOCKER_RUN_ARGS=(
    --name "$CONTAINER_NAME"
    --network host
    --shm-size 20G
    --hostname "$CONTAINER_NAME"
    -v /home:/home
)

if [ "$TMP" = "true" ] || [[ "$IMAGE_NAME" == *"cuda"* ]]; then
    DOCKER_RUN_ARGS+=(--gpus all)
fi

DOCKER_RUN_ARGS+=("${PROXY_ARGS[@]}" "${SYS_ADMIN_ARGS[@]}")

if [ "$TMP" = "true" ]; then
    docker run -it --rm "${DOCKER_RUN_ARGS[@]}" "$IMAGE_NAME" /bin/bash
else
    docker run -td "${DOCKER_RUN_ARGS[@]}" "$IMAGE_NAME"
    docker cp "$HOME/.ssh" "$CONTAINER_NAME:/root/"
    docker start "$CONTAINER_NAME"
    docker exec "$CONTAINER_NAME" chown -R root:root /root/.ssh
fi
