#!/usr/bin/env bash

set -euo pipefail

if [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
  ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  echo "${TZ}" > /etc/timezone
fi

if [[ $# -eq 0 ]]; then
  exec "/bin/bash"
else
  exec "$@"
fi
