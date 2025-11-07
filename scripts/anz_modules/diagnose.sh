#!/bin/bash
# 诊断脚本模块
# 用于检查16KB页面大小兼容性问题

# 彩色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查命令是否存在
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# 提取JSON部分的辅助函数
extract_json() {
  local file="$1"
  if [ -f "$file" ] && [ -s "$file" ]; then
    # 文件已经包含完整的JSON，直接使用
    # 但需要确保是有效的JSON对象
    local json_content
    json_content=$(cat "$file" 2>/dev/null)
    if echo "$json_content" | grep -q "^{"; then
      echo "$json_content"
    else
      echo "{}"
    fi
  else
    echo "{}"
  fi
}

# 检查Flutter版本和引擎版本
check_flutter_version() {
  echo -e "${BLUE}检查 Flutter 版本和引擎...${NC}"
  
  local flutter_version_output
  flutter_version_output=$(flutter --version 2>&1)
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 无法获取 Flutter 版本${NC}"
    return 1
  fi
  
  # 提取Flutter版本
  local flutter_version
  flutter_version=$(echo "$flutter_version_output" | grep -E "^Flutter" | head -1 | awk '{print $2}')
  
  # 提取引擎版本（hash或revision）
  local engine_version
  engine_line=$(echo "$flutter_version_output" | grep -E "Engine" | head -1)
  # 尝试提取revision（在括号中）
  engine_version=$(echo "$engine_line" | grep -oE "revision [0-9a-f]+" | awk '{print $2}' || echo "")
  # 如果没有revision，尝试提取hash
  if [ -z "$engine_version" ]; then
    engine_version=$(echo "$engine_line" | grep -oE "hash [0-9a-f]+" | awk '{print $2}' | head -c 12 || echo "unknown")
  fi
  
  # 获取Flutter SDK路径
  local flutter_root
  # 尝试从flutter命令路径获取
  local flutter_cmd
  flutter_cmd=$(which flutter 2>/dev/null || command -v flutter 2>/dev/null)
  if [ -n "$flutter_cmd" ] && [ -L "$flutter_cmd" ]; then
    # 如果是符号链接，解析真实路径
    flutter_cmd=$(readlink -f "$flutter_cmd" 2>/dev/null || readlink "$flutter_cmd" 2>/dev/null || echo "$flutter_cmd")
  fi
  if [ -n "$flutter_cmd" ]; then
    flutter_root=$(dirname "$flutter_cmd")
    flutter_root=$(dirname "$flutter_root")
  fi
  
  # 如果还是无法获取，尝试从flutter --version输出中获取
  if [ -z "$flutter_root" ] || [ ! -d "$flutter_root" ]; then
    local version_path
    version_path=$(echo "$flutter_version_output" | grep -E "at " | head -1 | sed 's/.*at //' | sed 's/ •.*//')
    if [ -n "$version_path" ] && [ -d "$version_path" ]; then
      flutter_root="$version_path"
    fi
  fi
  
  echo "  Flutter SDK 版本: $flutter_version"
  echo "  Flutter 引擎版本: $engine_version"
  echo "  Flutter SDK 路径: $flutter_root"
  
  # 检查引擎缓存
  local engine_cache_dir="$flutter_root/bin/cache/artifacts/engine"
  if [ -d "$engine_cache_dir" ]; then
    echo "  引擎缓存目录: $engine_cache_dir"
    
    # 检查Android引擎文件
    local android_engines
    android_engines=$(find "$engine_cache_dir" -name "libflutter.so" 2>/dev/null | grep -E "android" || true)
    
    if [ -n "$android_engines" ]; then
      echo "  找到的 Android 引擎文件:"
      while IFS= read -r engine_file; do
        if [ -f "$engine_file" ]; then
          local file_size
          file_size=$(stat -f%z "$engine_file" 2>/dev/null || stat -c%s "$engine_file" 2>/dev/null)
          local mod_time
          mod_time=$(stat -f%Sm "$engine_file" 2>/dev/null || stat -c%y "$engine_file" 2>/dev/null)
          echo "    - $engine_file (大小: $file_size 字节, 修改时间: $mod_time)"
        fi
      done <<< "$android_engines"
    else
      echo -e "  ${YELLOW}警告: 未找到 Android 引擎文件${NC}"
      echo -e "  ${YELLOW}提示: 运行 'flutter precache' 可以下载引擎文件${NC}"
    fi
  else
    echo -e "  ${YELLOW}警告: 引擎缓存目录不存在${NC}"
  fi
  
  # 输出JSON格式
  cat <<EOF
{
  "flutter_version": "$flutter_version",
  "engine_version": "$engine_version",
  "flutter_root": "$flutter_root",
  "engine_cache_dir": "$engine_cache_dir"
}
EOF
}

