#!/bin/bash
# 递增build号
# 用法: ./increment_build.sh [edition]
# edition: lite 或 pro（可选，默认为lite）

set -e

EDITION="${1:-lite}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 从pubspec.yaml读取当前版本号
CURRENT_VERSION=$(grep "^version:" "$PROJECT_ROOT/pubspec.yaml" | sed 's/version: //' | tr -d ' ')

# 解析版本号
VERSION_PART=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
CURRENT_BUILD=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

# 递增build号
NEW_BUILD=$((CURRENT_BUILD + 1))

# 更新pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^version: .*/version: $VERSION_PART+$NEW_BUILD/" "$PROJECT_ROOT/pubspec.yaml"
else
    # Linux
    sed -i "s/^version: .*/version: $VERSION_PART+$NEW_BUILD/" "$PROJECT_ROOT/pubspec.yaml"
fi

echo "版本号已更新: $VERSION_PART+$NEW_BUILD (edition: $EDITION)"

