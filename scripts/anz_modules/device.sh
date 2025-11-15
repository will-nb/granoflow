#!/bin/bash
# 设备管理模块

# 注意：此文件需要被 source，所以不设置 set -euo pipefail
# 颜色变量和工具函数应该由主文件定义

# ===== 设备查找函数 =====

# 查找 Android 虚拟器
find_android_emulator() {
  local pattern="$1"
  flutter emulators 2>&1 | grep -i "$pattern" | awk '{print $1}' | head -1
}

# 查找 iOS 模拟器
find_ios_simulator() {
  local pattern="$1"
  local result=$(xcrun simctl list devices available 2>&1 | grep -i "$pattern" | head -1)
  if [ -n "$result" ]; then
    echo "$result" | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/'
  fi
}

# ===== 设备控制函数 =====

# 等待设备就绪
wait_for_device() {
  local pattern="$1"  # 改为 pattern，可以是 "emulator|android" 或具体的 device_id
  local max_wait="${2:-60}"
  local waited=0
  local interval=2
  
  echo -e "${BLUE}等待设备就绪...${NC}"
  while [ $waited -lt $max_wait ]; do
    # 使用 grep -E 支持正则表达式
    if flutter devices 2>&1 | grep -qE "$pattern"; then
      # 额外等待 2 秒，确保设备完全就绪
      sleep 2
      echo -e "${GREEN}✅ 设备已就绪${NC}"
      return 0
    fi
    sleep $interval
    waited=$((waited + interval))
    echo -e "${YELLOW}  ⏳ 等待中... (${waited}/${max_wait}秒)${NC}"
  done
  
  echo -e "${RED}❌ 设备启动超时（${max_wait}秒）${NC}"
  return 1
}

# 停止 Android 虚拟器（保留但不再使用）
stop_android_emulator() {
  local device_id="$1"
  if [ -z "$device_id" ]; then
    return 0
  fi
  
  echo -e "${BLUE}关闭 Android 虚拟器...${NC}"
  # 尝试通过 adb 关闭
  if has_cmd adb; then
    # 尝试多种方式关闭虚拟器
    adb -s "$device_id" emu kill 2>/dev/null || true
    # 如果设备ID是 emulator-XXXX 格式，也尝试直接 kill
    if [[ "$device_id" == emulator-* ]]; then
      local port=$(echo "$device_id" | sed 's/emulator-//')
      killall -9 qemu-system-x86_64 2>/dev/null || true
    fi
  fi
  # 等待虚拟器关闭
  sleep 3
}

# 停止 iOS 模拟器（保留但不再使用）
stop_ios_simulator() {
  local device_udid="$1"
  if [ -z "$device_udid" ]; then
    # 如果没有指定 UDID，关闭所有运行中的模拟器
    echo -e "${BLUE}关闭所有运行中的 iOS 模拟器...${NC}"
    xcrun simctl shutdown all 2>/dev/null || true
  else
    echo -e "${BLUE}关闭 iOS 模拟器: $device_udid${NC}"
    xcrun simctl shutdown "$device_udid" 2>/dev/null || true
  fi
  sleep 2
}

# 启动 Android 虚拟器
launch_android_emulator() {
  local emulator_id="$1"
  if [ -z "$emulator_id" ]; then
    echo -e "${RED}❌ 虚拟器 ID 为空${NC}"
    return 1
  fi
  
  echo -e "${BLUE}启动 Android 虚拟器: $emulator_id${NC}"
  flutter emulators --launch "$emulator_id" >/dev/null 2>&1 &
}

# 启动 iOS 模拟器
launch_ios_simulator() {
  local device_udid="$1"
  if [ -z "$device_udid" ]; then
    echo -e "${RED}❌ 模拟器 UDID 为空${NC}"
    return 1
  fi
  
  echo -e "${BLUE}启动 iOS 模拟器: $device_udid${NC}"
  xcrun simctl boot "$device_udid" 2>/dev/null || true
  open -a Simulator 2>/dev/null || true
}

# ===== 设备状态查询函数 =====

# 获取运行中的 Android 设备 ID
get_running_android_device() {
  # flutter devices 输出格式: "设备名称 • device_id • platform • ..."
  # 需要提取 device_id（第二个字段，用 • 分隔）
  flutter devices 2>&1 | grep -E "emulator|android" | awk -F'•' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -1
}

# 获取运行中的 iOS 设备 ID
get_running_ios_device() {
  local pattern="$1"
  # flutter devices 输出格式: "设备名称 • device_id • platform • ..."
  # 需要提取 device_id（第二个字段，用 • 分隔）
  flutter devices 2>&1 | grep -i "$pattern" | awk -F'•' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -1
}

