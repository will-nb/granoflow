#!/bin/bash
#
# YAML 一致性测试运行脚本
#
# 推荐通过 `scripts/anz yaml:test` 调用；此脚本保留给自动化或特殊场景。
#
# 用法:
#   ./scripts/devtools/run_yaml_tests.sh [选项]
#
# 选项:
#   --all              运行所有 YAML 测试（默认）
#   --schema           只运行 schema 验证测试
#   --fields           只运行字段完整性测试
#   --refs             只运行引用一致性测试
#   --sync             只运行代码同步测试
#   -v, --verbose      显示详细输出
#   -h, --help         显示帮助信息

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认参数
TEST_MODE="all"
VERBOSE=""

# 解析参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --all)
      TEST_MODE="all"
      shift
      ;;
    --schema)
      TEST_MODE="schema"
      shift
      ;;
    --fields)
      TEST_MODE="fields"
      shift
      ;;
    --refs)
      TEST_MODE="refs"
      shift
      ;;
    --sync)
      TEST_MODE="sync"
      shift
      ;;
    -v|--verbose)
      VERBOSE="--verbose"
      shift
      ;;
    -h|--help)
      echo "YAML 一致性测试运行脚本"
      echo ""
      echo "用法:"
      echo "  ./scripts/devtools/run_yaml_tests.sh [选项]"
      echo ""
      echo "选项:"
      echo "  --all              运行所有 YAML 测试（默认）"
      echo "  --schema           只运行 schema 验证测试"
      echo "  --fields           只运行字段完整性测试"
      echo "  --refs             只运行引用一致性测试"
      echo "  --sync             只运行代码同步测试"
      echo "  -v, --verbose      显示详细输出"
      echo "  -h, --help         显示帮助信息"
      echo ""
      echo "示例:"
      echo "  ./scripts/devtools/run_yaml_tests.sh                # 运行所有测试"
      echo "  ./scripts/devtools/run_yaml_tests.sh --schema       # 只运行 schema 验证"
      echo "  ./scripts/devtools/run_yaml_tests.sh --sync -v      # 运行代码同步测试（详细模式）"
      exit 0
      ;;
    *)
      echo -e "${RED}错误: 未知参数 '$1'${NC}"
      echo "使用 --help 查看帮助信息"
      exit 1
      ;;
  esac
done

# 打印横幅
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                   YAML 一致性测试${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# 根据模式运行测试
case $TEST_MODE in
  all)
    echo -e "${YELLOW}运行所有 YAML 一致性测试...${NC}"
    echo ""
    flutter test test/yaml/ $VERBOSE
    ;;
  schema)
    echo -e "${YELLOW}运行 Schema 验证测试...${NC}"
    echo ""
    flutter test test/yaml/schema_validation_test.dart $VERBOSE
    ;;
  fields)
    echo -e "${YELLOW}运行字段完整性测试...${NC}"
    echo ""
    flutter test test/yaml/field_completeness_test.dart $VERBOSE
    ;;
  refs)
    echo -e "${YELLOW}运行引用一致性测试...${NC}"
    echo ""
    flutter test test/yaml/reference_consistency_test.dart $VERBOSE
    ;;
  sync)
    echo -e "${YELLOW}运行代码同步测试...${NC}"
    echo ""
    flutter test test/yaml/code_sync_test.dart $VERBOSE
    ;;
esac

# 检查测试结果
if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}✅ 所有测试通过！${NC}"
  echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
  echo -e "${RED}❌ 测试失败${NC}"
  echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${YELLOW}⚠️  请注意：${NC}"
  echo -e "${YELLOW}   如果测试失败，AI 应该：${NC}"
  echo -e "${YELLOW}   ✅ 明确报告哪些地方不一致${NC}"
  echo -e "${YELLOW}   ✅ 列出 YAML 定义 vs 代码实际情况${NC}"
  echo -e "${YELLOW}   ✅ 退出并等待人工判断${NC}"
  echo ""
  echo -e "${YELLOW}   AI 不应该：${NC}"
  echo -e "${YELLOW}   ❌ 直接修改代码使其符合 YAML${NC}"
  echo -e "${YELLOW}   ❌ 直接修改 YAML 使其符合代码${NC}"
  echo -e "${YELLOW}   ❌ 猜测哪一边是"正确"的${NC}"
  echo ""
  exit 1
fi