# 检查ELF对齐
check_elf_alignment() {
  echo -e "${BLUE}检查 ELF 文件对齐...${NC}"
  
  # 检查 readelf/greadelf 是否可用
  local readelf_cmd=""
  if has_cmd greadelf; then
    readelf_cmd="greadelf"
  elif has_cmd readelf; then
    readelf_cmd="readelf"
  elif [ -f "/opt/homebrew/opt/binutils/bin/greadelf" ]; then
    # macOS Homebrew keg-only 安装路径 (Apple Silicon)
    readelf_cmd="/opt/homebrew/opt/binutils/bin/greadelf"
  elif [ -f "/usr/local/opt/binutils/bin/greadelf" ]; then
    # macOS Homebrew Intel 安装路径
    readelf_cmd="/usr/local/opt/binutils/bin/greadelf"
  fi
  
  if [ -z "$readelf_cmd" ]; then
    echo -e "${YELLOW}警告: readelf 命令不可用，跳过 ELF 对齐检查${NC}"
    echo -e "${YELLOW}提示: macOS 上可以运行 'brew install binutils' 安装${NC}"
    echo -e "${YELLOW}提示: 安装后可能需要将 /opt/homebrew/opt/binutils/bin 添加到 PATH${NC}"
    # 输出空的JSON结果
    echo "{"
    echo "  \"total_checked\": 0,"
    echo "  \"misaligned_count\": 0,"
    echo "  \"misaligned_files\": [],"
    echo "  \"readelf_unavailable\": true"
    echo "}"
    return 0
  fi
  
  local misaligned_files=()
  local checked_files=()
  local total_checked=0
  
  # 检查Flutter引擎
  local flutter_root
  flutter_root=$(flutter --version 2>&1 | grep -E "^Flutter" | awk '{print $NF}' | xargs dirname | xargs dirname)
  if [ -z "$flutter_root" ]; then
    flutter_root=$(which flutter | xargs dirname | xargs dirname)
  fi
  
  local engine_cache_dir="$flutter_root/bin/cache/artifacts/engine"
  if [ -d "$engine_cache_dir" ]; then
    local engine_files
    engine_files=$(find "$engine_cache_dir" -name "*.so" -path "*/android-*" 2>/dev/null)
    
    while IFS= read -r so_file; do
      if [ -f "$so_file" ]; then
        checked_files+=("$so_file")
        total_checked=$((total_checked + 1))
        
        # 检查ELF对齐
        local alignment_info
        alignment_info=$($readelf_cmd -l "$so_file" 2>/dev/null | grep -E "^\s+LOAD" | head -1 | awk '{print $NF}')
        
        if [ -n "$alignment_info" ]; then
          # 转换对齐值（可能是十六进制）
          local alignment_dec
          if [[ "$alignment_info" =~ ^0x ]]; then
            alignment_dec=$((alignment_info))
          else
            alignment_dec=$((alignment_info))
          fi
          
          # 16KB = 16384 字节
          if [ "$alignment_dec" -lt 16384 ]; then
            misaligned_files+=("$so_file|$alignment_dec")
            echo -e "  ${RED}✗${NC} $so_file (对齐: $alignment_dec 字节, 需要: 16384 字节)"
          else
            echo -e "  ${GREEN}✓${NC} $so_file (对齐: $alignment_dec 字节)"
          fi
        fi
      fi
    done <<< "$engine_files"
  fi
  
  # 检查构建产物
  local build_dirs=(
    "build/app/intermediates/merged_native_libs"
    "build/app/intermediates/stripped_native_libs"
  )
  
  for build_dir in "${build_dirs[@]}"; do
    if [ -d "$build_dir" ]; then
      local build_files
      build_files=$(find "$build_dir" -name "*.so" 2>/dev/null)
      
      while IFS= read -r so_file; do
        if [ -f "$so_file" ]; then
          checked_files+=("$so_file")
          total_checked=$((total_checked + 1))
          
          local alignment_info
          alignment_info=$($readelf_cmd -l "$so_file" 2>/dev/null | grep -E "^\s+LOAD" | head -1 | awk '{print $NF}')
          
          if [ -n "$alignment_info" ]; then
            local alignment_dec
            if [[ "$alignment_info" =~ ^0x ]]; then
              alignment_dec=$((alignment_info))
            else
              alignment_dec=$((alignment_info))
            fi
            
            if [ "$alignment_dec" -lt 16384 ]; then
              misaligned_files+=("$so_file|$alignment_dec")
              echo -e "  ${RED}✗${NC} $so_file (对齐: $alignment_dec 字节, 需要: 16384 字节)"
            else
              echo -e "  ${GREEN}✓${NC} $so_file (对齐: $alignment_dec 字节)"
            fi
          fi
        fi
      done <<< "$build_files"
    fi
  done
  
  echo "  总共检查了 $total_checked 个文件"
  echo "  未对齐的文件: ${#misaligned_files[@]}"
  
  # 输出JSON格式
  echo "{"
  echo "  \"total_checked\": $total_checked,"
  echo "  \"misaligned_count\": ${#misaligned_files[@]},"
  echo "  \"misaligned_files\": ["
  local first=true
  for misaligned in "${misaligned_files[@]}"; do
    if [ "$first" = true ]; then
      first=false
    else
      echo ","
    fi
    local file_path
    file_path=$(echo "$misaligned" | cut -d'|' -f1)
    local alignment
    alignment=$(echo "$misaligned" | cut -d'|' -f2)
    echo "    {"
    echo "      \"file\": \"$file_path\","
    echo "      \"alignment\": $alignment"
    echo "    }"
  done
  echo "  ]"
  echo "}"
}

