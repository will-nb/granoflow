#!/bin/bash
# shellcheck shell=bash

fix_issues() {
  if ! has_cmd python3; then
    echo -e "${RED}执行 fix:issues 需要 Python 3 环境${NC}"
    exit 1
  fi

  local script_path="$ROOT_DIR/scripts/anz_modules/fix/issues.py"
  if [[ ! -f "$script_path" ]]; then
    echo -e "${RED}未找到修复脚本：$script_path${NC}"
    exit 1
  fi

  python3 "$script_path" "$@"
}
