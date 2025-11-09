#!/bin/bash
# shellcheck shell=bash
#
# 执行一次修复并生成报告
# 这个脚本只执行一次修复，不自动循环
# AI 会根据报告决定下一步行动
#
# 用法:
#   ./fix_once.sh                    # 执行一次修复
#   ./fix_once.sh --save-before      # 保存修复前的 analyze 结果
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TMP_DIR="$ROOT_DIR/.tmp"
ANALYZE_BEFORE="$TMP_DIR/analyze_before.json"
ANALYZE_AFTER="$TMP_DIR/analyze_after.json"

# 颜色定义
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 参数解析
SAVE_BEFORE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --save-before)
            SAVE_BEFORE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# 创建临时目录
mkdir -p "$TMP_DIR"

log_info() {
    echo -e "${BLUE}[fix-once]${NC} $1"
}

# 运行 analyze 并保存结果
run_analyze() {
    local output_file="$1"
    log_info "Running dart analyze..."
    cd "$ROOT_DIR"
    dart analyze --format=json > "$output_file" 2>&1 || true
}

# 主流程
log_info "=== Single Fix Execution ==="

# 步骤 1: 保存修复前的状态（可选）
if [[ "$SAVE_BEFORE" == "true" ]]; then
    run_analyze "$ANALYZE_BEFORE"
    log_info "Before state saved to: $ANALYZE_BEFORE"
    python3 "$SCRIPT_DIR/analyze_stats.py" "$ANALYZE_BEFORE" || true
fi

# 步骤 2: 执行修复
log_info "Running fix script..."
cd "$ROOT_DIR"
python3 "$SCRIPT_DIR/issues.py"

# 步骤 3: 保存修复后的状态
run_analyze "$ANALYZE_AFTER"
log_info "After state saved to: $ANALYZE_AFTER"

# 步骤 4: 显示对比（如果保存了修复前的状态）
if [[ "$SAVE_BEFORE" == "true" ]] && [[ -f "$ANALYZE_BEFORE" ]]; then
    log_info "Comparing before and after:"
    echo "--- Before ---"
    python3 "$SCRIPT_DIR/analyze_stats.py" "$ANALYZE_BEFORE" || true
    echo "--- After ---"
    python3 "$SCRIPT_DIR/analyze_stats.py" "$ANALYZE_AFTER" || true
fi

log_info "Fix execution completed. Review the output above to decide next steps."
