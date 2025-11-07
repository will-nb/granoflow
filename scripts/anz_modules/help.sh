#!/bin/bash
# 帮助函数模块

# 注意：此文件需要被 source，所以不设置 set -euo pipefail
# 颜色变量和工具函数应该由主文件定义

show_main_help() {
  cat << EOF
GranoFlow 项目管理脚本

用法: $(basename "$0") <命令> [选项]

项目管理命令：
  clean           清理项目并重建
  build:aab       构建 Android App Bundle (AAB) 文件
  hooks:install   配置/更新 Git hooks（pre-commit / pre-push）

代码质量命令：
  refactor        检查哪些文件和方法需要重构（根据文件大小和方法长度阈值）

图标生成命令：
  icons:generate       生成所有平台的应用图标

文档生成命令：
  yaml:create        基于模板创建单个 architecture YAML 文档
  yaml:create:all    批量重新生成所有六大核心类型的 YAML 文档
  yaml:test          运行 YAML 一致性测试（支持 schema/fields/refs/sync 细粒度选项）

运行命令：
  run:android       在 Android 手机上运行（Pixel 6, 6.4", 1080 x 2400）
  run:tablet        在 Android 平板上运行（Pixel Tablet, 10.2", 2560 x 1600）
  run:iphone        在 iPhone 上运行（iPhone 16 Pro, 6.3", 1290 x 2796）
  run:ipad          在 iPad 上运行（iPad Pro 11", 11", 2388 x 1668）
  run:macos         在 macOS 上运行（桌面应用）

测试命令：
  test               并行执行 test/ 下所有 *_test.dart 测试
  test:drag          运行拖拽集成测试 100 次（随机坐标测试）

使用 '$(basename "$0") <命令> --help' 查看具体命令的详细用法
EOF
}

# 显示 yaml 子命令帮助
show_yaml_help() {
  cat << 'YAML_HELP'
Usage: scripts/anz yaml:create --file FILEPATH --type TYPE [--from DART_FILE]

Description:
  基于 Dart 文件分析或模板创建 architecture YAML 文档；自动提取类信息、依赖、i18n 键和设计令牌。

Arguments:
  --file FILEPATH     目标 YAML 文件路径（相对于项目根目录）
  --type TYPE         文档类型：widget|page|model|provider|repository|service
  --from DART_FILE    [可选] 源 Dart 文件路径，用于自动提取信息

Examples:
  # 从 Dart 文件自动生成 YAML（推荐）
  scripts/anz yaml:create --file documents/architecture/widgets/modern_tag.yaml --type widget --from lib/presentation/widgets/modern_tag.dart
  
  # 仅从模板创建空 YAML（需手动填充）
  scripts/anz yaml:create --file documents/architecture/widgets/new_widget.yaml --type widget

Note:
  - 使用 --from 参数可自动分析 Dart 文件并填充 YAML 字段
  - 创建后会自动运行 Linter 校验，如有问题需修正后再提交
YAML_HELP
}

show_yaml_test_help() {
  cat << 'YAML_TEST_HELP'
Usage: scripts/anz yaml:test [--all|--schema|--fields|--refs|--sync] [-v|--verbose]

Description:
  运行 YAML 架构文档的一致性测试套件。默认执行全部测试，可通过选项仅运行特定类别。

Options:
  --all        运行所有测试（默认）
  --schema     仅验证 schema 约束（字段存在、类型正确等）
  --fields     仅验证字段完整性（必填字段、引用字段等）
  --refs       仅验证跨文档引用一致性（calls/called_by 等）
  --sync       仅验证 YAML 与代码实现的同步情况
  -v,--verbose 通过给 Flutter 测试增加 --verbose 输出
  -h,--help    显示此帮助

Examples:
  scripts/anz yaml:test                # 运行全部测试
  scripts/anz yaml:test --schema       # 仅运行 schema 验证
  scripts/anz yaml:test --sync -v      # 同步验证并输出详细日志
YAML_TEST_HELP
}

show_hooks_install_help() {
  cat << 'HOOKS_HELP'
Usage: scripts/anz hooks:install

Description:
  配置项目的 Git hooks（pre-commit 与 pre-push），确保在提交/推送前自动执行格式化、分析与 YAML 校验。

Actions:
  - 设置 git config core.hooksPath=scripts/git-hooks
  - 为 pre-commit、pre-push 脚本添加执行权限

Examples:
  scripts/anz hooks:install            # 安装或更新本地 Git hooks
HOOKS_HELP
}

# 显示 yaml:create:all 帮助
show_yaml_create_all_help() {
  cat << 'YAML_ALL_HELP'
Usage: scripts/anz yaml:create:all [--dry-run] [--no-backup]

Description:
  批量重新生成所有六大核心类型的 architecture YAML 文档。
  
  会清空并重新生成以下目录：
  - documents/architecture/models/
  - documents/architecture/pages/
  - documents/architecture/widgets/
  - documents/architecture/providers/
  - documents/architecture/repositories/
  - documents/architecture/services/

Options:
  --dry-run          模拟运行，不实际修改文件
  --no-backup        不创建备份（谨慎使用）

Examples:
  # 完整重新生成所有文档（推荐，会自动备份）
  scripts/anz yaml:create:all
  
  # 模拟运行，查看会生成哪些文件
  scripts/anz yaml:create:all --dry-run
  
  # 不创建备份（谨慎使用）
  scripts/anz yaml:create:all --no-backup

Safety:
  - 默认会将 documents/architecture 重命名为 documents/architecture-yymmdd-hhmmss
  - 然后重新创建 documents/architecture 目录并生成所有 YAML
  - routers.yaml 会被自动保留并恢复（作为路由地图的特殊情况）
  - 建议先运行 --dry-run 查看影响范围
  - 运行后会自动执行 architecture_linter.py 校验
  - 推荐在干净的 git 工作树中执行

Note:
  此命令设计为经常执行，确保 YAML 文档与代码保持同步。
  仅为六大核心类型生成文档（不包括 Constants/Config/Theme/Enums 等）。
  routers.yaml 作为全局路由地图会被保留。
YAML_ALL_HELP
}

