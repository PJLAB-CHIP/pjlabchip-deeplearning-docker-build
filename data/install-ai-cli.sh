#!/usr/bin/env bash

set -euxo pipefail

npm install -g @openai/codex @anthropic-ai/claude-code
npm cache clean --force
