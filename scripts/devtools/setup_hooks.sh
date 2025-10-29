#!/usr/bin/env bash
# 建议通过 `scripts/anz hooks:install` 调用；此脚本作为底层实现保留。
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

echo "[setup] Configure git hooks path ..."
git config core.hooksPath scripts/git-hooks

echo "[setup] Make hooks executable ..."
chmod +x "$ROOT_DIR/scripts/git-hooks/pre-commit"
chmod +x "$ROOT_DIR/scripts/git-hooks/pre-push"

echo "[setup] Done. Hooks installed."