# 检查第三方依赖版本
check_dependencies() {
  echo -e "${BLUE}检查第三方依赖版本...${NC}"
  
  local pubspec_lock="pubspec.lock"
  if [ ! -f "$pubspec_lock" ]; then
    echo -e "${RED}错误: pubspec.lock 文件不存在${NC}"
    return 1
  fi
  
  # 关键依赖列表（包含原生代码的）
  local critical_deps=(
    "isar_flutter_libs"
    "audioplayers"
    "flutter_local_notifications"
    "flutter_foreground_task"
    "file_picker"
    "path_provider"
    "share_plus"
  )
  
  echo "  检查的依赖:"
  for dep in "${critical_deps[@]}"; do
    # pubspec.lock格式：包名在顶层，version在下一级
    local version_line
    version_line=$(grep -A 10 "^  $dep:" "$pubspec_lock" 2>/dev/null | grep -E "^\s+version:" | head -1)
    
    if [ -z "$version_line" ]; then
      # 尝试另一种格式（可能包名有下划线或连字符）
      version_line=$(grep -A 10 "^  ${dep//_/-}:" "$pubspec_lock" 2>/dev/null | grep -E "^\s+version:" | head -1)
    fi
    
    if [ -n "$version_line" ]; then
      local version
      version=$(echo "$version_line" | awk '{print $2}' | tr -d '"')
      echo "    - $dep: $version"
    else
      echo -e "    ${YELLOW}- $dep: 未找到版本信息${NC}"
    fi
  done
  
  # 输出JSON格式（简化版，实际版本从pubspec.lock解析）
  echo "{"
  echo "  \"checked_dependencies\": ["
  local first=true
  for dep in "${critical_deps[@]}"; do
    if [ "$first" = true ]; then
      first=false
    else
      echo ","
    fi
    local version_line
    version_line=$(grep -A 10 "^  $dep:" "$pubspec_lock" 2>/dev/null | grep -E "^\s+version:" | head -1)
    if [ -z "$version_line" ]; then
      version_line=$(grep -A 10 "^  ${dep//_/-}:" "$pubspec_lock" 2>/dev/null | grep -E "^\s+version:" | head -1)
    fi
    local version
    version="unknown"
    if [ -n "$version_line" ]; then
      version=$(echo "$version_line" | awk '{print $2}' | tr -d '"')
    fi
    echo "    {"
    echo "      \"name\": \"$dep\","
    echo "      \"version\": \"$version\""
    echo "    }"
  done
  echo "  ]"
  echo "}"
}