# ===== 设备创建函数 =====

# 创建 Android 虚拟器（使用 avdmanager）
create_android_emulator() {
  local avd_name="$1"
  local device_id="$2"  # 设备定义 ID，如 "pixel_6" 或 "pixel_tablet"
  local system_image="$3"  # 系统镜像，如 "system-images;android-33;google_apis;x86_64"
  
  local android_home="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
  local avdmanager="$android_home/cmdline-tools/latest/bin/avdmanager"
  
  if [ ! -f "$avdmanager" ]; then
    echo -e "${YELLOW}⚠️  avdmanager 未找到，尝试使用 flutter 命令创建...${NC}"
    if flutter emulators --create --name "$avd_name" >/dev/null 2>&1; then
      return 0
    fi
    return 1
  fi
  
  echo -e "${BLUE}使用 avdmanager 创建虚拟器: $avd_name${NC}"
  # 注意：avdmanager 创建虚拟器需要先下载系统镜像，这里只尝试创建
  # 如果系统镜像不存在，会失败，需要用户手动下载
  "$avdmanager" create avd -n "$avd_name" -k "$system_image" -d "$device_id" >/dev/null 2>&1
}

# ===== 应用管理函数 =====

# 卸载 Android 应用
uninstall_android_app() {
  local device_id="$1"
  local package_name="${2:-com.granoflow.app}"
  if [ -z "$device_id" ]; then
    echo -e "${YELLOW}⚠️  设备 ID 为空，跳过卸载${NC}"
    return 0
  fi
  
  echo -e "${BLUE}卸载已安装的应用（如果存在）...${NC}"
  
  # 先停止应用（如果正在运行）
  adb -s "$device_id" shell am force-stop "$package_name" 2>/dev/null || true
  
  # 卸载应用
  local result=$(adb -s "$device_id" uninstall "$package_name" 2>&1)
  if echo "$result" | grep -q "Success"; then
    echo -e "${GREEN}✅ 应用已卸载${NC}"
  elif echo "$result" | grep -q "not found"; then
    echo -e "${YELLOW}  ℹ️  应用未安装，无需卸载${NC}"
  else
    echo -e "${YELLOW}  ⚠️  卸载结果: $result${NC}"
  fi
}

# 授予 Android 应用通知权限（用于测试，避免弹出权限对话框）
grant_android_notification_permission() {
  local device_id="$1"
  local package_name="${2:-com.granoflow.app}"
  if [ -z "$device_id" ]; then
    echo -e "${YELLOW}⚠️  设备 ID 为空，跳过权限授予${NC}"
    return 0
  fi
  
  echo -e "${BLUE}授予通知权限（避免测试时弹出对话框）...${NC}"
  
  # 授予 Android 13+ 通知权限
  adb -s "$device_id" shell pm grant "$package_name" android.permission.POST_NOTIFICATIONS 2>/dev/null || {
    echo -e "${YELLOW}  ⚠️  权限授予失败（可能应用未安装或权限已授予）${NC}"
  }
  
  echo -e "${GREEN}✅ 权限授予完成${NC}"
}

# 卸载 iOS 应用
uninstall_ios_app() {
  local device_id="$1"
  local package_name="${2:-com.granoflow.app}"
  if [ -z "$device_id" ]; then
    # 如果没有指定设备 ID，使用 booted
    device_id="booted"
  fi
  
  echo -e "${BLUE}卸载已安装的应用（如果存在）...${NC}"
  
  # 先终止应用（如果正在运行）
  xcrun simctl terminate "$device_id" "$package_name" 2>/dev/null || true
  
  # 卸载应用
  local result=$(xcrun simctl uninstall "$device_id" "$package_name" 2>&1)
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 应用已卸载${NC}"
  else
    if echo "$result" | grep -qi "not found\|does not exist"; then
      echo -e "${YELLOW}  ℹ️  应用未安装，无需卸载${NC}"
    else
      echo -e "${YELLOW}  ⚠️  卸载结果: $result${NC}"
    fi
  fi
}

