#!/bin/bash
# 构建相关命令模块

# 注意：此文件需要被 source，所以不设置 set -euo pipefail
# 颜色变量和工具函数应该由主文件定义

clean_project() {
  echo -e "${GREEN}🧹 开始清理项目...${NC}"
  
  # 1. 清空数据库
  echo -e "${BLUE}1. 清空 Isar 数据库...${NC}"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - 检查新旧两个可能的路径
    NEW_DB_PATH="$HOME/Library/Containers/com.granoflow.app/Data/Library/Application Support"
    OLD_DB_PATH="$HOME/Library/Containers/com.example.granoflow/Data/Library/Application Support"
    
    DB_FOUND=false
    
    # 清理新路径
    if [ -d "$NEW_DB_PATH" ]; then
      echo -e "${YELLOW}  - 清理数据库: com.granoflow.app${NC}"
      rm -rf "$NEW_DB_PATH"/*
      DB_FOUND=true
    fi
    
    # 清理旧路径（如果存在）
    if [ -d "$OLD_DB_PATH" ]; then
      echo -e "${YELLOW}  - 清理旧数据库: com.example.granoflow${NC}"
      rm -rf "$OLD_DB_PATH"/*
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
      echo -e "${YELLOW}  - 清理数据库: $DB_PATH${NC}"
      rm -rf "$DB_PATH"/*
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
  
  # 6. 生成 Isar 代码
  echo -e "${BLUE}6. 生成 Isar 代码...${NC}"
  run_with_timeout 180 flutter pub run build_runner build --delete-conflicting-outputs
  echo -e "${GREEN}✅ Isar 代码生成完成${NC}"
  
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
