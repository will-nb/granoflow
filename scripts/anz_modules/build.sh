#!/bin/bash
# 构建相关命令模块

# 注意：此文件需要被 source，所以不设置 set -euo pipefail
# 颜色变量和工具函数应该由主文件定义

# 通用的测试函数：清理环境并运行测试或应用
# 参数：
#   $1: 设备 ID (如 macos, ios, android, linux, windows, web, tablet, iphone, ipad)
#   $2: 设备名称模式（可选，用于 Android/iOS 设备查找，如 "Pixel 6", "iPhone 16 Pro"）
#   $3: 设备类型模式（可选，用于 iOS 设备查找，如 "iPhone", "iPad"）
#   $@: 如果提供参数，传递给 flutter test；如果没有参数，执行 flutter run
run_tests_with_clean() {
  local device="$1"
  local device_name="${2:-}"
  local device_type="${3:-}"
  # 移除设备参数（根据实际参数数量决定 shift 次数）
  if [ $# -ge 3 ]; then
    shift 3
  elif [ $# -ge 2 ]; then
    shift 2
  else
    shift
  fi
  
  # 先执行 clean（和 clean 命令一样的清理内容）
  echo -e "${BLUE}🧹 执行清理...${NC}"
  clean_project
  
  # 如果没有提供参数，执行 flutter run
  if [ $# -eq 0 ]; then
    echo -e "${BLUE}🚀 运行应用 (设备: $device)...${NC}"
    echo -e "${YELLOW}提示: 如需运行测试，请提供测试文件路径作为参数${NC}"
    echo -e "${YELLOW}示例: scripts/anz test:$device integration_test/seed_import_test.dart${NC}"
    
    # 对于 Android 和 iOS，需要查找实际的设备 ID
    local actual_device="$device"
    if [ "$device" = "android" ] || [ "$device" = "tablet" ]; then
      # 查找运行中的 Android 设备
      actual_device=$(get_running_android_device)
      if [ -z "$actual_device" ]; then
        echo -e "${YELLOW}⚠️  未找到运行中的 Android 设备，尝试启动模拟器...${NC}"
        # 根据设备类型选择不同的设备名称
        if [ "$device" = "tablet" ]; then
          local emulator_name="${device_name:-Pixel Tablet}"
          actual_device=$(prepare_android_device "$emulator_name" "$emulator_name")
        else
          local emulator_name="${device_name:-Pixel 6}"
          actual_device=$(prepare_android_device "$emulator_name" "$emulator_name")
        fi
        if [ -z "$actual_device" ]; then
          echo -e "${RED}❌ 无法准备 Android 设备${NC}"
          echo -e "${BLUE}提示: 请使用 'scripts/anz run:android' 或 'scripts/anz run:tablet' 来运行 Android 应用${NC}"
          echo -e "${BLUE}或者手动启动 Android 模拟器后重试${NC}"
          return 1
        fi
      fi
      echo -e "${GREEN}✅ 使用 Android 设备: $actual_device${NC}"
    elif [ "$device" = "ios" ] || [ "$device" = "iphone" ] || [ "$device" = "ipad" ]; then
      # 查找运行中的 iOS 设备
      local pattern="${device_type:-iPhone}"
      if [ "$device" = "ipad" ]; then
        pattern="iPad"
      fi
      actual_device=$(get_running_ios_device "$pattern")
      if [ -z "$actual_device" ]; then
        echo -e "${YELLOW}⚠️  未找到运行中的 iOS 设备，尝试启动模拟器...${NC}"
        # 根据设备类型选择不同的设备名称
        if [ "$device" = "ipad" ]; then
          local ios_device_name="${device_name:-iPad Pro 11-inch}"
          actual_device=$(prepare_ios_device "$ios_device_name" "iPad")
          if [ -z "$actual_device" ]; then
            # 尝试另一个名称
            actual_device=$(prepare_ios_device "iPad Pro (11-inch)" "iPad")
          fi
        else
          local ios_device_name="${device_name:-iPhone 16 Pro}"
          actual_device=$(prepare_ios_device "$ios_device_name" "iPhone")
        fi
        if [ -z "$actual_device" ]; then
          echo -e "${RED}❌ 无法准备 iOS 设备${NC}"
          echo -e "${BLUE}提示: 请使用 'scripts/anz run:iphone' 或 'scripts/anz run:ipad' 来运行 iOS 应用${NC}"
          echo -e "${BLUE}或者手动启动 iOS 模拟器后重试${NC}"
          return 1
        fi
      fi
      echo -e "${GREEN}✅ 使用 iOS 设备: $actual_device${NC}"
    fi
    
    flutter run -d "$actual_device"
  else
    # 如果提供了参数，执行 flutter test
    echo -e "${BLUE}🧪 运行测试 (设备: $device)...${NC}"
    
    # 对于 Android 和 iOS，需要查找实际的设备 ID
    local actual_device="$device"
    if [ "$device" = "android" ] || [ "$device" = "tablet" ]; then
      # 查找运行中的 Android 设备
      actual_device=$(get_running_android_device)
      if [ -z "$actual_device" ]; then
        echo -e "${YELLOW}⚠️  未找到运行中的 Android 设备，尝试启动模拟器...${NC}"
        # 根据设备类型选择不同的设备名称
        if [ "$device" = "tablet" ]; then
          local emulator_name="${device_name:-Pixel Tablet}"
          actual_device=$(prepare_android_device "$emulator_name" "$emulator_name")
        else
          local emulator_name="${device_name:-Pixel 6}"
          actual_device=$(prepare_android_device "$emulator_name" "$emulator_name")
        fi
        if [ -z "$actual_device" ]; then
          echo -e "${RED}❌ 无法准备 Android 设备${NC}"
          echo -e "${BLUE}提示: 请手动启动 Android 模拟器后重试${NC}"
          return 1
        fi
      fi
      echo -e "${GREEN}✅ 使用 Android 设备: $actual_device${NC}"
    elif [ "$device" = "ios" ] || [ "$device" = "iphone" ] || [ "$device" = "ipad" ]; then
      # 查找运行中的 iOS 设备
      local pattern="${device_type:-iPhone}"
      if [ "$device" = "ipad" ]; then
        pattern="iPad"
      fi
      actual_device=$(get_running_ios_device "$pattern")
      if [ -z "$actual_device" ]; then
        echo -e "${YELLOW}⚠️  未找到运行中的 iOS 设备，尝试启动模拟器...${NC}"
        # 根据设备类型选择不同的设备名称
        if [ "$device" = "ipad" ]; then
          local ios_device_name="${device_name:-iPad Pro 11-inch}"
          actual_device=$(prepare_ios_device "$ios_device_name" "iPad")
          if [ -z "$actual_device" ]; then
            # 尝试另一个名称
            actual_device=$(prepare_ios_device "iPad Pro (11-inch)" "iPad")
          fi
        else
          local ios_device_name="${device_name:-iPhone 16 Pro}"
          actual_device=$(prepare_ios_device "$ios_device_name" "iPhone")
        fi
        if [ -z "$actual_device" ]; then
          echo -e "${RED}❌ 无法准备 iOS 设备${NC}"
          echo -e "${BLUE}提示: 请手动启动 iOS 模拟器后重试${NC}"
          return 1
        fi
      fi
      echo -e "${GREEN}✅ 使用 iOS 设备: $actual_device${NC}"
    fi
    
    # 传递所有参数给 flutter test
    # 注意：使用 run_with_timeout 包装，避免测试超时
    run_with_timeout 600 flutter test -d "$actual_device" "$@" || {
      echo -e "${RED}❌ 测试失败${NC}"
      return 1
    }
    echo -e "${GREEN}✅ 所有测试通过！${NC}"
  fi
}

clean_project() {
  echo -e "${GREEN}🧹 开始清理项目...${NC}"
  
  # 1. 清空数据库
  echo -e "${BLUE}1. 清空 ObjectBox 数据库...${NC}"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - ObjectBox 使用默认目录时，数据库存储在 ~/Library/Application Support/<bundle-id>
    # 也可能在沙盒容器中（如果应用是沙盒化的）
    DB_FOUND=false
    
    # 路径1: 默认 Application Support 目录（openStore() 默认使用）
    DEFAULT_DB_PATH="$HOME/Library/Application Support/com.granoflow.app"
    if [ -d "$DEFAULT_DB_PATH" ]; then
      echo -e "${YELLOW}  - 删除数据库目录: $DEFAULT_DB_PATH${NC}"
      rm -rf "$DEFAULT_DB_PATH"
      DB_FOUND=true
    fi
    
    # 路径2: 沙盒容器路径（如果应用是沙盒化的）
    SANDBOX_DB_PATH="$HOME/Library/Containers/com.granoflow.app/Data/Library/Application Support"
    if [ -d "$SANDBOX_DB_PATH" ]; then
      echo -e "${YELLOW}  - 删除沙盒数据库目录: $SANDBOX_DB_PATH${NC}"
      rm -rf "$SANDBOX_DB_PATH"
      DB_FOUND=true
    fi

    # 路径3: 沙盒 Documents/objectbox
    SANDBOX_DOC_DB_PATH="$HOME/Library/Containers/com.granoflow.app/Data/Documents/objectbox"
    if [ -d "$SANDBOX_DOC_DB_PATH" ]; then
      echo -e "${YELLOW}  - 删除沙盒文档数据库目录: $SANDBOX_DOC_DB_PATH${NC}"
      rm -rf "$SANDBOX_DOC_DB_PATH"
      DB_FOUND=true
    fi
    
    # 路径4: 旧的应用 ID（如果存在）
    OLD_DB_PATH="$HOME/Library/Application Support/com.example.granoflow"
    if [ -d "$OLD_DB_PATH" ]; then
      echo -e "${YELLOW}  - 删除旧数据库目录: $OLD_DB_PATH${NC}"
      rm -rf "$OLD_DB_PATH"
      DB_FOUND=true
    fi
    
    # 路径5: 旧的沙盒路径
    OLD_SANDBOX_DB_PATH="$HOME/Library/Containers/com.example.granoflow/Data/Library/Application Support"
    if [ -d "$OLD_SANDBOX_DB_PATH" ]; then
      echo -e "${YELLOW}  - 删除旧沙盒数据库目录: $OLD_SANDBOX_DB_PATH${NC}"
      rm -rf "$OLD_SANDBOX_DB_PATH"
      DB_FOUND=true
    fi

    # 路径6: 旧应用沙盒 Documents/objectbox
    OLD_SANDBOX_DOC_DB_PATH="$HOME/Library/Containers/com.example.granoflow/Data/Documents/objectbox"
    if [ -d "$OLD_SANDBOX_DOC_DB_PATH" ]; then
      echo -e "${YELLOW}  - 删除旧沙盒文档数据库目录: $OLD_SANDBOX_DOC_DB_PATH${NC}"
      rm -rf "$OLD_SANDBOX_DOC_DB_PATH"
      DB_FOUND=true
    fi

    # 路径7: 默认 Documents/objectbox 目录（objectbox 默认 fallback）
    DOCUMENTS_DB_PATH="$HOME/Documents/objectbox"
    if [ -d "$DOCUMENTS_DB_PATH" ]; then
      echo -e "${YELLOW}  - 删除默认 ObjectBox 目录: $DOCUMENTS_DB_PATH${NC}"
      rm -rf "$DOCUMENTS_DB_PATH"
      DB_FOUND=true
    fi
    
    if [ "$DB_FOUND" = true ]; then
      echo -e "${GREEN}✅ 数据库已清空，下次启动将重新导入种子数据${NC}"
    else
      echo -e "${YELLOW}  ⚠️  未找到数据库（可能尚未运行过应用）${NC}"
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    DB_PATH="$HOME/.local/share/granoflow"
    if [ -d "$DB_PATH" ]; then
      echo -e "${YELLOW}  - 删除数据库目录: $DB_PATH${NC}"
      rm -rf "$DB_PATH"
      echo -e "${GREEN}✅ 数据库已清空${NC}"
    else
      echo -e "${YELLOW}  ⚠️  未找到数据库（可能尚未运行过应用）${NC}"
    fi
  fi
  
  # 2. flutter clean
  echo -e "${BLUE}2. 执行 flutter clean...${NC}"
  run_with_timeout 60 flutter clean
  echo -e "${GREEN}✅ flutter clean 完成${NC}"
  
  # 3. 删除构建相关的文件夹（保留配置文件）
  echo -e "${BLUE}3. 删除构建相关文件夹...${NC}"
  
  # 删除 build 文件夹
  if [ -d "build" ]; then
    echo -e "${YELLOW}  - 删除 build/ 文件夹${NC}"
    rm -rf build
  fi
  
  # 删除 .dart_tool 文件夹
  if [ -d ".dart_tool" ]; then
    echo -e "${YELLOW}  - 删除 .dart_tool/ 文件夹${NC}"
    rm -rf .dart_tool
  fi
  
  # 删除各平台的构建文件夹（保留配置文件）
  for platform in macos android ios linux web windows; do
    if [ -d "$platform" ]; then
      # 只删除构建相关的子文件夹，保留配置文件
      if [ -d "$platform/build" ]; then
        echo -e "${YELLOW}  - 删除 $platform/build/ 文件夹${NC}"
        rm -rf "$platform/build"
      fi
      if [ -d "$platform/.dart_tool" ]; then
        echo -e "${YELLOW}  - 删除 $platform/.dart_tool/ 文件夹${NC}"
        rm -rf "$platform/.dart_tool"
      fi
    fi
  done
  
  # 删除 Android Gradle 缓存（解决代码不更新问题）
  if [ -d "android/.gradle" ]; then
    echo -e "${YELLOW}  - 删除 android/.gradle/ 文件夹（Gradle 构建缓存）${NC}"
    rm -rf android/.gradle
  fi
  
  if [ -d "android/app/.gradle" ]; then
    echo -e "${YELLOW}  - 删除 android/app/.gradle/ 文件夹（App 模块缓存）${NC}"
    rm -rf android/app/.gradle
  fi
  
  # 可选：清理 Android IDE 缓存
  if [ -d "android/.idea" ]; then
    echo -e "${YELLOW}  - 删除 android/.idea/ 文件夹（Android Studio 缓存）${NC}"
    rm -rf android/.idea
  fi
  
  echo -e "${GREEN}✅ 构建文件夹清理完成${NC}"
  
  # 4. flutter gen-l10n
  echo -e "${BLUE}4. 生成本地化文件...${NC}"
  run_with_timeout 60 flutter gen-l10n
  echo -e "${GREEN}✅ 本地化文件生成完成${NC}"
  
  # 5. flutter pub get
  echo -e "${BLUE}5. 获取依赖包...${NC}"
  run_with_timeout 120 flutter pub get
  echo -e "${GREEN}✅ 依赖包获取完成${NC}"
  
  # 6. 生成 ObjectBox 代码
  echo -e "${BLUE}6. 生成 ObjectBox 代码...${NC}"
  run_with_timeout 180 dart run build_runner build --delete-conflicting-outputs
  echo -e "${GREEN}✅ ObjectBox 代码生成完成${NC}"
  
  # 7. flutter analyze
  echo -e "${BLUE}7. 执行代码分析...${NC}"
  run_with_timeout 120 flutter analyze
  echo -e "${GREEN}✅ 代码分析完成${NC}"
  
  echo -e "${GREEN}🎉 项目清理和重建完成！${NC}"
}

build_aab() {
  echo -e "${GREEN}📦 开始构建 Android App Bundle (AAB)...${NC}"
  
  # 检查是否有密钥文件
  if [ ! -f "android/app/keystore.properties" ]; then
    echo -e "${YELLOW}⚠ 未找到密钥文件 android/app/keystore.properties${NC}"
    echo -e "${BLUE}ℹ 将使用调试签名构建 AAB${NC}"
  fi
  
  # 构建 AAB
  echo -e "${BLUE}执行 flutter build appbundle --release...${NC}"
  run_with_timeout 300 flutter build appbundle --release
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ AAB 构建成功！${NC}"
    echo -e "${BLUE}📁 AAB 文件位置: build/app/outputs/bundle/release/app-release.aab${NC}"
    
    # 显示文件大小
    local aab_file="build/app/outputs/bundle/release/app-release.aab"
    if [ -f "$aab_file" ]; then
      local file_size=$(ls -lh "$aab_file" | awk '{print $5}')
      echo -e "${BLUE}📊 文件大小: $file_size${NC}"
    fi
  else
    echo -e "${RED}❌ AAB 构建失败${NC}"
    exit 1
  fi
}

generate_icons_all() {
  echo -e "${GREEN}🎨 开始生成所有平台图标...${NC}"
  
  if ! has_cmd python3; then
    echo -e "${RED}❌ 需要 Python 3 环境${NC}"
    return 1
  fi
  
  if [ ! -f "assets/logo/granostack-logo-transparent.png" ]; then
    echo -e "${RED}❌ 源文件不存在: assets/logo/granostack-logo-transparent.png${NC}"
    return 1
  fi
  
  echo -e "${BLUE}执行: python3 scripts/anz_modules/icons/generate.py${NC}"
  run_with_timeout 120 python3 scripts/anz_modules/icons/generate.py
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 所有平台图标生成成功！${NC}"
  else
    echo -e "${RED}❌ 图标生成失败${NC}"
    return 1
  fi
}

run_yaml_tests_all() {
  if has_help "$@"; then
    show_yaml_test_help
    return 0
  fi

  local timeout_seconds=600
  echo -e "${BLUE}运行 YAML 一致性测试脚本...${NC}"
  run_with_timeout "$timeout_seconds" bash "$ROOT_DIR/scripts/devtools/run_yaml_tests.sh" "$@"
}

install_hooks() {
  if has_help "$@"; then
    show_hooks_install_help
    return 0
  fi

  echo -e "${BLUE}配置 Git hooks...${NC}"
  bash "$ROOT_DIR/scripts/devtools/setup_hooks.sh" "$@"
}
