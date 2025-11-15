#!/bin/bash
# 运行命令模块

# 注意：此文件需要被 source，所以不设置 set -euo pipefail
# 颜色变量和工具函数应该由主文件定义

run_android() {
  local edition="${1:-lite}"
  local package_name="com.granoflow.$edition"
  
  echo -e "${GREEN}🚀 准备在 Android 手机上运行应用（Pixel 6, 6.4\", 1080 x 2400）[Edition: $edition]${NC}"
  
  # 准备设备（查找、启动、等待就绪）
  local device_id=$(prepare_android_device "Pixel 6" "Pixel 6")
  if [ -z "$device_id" ]; then
    echo -e "${RED}❌ 无法准备 Android 设备${NC}"
    return 1
  fi
  
  # 卸载已安装的应用
  uninstall_android_app "$device_id" "$package_name"
  
  # 运行应用
  echo -e "${BLUE}运行应用...${NC}"
  # 通过环境变量传递 Gradle 项目属性（直接在命令前设置，确保传递到子进程）
  ORG_GRADLE_PROJECT_appEdition="$edition" flutter run -d "$device_id" \
    --dart-define=GRANOFLOW_APP_EDITION="$edition" \
    --dart-define=GRANOFLOW_PACKAGE_NAME="$package_name" \
    --dart-define=appEdition="$edition"
}

run_tablet() {
  local edition="${1:-lite}"
  local package_name="com.granoflow.$edition"
  
  echo -e "${GREEN}🚀 准备在 Android 平板上运行应用（Pixel Tablet, 10.2\", 2560 x 1600）[Edition: $edition]${NC}"
  
  # 准备设备（查找、启动、等待就绪）
  local device_id=$(prepare_android_device "Pixel Tablet" "Pixel Tablet")
  if [ -z "$device_id" ]; then
    echo -e "${RED}❌ 无法准备 Android 设备${NC}"
    return 1
  fi
  
  # 卸载已安装的应用
  uninstall_android_app "$device_id" "$package_name"
  
  # 运行应用
  echo -e "${BLUE}运行应用...${NC}"
  # 通过环境变量传递 Gradle 项目属性（直接在命令前设置，确保传递到子进程）
  ORG_GRADLE_PROJECT_appEdition="$edition" flutter run -d "$device_id" \
    --dart-define=GRANOFLOW_APP_EDITION="$edition" \
    --dart-define=GRANOFLOW_PACKAGE_NAME="$package_name" \
    --dart-define=appEdition="$edition"
}

run_iphone() {
  local edition="${1:-lite}"
  local package_name="com.granoflow.$edition"
  
  echo -e "${GREEN}🚀 准备在 iPhone 上运行应用（iPhone 16 Pro, 6.3\", 1290 x 2796）[Edition: $edition]${NC}"
  
  # 准备设备（查找、启动、等待就绪）
  local device_udid=$(prepare_ios_device "iPhone 16 Pro" "iPhone")
  if [ -z "$device_udid" ]; then
    echo -e "${RED}❌ 无法准备 iOS 设备${NC}"
    return 1
  fi
  
  # 卸载已安装的应用
  uninstall_ios_app "$device_udid" "$package_name"
  
  # 运行应用
  echo -e "${BLUE}运行应用...${NC}"
  flutter run -d "$device_udid" \
    --dart-define=GRANOFLOW_APP_EDITION="$edition" \
    --dart-define=GRANOFLOW_PACKAGE_NAME="$package_name" \
    --dart-define=appEdition="$edition"
}

run_ipad() {
  local edition="${1:-lite}"
  local package_name="com.granoflow.$edition"
  
  echo -e "${GREEN}🚀 准备在 iPad 上运行应用（iPad Pro 11\", 11\", 2388 x 1668）[Edition: $edition]${NC}"
  
  # 准备设备（查找、启动、等待就绪）
  local device_udid=$(prepare_ios_device "iPad Pro 11-inch" "iPad")
  if [ -z "$device_udid" ]; then
    # 尝试另一个名称
    device_udid=$(prepare_ios_device "iPad Pro (11-inch)" "iPad")
  fi
  if [ -z "$device_udid" ]; then
    echo -e "${RED}❌ 无法准备 iOS 设备${NC}"
    return 1
  fi
  
  # 卸载已安装的应用
  uninstall_ios_app "$device_udid" "$package_name"
  
  # 运行应用
  echo -e "${BLUE}运行应用...${NC}"
  flutter run -d "$device_udid" \
    --dart-define=GRANOFLOW_APP_EDITION="$edition" \
    --dart-define=GRANOFLOW_PACKAGE_NAME="$package_name" \
    --dart-define=appEdition="$edition"
}

run_macos() {
  local edition="${1:-lite}"
  local package_name="com.granoflow.$edition"
  
  echo -e "${GREEN}🚀 准备在 macOS 上运行应用（桌面应用）[Edition: $edition]${NC}"
  
  # 检查 macOS 设备是否可用
  if ! flutter devices --machine 2>/dev/null | grep -q '"id"[[:space:]]*:[[:space:]]*"macos"'; then
    echo -e "${RED}❌ macOS 设备不可用${NC}"
    echo -e "${BLUE}提示: 请确保 Flutter 支持 macOS 平台${NC}"
    return 1
  fi
  
  echo -e "${BLUE}🧹 运行前执行完整清理流程（scripts/anz clean）...${NC}"
  clean_project
  
  echo -e "${GREEN}✅ 环境已清理完毕，macOS 设备可用${NC}"
  echo -e "${BLUE}运行应用...${NC}"
  flutter run -d macos \
    --dart-define=GRANOFLOW_APP_EDITION="$edition" \
    --dart-define=GRANOFLOW_PACKAGE_NAME="$package_name" \
    --dart-define=appEdition="$edition"
}

