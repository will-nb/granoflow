#!/bin/bash

# YAML 一致性测试运行脚本
# 
# 这个脚本用于运行所有基于 YAML 的测试，确保代码与设计文档的一致性。
# 
# 使用方法：
#   ./scripts/run_yaml_tests.sh [选项]
# 
# 选项：
#   --all         运行所有测试
#   --navigation  只运行导航组件测试
#   --widgets     只运行组件测试
#   --documentation 只运行 YAML 完整性测试
#   --integration 只运行集成一致性测试
#   --verbose     显示详细输出
#   --help        显示帮助信息

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认选项
RUN_ALL=false
RUN_NAVIGATION=false
RUN_WIDGETS=false
RUN_DOCUMENTATION=false
RUN_INTEGRATION=false
VERBOSE=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --all)
      RUN_ALL=true
      shift
      ;;
    --navigation)
      RUN_NAVIGATION=true
      shift
      ;;
    --widgets)
      RUN_WIDGETS=true
      shift
      ;;
    --documentation)
      RUN_DOCUMENTATION=true
      shift
      ;;
    --integration)
      RUN_INTEGRATION=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      echo "YAML 一致性测试运行脚本"
      echo ""
      echo "使用方法："
      echo "  $0 [选项]"
      echo ""
      echo "选项："
      echo "  --all         运行所有测试"
      echo "  --navigation  只运行导航组件测试"
      echo "  --widgets     只运行组件测试"
      echo "  --documentation 只运行 YAML 完整性测试"
      echo "  --integration 只运行集成一致性测试"
      echo "  --verbose     显示详细输出"
      echo "  --help        显示帮助信息"
      echo ""
      echo "示例："
      echo "  $0 --all"
      echo "  $0 --navigation --verbose"
      echo "  $0 --widgets --documentation"
      exit 0
      ;;
    *)
      echo "未知选项: $1"
      echo "使用 --help 查看帮助信息"
      exit 1
      ;;
  esac
done

# 如果没有指定任何选项，默认运行所有测试
if [[ "$RUN_ALL" == false && "$RUN_NAVIGATION" == false && "$RUN_WIDGETS" == false && "$RUN_DOCUMENTATION" == false && "$RUN_INTEGRATION" == false ]]; then
  RUN_ALL=true
fi

# 打印标题
echo -e "${BLUE}🚀 开始运行 YAML 一致性测试...${NC}"
echo ""

# 检查 Flutter 环境
if ! command -v flutter &> /dev/null; then
  echo -e "${RED}❌ Flutter 未安装或不在 PATH 中${NC}"
  exit 1
fi

# 检查项目目录
if [[ ! -f "pubspec.yaml" ]]; then
  echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
  exit 1
fi

# 检查必需的 YAML 文件
echo -e "${YELLOW}📋 检查必需的 YAML 文件...${NC}"
REQUIRED_YAML_FILES=(
  "documents/architecture/widgets/navigation_destinations.yaml"
  "documents/architecture/widgets/drawer_menu.yaml"
  "documents/architecture/widgets/responsive_navigation.yaml"
  "documents/architecture/widgets/main_drawer.yaml"
  "documents/architecture/widgets/page_app_bar.yaml"
  "documents/architecture/widgets/create_task_dialog.yaml"
  "documents/architecture/widgets/widgets.yaml"
)

MISSING_FILES=()
for file in "${REQUIRED_YAML_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    MISSING_FILES+=("$file")
  fi
done

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
  echo -e "${RED}❌ 以下必需的 YAML 文件不存在：${NC}"
  for file in "${MISSING_FILES[@]}"; do
    echo "  - $file"
  done
  exit 1
fi

echo -e "${GREEN}✅ 所有必需的 YAML 文件存在${NC}"
echo ""

# 运行测试的函数
run_test() {
  local test_file="$1"
  local test_name="$2"
  
  if [[ "$VERBOSE" == true ]]; then
    echo -e "${BLUE}🧪 运行 $test_name...${NC}"
  fi
  
  if flutter test "$test_file" --reporter=compact; then
    echo -e "${GREEN}✅ $test_name 通过${NC}"
    return 0
  else
    echo -e "${RED}❌ $test_name 失败${NC}"
    return 1
  fi
}

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 运行导航组件测试
if [[ "$RUN_ALL" == true || "$RUN_NAVIGATION" == true ]]; then
  echo -e "${YELLOW}📱 运行导航组件一致性测试...${NC}"
  
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  if run_test "test/presentation/navigation/yaml_based_consistency_test.dart" "导航组件一致性测试"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
  
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  if run_test "test/presentation/navigation/integration_consistency_test.dart" "集成一致性测试"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
  
  echo ""
fi

# 运行组件测试
if [[ "$RUN_ALL" == true || "$RUN_WIDGETS" == true ]]; then
  echo -e "${YELLOW}🧩 运行组件一致性测试...${NC}"
  
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  if run_test "test/presentation/widgets/yaml_based_widget_test.dart" "组件一致性测试"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
  
  echo ""
fi

# 运行 YAML 完整性测试
if [[ "$RUN_ALL" == true || "$RUN_DOCUMENTATION" == true ]]; then
  echo -e "${YELLOW}📋 运行 YAML 完整性测试...${NC}"
  
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  if run_test "test/documentation/yaml_integrity_test.dart" "YAML 完整性测试"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
  
  echo ""
fi

# 运行集成一致性测试
if [[ "$RUN_ALL" == true || "$RUN_INTEGRATION" == true ]]; then
  echo -e "${YELLOW}🔗 运行集成一致性测试...${NC}"
  
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  if run_test "test/presentation/navigation/integration_consistency_test.dart" "集成一致性测试"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
  
  echo ""
fi

# 打印测试结果
echo -e "${BLUE}📊 测试结果汇总：${NC}"
echo "  总测试数: $TOTAL_TESTS"
echo -e "  通过: ${GREEN}$PASSED_TESTS${NC}"
echo -e "  失败: ${RED}$FAILED_TESTS${NC}"

if [[ $FAILED_TESTS -eq 0 ]]; then
  echo -e "${GREEN}🎉 所有 YAML 一致性测试通过！${NC}"
  exit 0
else
  echo -e "${RED}💥 有 $FAILED_TESTS 个测试失败${NC}"
  exit 1
fi
