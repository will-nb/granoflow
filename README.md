# GranoFlow

GranoFlow 是一款离线优先的任务与计时管理应用，支持 Android、iOS 与 macOS，围绕「收集、计划、执行、复盘」四个阶段打造顺滑体验。

## 环境准备
1. **安装依赖**
   - Flutter SDK：`>=3.8.0 <4.0.0`（推荐使用 FVM 管理版本）
   - Dart SDK：随 Flutter 一同安装
   - Android Studio（Arctic Fox+）或 VS Code（需安装 Flutter/Dart 插件）
   - Xcode 14+（仅 macOS 构建）
   - Git、Chrome（Web 调试可选）

2. **使用 FVM 安装 Flutter**
   ```bash
   brew install fvm                          # macOS
   fvm install 3.24.0                        # 对齐 tech spec 建议版本
   fvm use 3.24.0 --force
   fvm flutter doctor                        # 检查环境
   ```
   如未使用 FVM，可直接从 [Flutter 官网](https://docs.flutter.dev/get-started/install) 获取最新稳定版，并确保与上述版本范围兼容。

3. **克隆与初始化**
   ```bash
   git clone <repo-url>
   cd granoflow
   fvm flutter pub get
   ```

4. **代码生成与本地化**
   ```bash
   fvm flutter pub run build_runner build --delete-conflicting-outputs
   fvm flutter gen-l10n
   ```

## 常用命令
- `fvm flutter analyze`：静态检查（CI Gate）。
- `fvm flutter test`：运行单元与 Widget 测试。
- `fvm flutter test integration_test`：运行集成测试。
- `fvm flutter format . --line-length 100`：统一代码风格。
- `fvm flutter pub run build_runner watch --delete-conflicting-outputs`：持续生成 Isar 适配器、Retrofit 客户端等。

## 目录结构速览
- `lib/core`：应用入口、服务、依赖注入。
- `lib/data`：模型、仓库、离线同步。
- `lib/presentation`：页面与组件。
- `assets/seeds`：多语言种子数据。
- `documents/`：需求、架构、KPI、迭代计划等文档。

## 贡献者指南（摘要）
- 遵循 `AGENTS.md` 中的代码规范与提交流程。
- 新功能需附带文档更新、测试覆盖与多语言条目。
- 触及数据模型时同步更新 `documents/storage_migrations.md` 并编写迁移策略。

更多背景、术语与流程请参考 `documents/project_plan.yaml` 与 `documents/product_requirements.yaml`。