# 检查构建配置
check_build_config() {
  echo -e "${BLUE}检查构建配置...${NC}"
  
  local build_gradle="android/app/build.gradle.kts"
  if [ ! -f "$build_gradle" ]; then
    echo -e "${RED}错误: $build_gradle 文件不存在${NC}"
    return 1
  fi
  
  local issues=()
  local config_ok=true
  
  # 检查NDK版本
  if grep -q "ndkVersion.*29" "$build_gradle"; then
    echo -e "  ${GREEN}✓${NC} NDK 版本已设置为 r29"
  else
    echo -e "  ${RED}✗${NC} NDK 版本未设置为 r29"
    issues=("${issues[@]}" "NDK版本未设置为r29")
    config_ok=false
  fi
  
  # 检查packaging配置
  if grep -q "useLegacyPackaging.*false" "$build_gradle"; then
    echo -e "  ${GREEN}✓${NC} useLegacyPackaging 已设置为 false"
  else
    echo -e "  ${YELLOW}⚠${NC} useLegacyPackaging 配置未找到或未设置为 false"
    issues=("${issues[@]}" "useLegacyPackaging未设置为false")
  fi
  
  # 检查Gradle版本
  local gradle_wrapper="android/gradle/wrapper/gradle-wrapper.properties"
  if [ -f "$gradle_wrapper" ]; then
    local gradle_version
    gradle_version=$(grep "distributionUrl" "$gradle_wrapper" | sed 's/.*gradle-\([0-9.]*\)-.*/\1/')
    echo "  Gradle 版本: $gradle_version"
  fi
  
  # 输出JSON格式
  echo "{"
  echo "  \"config_ok\": $config_ok,"
  echo "  \"issues\": ["
  if [ ${#issues[@]} -gt 0 ]; then
    local first=true
    for issue in "${issues[@]}"; do
      if [ "$first" = true ]; then
        first=false
      else
        echo ","
      fi
      echo "    \"$issue\""
    done
  fi
  echo "  ]"
  echo "}"
}

# 生成完整诊断报告
diagnose_16kb() {
  local report_file="${1:-diagnose_16kb_report.json}"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}16KB 页面大小兼容性诊断${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # 创建临时文件收集JSON输出
  local temp_dir
  temp_dir=$(mktemp -d)
  local flutter_info="$temp_dir/flutter.json"
  local elf_info="$temp_dir/elf.json"
  local deps_info="$temp_dir/deps.json"
  local config_info="$temp_dir/config.json"
  
  # 运行各项检查，同时显示输出和保存JSON
  # 使用临时文件保存完整输出，然后提取JSON部分
  echo ""
  check_flutter_version 2>&1 | tee "$temp_dir/flutter_full.txt"
  awk '/^{/,/^}$/ {print}' "$temp_dir/flutter_full.txt" > "$flutter_info" 2>/dev/null || echo "{}" > "$flutter_info"
  echo ""
  check_elf_alignment 2>&1 | tee "$temp_dir/elf_full.txt"
  awk '/^{/,/^}$/ {print}' "$temp_dir/elf_full.txt" > "$elf_info" 2>/dev/null || echo "{}" > "$elf_info"
  echo ""
  check_dependencies 2>&1 | tee "$temp_dir/deps_full.txt"
  awk '/^{/,/^}$/ {print}' "$temp_dir/deps_full.txt" > "$deps_info" 2>/dev/null || echo "{}" > "$deps_info"
  echo ""
  check_build_config 2>&1 | tee "$temp_dir/config_full.txt"
  awk '/^{/,/^}$/ {print}' "$temp_dir/config_full.txt" > "$config_info" 2>/dev/null || echo "{}" > "$config_info"
  
  echo ""
  echo -e "${BLUE}生成诊断报告...${NC}"
  
  # 合并JSON报告
  local flutter_json deps_json elf_json config_json
  flutter_json=$(extract_json "$flutter_info")
  elf_json=$(extract_json "$elf_info")
  deps_json=$(extract_json "$deps_info")
  config_json=$(extract_json "$config_info")
  
  # 确保JSON格式正确（如果提取失败，使用空对象）
  [ -z "$flutter_json" ] && flutter_json="{}"
  [ -z "$elf_json" ] && elf_json="{}"
  [ -z "$deps_json" ] && deps_json="{}"
  [ -z "$config_json" ] && config_json="{}"
  
  # 验证JSON格式（简单检查）
  echo "$flutter_json" | grep -q "^{" || flutter_json="{}"
  echo "$elf_json" | grep -q "^{" || elf_json="{}"
  echo "$deps_json" | grep -q "^{" || deps_json="{}"
  echo "$config_json" | grep -q "^{" || config_json="{}"
  
  {
    echo "{"
    echo "  \"timestamp\": \"$timestamp\","
    echo "  \"flutter\": $flutter_json,"
    echo "  \"elf_alignment\": $elf_json,"
    echo "  \"dependencies\": $deps_json,"
    echo "  \"build_config\": $config_json"
    echo "}"
  } > "$report_file"
  
  # 清理临时文件
  rm -rf "$temp_dir"
  
  echo -e "${GREEN}诊断报告已保存到: $report_file${NC}"
  echo ""
  echo -e "${BLUE}问题摘要:${NC}"
  
  # 解析并显示问题摘要
  local misaligned_count
  misaligned_count=$(grep -o '"misaligned_count": [0-9]*' "$report_file" | grep -o '[0-9]*' || echo "0")
  
  if [ "$misaligned_count" -gt 0 ]; then
    echo -e "  ${RED}发现 $misaligned_count 个未对齐的 .so 文件${NC}"
  else
    echo -e "  ${GREEN}所有检查的 .so 文件都已正确对齐${NC}"
  fi
  
  local config_ok
  config_ok=$(grep -o '"config_ok": [a-z]*' "$report_file" | grep -o '[a-z]*$' || echo "false")
  
  if [ "$config_ok" = "false" ]; then
    echo -e "  ${RED}构建配置存在问题${NC}"
  else
    echo -e "  ${GREEN}构建配置检查通过${NC}"
  fi
}
