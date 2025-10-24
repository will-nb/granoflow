# GranoFlow

GranoFlow 是一款离线优先的任务与计时管理应用，支持 Android、iOS 与 macOS，围绕「收集、计划、执行、复盘」四个阶段打造顺滑体验。

## Git 仓库管理

### 敏感文件处理
项目已配置完善的 `.gitignore`，自动忽略以下敏感文件：
- 签名密钥文件（`*.jks`, `*.keystore`, `keystore.properties`）
- 构建产物（`*.apk`, `*.aab`, `*.ipa`）
- IDE 配置和缓存文件
- 系统临时文件

⚠️ **重要**：实际的签名密钥文件请勿提交到仓库。使用 `android/app/keystore.sample.properties` 作为模板。

### 签名配置
1. 复制示例文件：
   ```bash
   cp android/app/keystore.sample.properties android/app/keystore.properties
   ```

2. 编辑 `android/app/keystore.properties` 并填入真实信息：
   ```properties
   storeFile=upload-keystore.jks
   storePassword=YOUR_ACTUAL_STORE_PASSWORD
   keyAlias=upload
   keyPassword=YOUR_ACTUAL_KEY_PASSWORD
   ```

3. 将签名密钥文件 `upload-keystore.jks` 放置在 `android/app/` 目录（此文件会被 `.gitignore` 忽略）

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

## 构建与发布

### Android 构建
```bash
# 构建调试 APK
fvm flutter build apk --debug

# 构建发布 APK（需要签名配置）
fvm flutter build apk --release

# 构建 AAB 文件（推荐，用于 Google Play）
fvm flutter build appbundle --release
```

### iOS/macOS 构建
```bash
# iOS（需要 Xcode）
fvm flutter build ios --release

# macOS
fvm flutter build macos --release
```

### Google Play 发布
1. 使用上述命令构建 AAB 文件
2. 访问 [Google Play Console](https://play.google.com/console/)
3. 创建新应用并上传 AAB 文件
4. 完善应用信息（描述、截图、隐私政策等）
5. 提交审核

## 常用命令
- `fvm flutter analyze`：静态检查（CI Gate）。
- `fvm flutter test`：运行单元与 Widget 测试。
- `fvm flutter test integration_test`：运行集成测试。
- `fvm flutter format . --line-length 100`：统一代码风格。
- `fvm flutter pub run build_runner watch --delete-conflicting-outputs`：持续生成 Isar 适配器、Retrofit 客户端等。

## 目录结构速览

### 代码结构
- `lib/core`：应用入口、服务、依赖注入。
- `lib/data`：模型、仓库、离线同步。
- `lib/presentation`：页面与组件。
- `assets/seeds`：多语言种子数据。

### 文档结构 (documents/)
```
documents/
├── spec/           # 📋 规格文档 - 定义"做什么"
│   ├── product_requirements.yaml    # 产品需求规格
│   ├── user_stories.md             # 用户故事
│   ├── *-技术规范.yaml             # 技术规范文档
│   └── iteration_template.yaml     # 迭代模板
├── config/         # ⚙️ 配置文档 - 定义"如何配置"
│   ├── theme.yaml                  # 主题配置
│   ├── config.yaml                 # 环境配置
│   ├── l10n.yaml                   # 本地化配置
│   └── analysis_options.yaml       # 代码分析配置
├── architecture/   # 🏗️ 架构文档 - 定义"如何构建"
│   ├── models.yaml                 # 数据模型
│   ├── pages.yaml                  # 页面结构
│   ├── providers.yaml              # 状态管理
│   ├── services.yaml               # 业务服务
│   ├── widgets.yaml                # 组件定义
│   └── routers.yaml                # 路由配置
├── project/        # 📊 项目管理文档 - 定义"如何管理"
│   ├── project_plan.yaml           # 项目计划
│   ├── PROGRESS.md                 # 项目进度
│   ├── rules.yaml                  # 项目规则
│   ├── refactor_rules.yaml         # 重构规则
│   ├── todo-list.yaml              # 任务列表
│   └── kpi_overview.md             # KPI概览
├── plan/           # 🎯 迭代计划文档 - 定义"如何执行"
│   ├── *-preview.yaml              # 迭代预览
│   └── *-plan.yaml                 # 详细计划
├── deployment/     # 🚀 部署相关文档 - 定义"如何部署"
│   ├── go_live_report.md           # 上线报告
│   ├── launch_checklist.md         # 发布清单
│   └── storage_migrations.md       # 数据迁移
├── legal/          # ⚖️ 法律文档 - 定义"法律合规"
│   ├── privacy_policy.md           # 隐私政策
│   └── terms_of_service.md         # 服务条款
└── test_reports/   # 🧪 测试报告 - 记录"测试结果"
    └── offline_validation.md       # 离线验证报告
```

**文档职责分工**：
- **spec/**: 产品规格和需求定义，是项目开发的基础依据
- **config/**: 技术配置和环境设置，影响代码运行行为
- **architecture/**: 系统架构和组件设计，指导代码实现
- **project/**: 项目管理和进度跟踪，确保项目按计划推进
- **plan/**: 迭代执行计划，阶段性文档，完成后可归档
- **deployment/**: 部署和发布相关，确保上线过程顺利
- **legal/**: 法律合规文档，保护项目和用户权益
- **test_reports/**: 测试验证结果，为质量把关

## 贡献者指南（摘要）
- 遵循 `AGENTS.md` 中的代码规范与提交流程。
- 新功能需附带文档更新、测试覆盖与多语言条目。
- 触及数据模型时同步更新 `documents/storage_migrations.md` 并编写迁移策略。

更多背景、术语与流程请参考 `documents/project_plan.yaml` 与 `documents/product_requirements.yaml`。