# 清空 macOS 应用数据
clean_macos_app_data() {
  echo -e "${BLUE}清空 macOS 应用数据...${NC}"
 
  # macOS - 检查新旧两个可能的路径
  NEW_DB_PATH="$HOME/Library/Containers/com.granoflow.app/Data/Library/Application Support"
  OLD_DB_PATH="$HOME/Library/Containers/com.example.granoflow/Data/Library/Application Support"
  NEW_DOC_DB_PATH="$HOME/Library/Containers/com.granoflow.app/Data/Documents/objectbox"
  OLD_DOC_DB_PATH="$HOME/Library/Containers/com.example.granoflow/Data/Documents/objectbox"
 
  DB_FOUND=false
 
  # 清理新路径
  if [ -d "$NEW_DB_PATH" ]; then
    echo -e "${YELLOW}  - 清理数据库: com.granoflow.app${NC}"
    rm -rf "$NEW_DB_PATH"/*
    DB_FOUND=true
  fi

  if [ -d "$NEW_DOC_DB_PATH" ]; then
    echo -e "${YELLOW}  - 清理数据库: $NEW_DOC_DB_PATH${NC}"
    rm -rf "$NEW_DOC_DB_PATH"
    DB_FOUND=true
  fi
 
  # 清理旧路径（如果存在）
  if [ -d "$OLD_DB_PATH" ]; then
    echo -e "${YELLOW}  - 清理旧数据库: com.example.granoflow${NC}"
    rm -rf "$OLD_DB_PATH"/*
    DB_FOUND=true
  fi

  if [ -d "$OLD_DOC_DB_PATH" ]; then
    echo -e "${YELLOW}  - 清理旧数据库: $OLD_DOC_DB_PATH${NC}"
    rm -rf "$OLD_DOC_DB_PATH"
    DB_FOUND=true
  fi

  # 清理 Drift 数据库文件
  # 新应用 ID 沙盒 Application Support
  if [ -f "$HOME/Library/Containers/com.granoflow.app/Data/Library/Application Support/granoflow.db" ]; then
    echo -e "${YELLOW}  - 删除 Drift 数据库文件: com.granoflow.app (Application Support)${NC}"
    rm -f "$HOME/Library/Containers/com.granoflow.app/Data/Library/Application Support/granoflow.db"
    DB_FOUND=true
  fi

  # 新应用 ID 沙盒 Documents
  if [ -f "$HOME/Library/Containers/com.granoflow.app/Data/Documents/granoflow.db" ]; then
    echo -e "${YELLOW}  - 删除 Drift 数据库文件: com.granoflow.app (Documents)${NC}"
    rm -f "$HOME/Library/Containers/com.granoflow.app/Data/Documents/granoflow.db"
    DB_FOUND=true
  fi

  # 旧应用 ID 沙盒 Application Support
  if [ -f "$HOME/Library/Containers/com.example.granoflow/Data/Library/Application Support/granoflow.db" ]; then
    echo -e "${YELLOW}  - 删除 Drift 数据库文件: com.example.granoflow (Application Support)${NC}"
    rm -f "$HOME/Library/Containers/com.example.granoflow/Data/Library/Application Support/granoflow.db"
    DB_FOUND=true
  fi

  # 旧应用 ID 沙盒 Documents
  if [ -f "$HOME/Library/Containers/com.example.granoflow/Data/Documents/granoflow.db" ]; then
    echo -e "${YELLOW}  - 删除 Drift 数据库文件: com.example.granoflow (Documents)${NC}"
    rm -f "$HOME/Library/Containers/com.example.granoflow/Data/Documents/granoflow.db"
    DB_FOUND=true
  fi

  # 使用 find 命令查找所有可能的 granoflow.db 文件（兜底方案）
  while IFS= read -r db_file; do
    if [ -f "$db_file" ]; then
      echo -e "${YELLOW}  - 删除找到的数据库文件: $db_file${NC}"
      rm -f "$db_file"
      DB_FOUND=true
    fi
  done < <(find "$HOME/Library" -name "granoflow.db" -type f 2>/dev/null | grep -E "(com\.granoflow\.app|com\.example\.granoflow)" || true)
 
  if [ "$DB_FOUND" = true ]; then
    echo -e "${GREEN}✅ 应用数据已清空，下次启动将重新导入种子数据${NC}"
  else
    echo -e "${YELLOW}  ⚠️  未找到应用数据（可能尚未运行过应用）${NC}"
  fi
}

# ===== 设备准备函数 =====

# 准备 Android 设备（查找、启动、等待就绪）
# 参数：
#   $1: 虚拟器名称模式（如 "Pixel 6" 或 "Pixel_6"）
#   $2: 虚拟器 ID 模式（可选，用于查找）
# 返回：设备 ID（如果成功），空字符串（如果失败）
# 注意：所有信息输出都重定向到 stderr，只有设备 ID 输出到 stdout
prepare_android_device() {
  local emulator_name="$1"
  local emulator_id_pattern="${2:-$emulator_name}"
  
  # 查找虚拟器
  local emulator_id=$(find_android_emulator "$emulator_id_pattern")
  if [ -z "$emulator_id" ]; then
    # 尝试另一个模式
    if [[ "$emulator_id_pattern" == *" "* ]]; then
      emulator_id=$(find_android_emulator "${emulator_id_pattern// /_}")
    elif [[ "$emulator_id_pattern" == *"_"* ]]; then
      emulator_id=$(find_android_emulator "${emulator_id_pattern//_/ }")
    fi
  fi
  
  # 如果找不到，尝试创建
  if [ -z "$emulator_id" ]; then
    echo -e "${YELLOW}⚠️  未找到 $emulator_name 虚拟器，尝试创建...${NC}" >&2
    if flutter emulators --create --name "${emulator_id_pattern// /_}" >/dev/null 2>&1; then
      sleep 2
      emulator_id=$(find_android_emulator "$emulator_id_pattern")
    fi
    if [ -z "$emulator_id" ]; then
      echo -e "${RED}❌ 无法自动创建 $emulator_name 虚拟器${NC}" >&2
      echo -e "${BLUE}提示: 请使用 Android Studio 创建虚拟器${NC}" >&2
      return 1
    fi
  fi
  
  echo -e "${GREEN}✅ 找到虚拟器: $emulator_id${NC}" >&2
  
  # 检查虚拟器是否已在运行
  local device_id=$(get_running_android_device)
  if [ -n "$device_id" ]; then
    echo -e "${GREEN}✅ 虚拟器已在运行: $device_id${NC}" >&2
    echo "$device_id"
    return 0
  fi
  
  # 启动虚拟器
  launch_android_emulator "$emulator_id"
  
  # 等待设备就绪
  if ! wait_for_device "emulator|android" 90; then
    return 1
  fi
  
  # 获取设备 ID，最多重试 5 次
  device_id=""
  local retries=0
  while [ -z "$device_id" ] && [ $retries -lt 5 ]; do
    sleep 2
    device_id=$(get_running_android_device)
    retries=$((retries + 1))
    if [ -z "$device_id" ]; then
      echo -e "${YELLOW}  ⏳ 等待设备 ID... (${retries}/5)${NC}" >&2
    fi
  done
  
  if [ -z "$device_id" ]; then
    echo -e "${RED}❌ 无法获取设备 ID${NC}" >&2
    return 1
  fi
  
  echo -e "${GREEN}✅ 设备已就绪: $device_id${NC}" >&2
  echo "$device_id"
  return 0
}

# 准备 iOS 设备（查找、启动、等待就绪）
# 参数：
#   $1: 设备名称模式（如 "iPhone 16 Pro"）
#   $2: 设备类型模式（可选，如 "iPhone" 或 "iPad"）
# 返回：设备 UDID（如果成功），空字符串（如果失败）
# 注意：所有信息输出都重定向到 stderr，只有设备 UDID 输出到 stdout
prepare_ios_device() {
  local device_name="$1"
  local device_pattern="${2:-$device_name}"
  
  # 查找模拟器
  local device_udid=$(find_ios_simulator "$device_name")
  
  # 如果找不到，尝试创建
  if [ -z "$device_udid" ]; then
    echo -e "${YELLOW}⚠️  未找到 $device_name 模拟器，尝试创建...${NC}" >&2
    # 获取最新的 iOS 运行时
    local runtime=$(xcrun simctl list runtimes available 2>&1 | grep -i "iOS" | tail -1 | awk '{print $NF}' | sed 's/[()]//g')
    if [ -z "$runtime" ]; then
      echo -e "${RED}❌ 无法找到 iOS 运行时，请先安装 Xcode${NC}" >&2
      return 1
    fi
    device_udid=$(xcrun simctl create "$device_name" "$device_name" "$runtime" 2>&1 | tail -1)
    if [ -z "$device_udid" ] || [[ "$device_udid" == *"Error"* ]]; then
      echo -e "${RED}❌ 无法创建 $device_name 模拟器${NC}" >&2
      echo -e "${BLUE}提示: 请使用 Xcode 创建模拟器${NC}" >&2
      return 1
    fi
  fi
  
  echo -e "${GREEN}✅ 找到模拟器: $device_udid${NC}" >&2
  
  # 检查模拟器是否已在运行
  local running_udid=$(get_running_ios_device "$device_pattern")
  if [ -n "$running_udid" ] && [ "$running_udid" == "$device_udid" ]; then
    echo -e "${GREEN}✅ 模拟器已在运行: $device_udid${NC}" >&2
    echo "$device_udid"
    return 0
  fi
  
  # 启动模拟器
  launch_ios_simulator "$device_udid"
  
  # 等待设备就绪
  if ! wait_for_device "$device_udid" 60; then
    return 1
  fi
  
  echo -e "${GREEN}✅ 设备已就绪: $device_udid${NC}" >&2
  echo "$device_udid"
  return 0
}

