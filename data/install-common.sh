#!/usr/bin/env bash

set -euxo pipefail

print_help() {
    cat <<'EOF'
Usage: /usr/local/bin/install-common.sh

Install the shared toolchain and utilities used by both Docker image variants.

Environment:
  LLVM_VERSION          LLVM major version to install. Required.
  VCPKG_HOME            Target directory for vcpkg. Required.
  UV_HOME               Target directory for uv. Required.
  TZ                    Optional timezone name to configure, for example Etc/UTC.
EOF
}

case "${1:-}" in
    -h|--help)
        print_help
        exit 0
        ;;
esac

export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"

apt-get update
apt-get install -y --no-install-recommends \
    apt-utils \
    lsb-release \
    software-properties-common \
    gnupg \
    git \
    acl \
    sed \
    vim-gtk3 \
    wget \
    p7zip-full \
    zip \
    unzip \
    tar \
    ninja-build \
    curl \
    jq \
    nodejs \
    npm \
    pkg-config \
    openssh-client \
    ccache \
    build-essential \
    gdb \
    htop \
    tmux \
    kmod \
    bubblewrap \
    libssl-dev \
    tzdata \
    ca-certificates

echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" \
    | debconf-set-selections
apt-get install -y --no-install-recommends ttf-mscorefonts-installer
fc-cache -f -v

if [ -n "${TZ:-}" ]; then
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
    echo "${TZ}" > /etc/timezone
fi

git clone https://github.com/microsoft/vcpkg.git "${VCPKG_HOME}"
pushd "${VCPKG_HOME}"
./bootstrap-vcpkg.sh
popd

wget -O /tmp/kitware-archive.sh https://apt.kitware.com/kitware-archive.sh
bash /tmp/kitware-archive.sh
apt-get update
apt-get install -y --no-install-recommends cmake

wget -O /tmp/llvm.sh https://apt.llvm.org/llvm.sh
chmod +x /tmp/llvm.sh
/tmp/llvm.sh "${LLVM_VERSION}"
apt-get update
apt-get install -y --no-install-recommends \
    "clang-${LLVM_VERSION}" \
    "lldb-${LLVM_VERSION}" \
    "clang-tools-${LLVM_VERSION}" \
    "libclang-${LLVM_VERSION}-dev" \
    "clang-format-${LLVM_VERSION}" \
    "libomp-${LLVM_VERSION}-dev" \
    "clangd-${LLVM_VERSION}" \
    "clang-tidy-${LLVM_VERSION}" \
    "libc++-${LLVM_VERSION}-dev" \
    "libc++abi-${LLVM_VERSION}-dev"

ln -sf "/usr/bin/clang-${LLVM_VERSION}" /usr/bin/clang
ln -sf "/usr/bin/clang++-${LLVM_VERSION}" /usr/bin/clang++
ln -sf "/usr/bin/clangd-${LLVM_VERSION}" /usr/bin/clangd
ln -sf "/usr/bin/clang-tidy-${LLVM_VERSION}" /usr/bin/clang-tidy
ln -sf "/usr/bin/clang-format-${LLVM_VERSION}" /usr/bin/clang-format
ln -sf "/usr/bin/lldb-${LLVM_VERSION}" /usr/bin/lldb

curl https://sh.rustup.rs -sSf | sh -s -- -y

curl -LsSf https://astral.sh/uv/install.sh | \
    env UV_INSTALL_DIR="${UV_HOME}" UV_NO_MODIFY_PATH=1 sh

apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -f /tmp/kitware-archive.sh /tmp/llvm.sh

git config --system --unset-all user.name || true
git config --system --unset-all user.email || true
git config --global --unset-all user.name || true
git config --global --unset-all user.email || true
