#!/bin/bash
# 获取当前版本号
# 用法: ./get_version.sh [edition]
# edition: lite 或 pro（可选，默认为lite）

set -e

EDITION="${1:-lite}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 从pubspec.yaml读取版本号
VERSION=$(grep "^version:" "$PROJECT_ROOT/pubspec.yaml" | sed 's/version: //' | tr -d ' ')

# 解析版本号 (格式: major.minor.patch+build)
VERSION_PART=$(echo "$VERSION" | cut -d'+' -f1)
BUILD_PART=$(echo "$VERSION" | cut -d'+' -f2)

# 输出版本信息
echo "VERSION=$VERSION_PART"
echo "BUILD=$BUILD_PART"
echo "EDITION=$EDITION"
echo "FULL_VERSION=$VERSION_PART+$EDITION.$BUILD_PART"

