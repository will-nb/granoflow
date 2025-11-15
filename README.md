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
   storeFile=granoflow-keystore.jks
   storePassword=YOUR_ACTUAL_STORE_PASSWORD
   keyAlias=YOUR_KEY_ALIAS
   keyPassword=YOUR_ACTUAL_KEY_PASSWORD
   ```

3. 将签名密钥文件 `granoflow-keystore.jks` 放置在 `android/app/` 目录（此文件会被 `.gitignore` 忽略）
   - **注意**：lite 和 pro 版本共用同一个 keystore 文件，因为它们的包名不同（`com.granoflow.lite` 和 `com.granoflow.pro`），不会产生冲突
   - 同一个 keystore 也可以用于其他项目，只要包名不同即可

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

#### 手动发布
1. 使用上述命令构建 AAB 文件
2. 访问 [Google Play Console](https://play.google.com/console/)
3. 创建新应用并上传 AAB 文件
4. 完善应用信息（描述、截图、隐私政策等）
5. 提交审核

#### 自动发布（CI/CD）

项目已配置通过 GitHub Actions 自动部署到 Google Play。

**分支策略**：

- **`staging` 分支**：全平台构建和发布
  - 当代码推送到 `staging` 分支时，会自动构建所有平台的安装包
  - 自动创建 GitHub Release，包含：
    - Android APK
    - macOS (.app 和 .zip)
    - Windows (.exe)
    - Linux (压缩包)
  - 用于全平台验证，验证通过后合并到 `develop` 分支

- **`develop` 分支**：内部测试快速迭代
  - 当代码推送到 `develop` 分支时，会自动构建 Lite 版本的 AAB 和 APK
  - AAB 部署到 Google Play Internal Testing 轨道（团队内部快速迭代，最多100人）
  - APK 发布到 GitHub Release（备用下载渠道，无需审核）

**手动触发**：
- 在 GitHub Actions 页面手动运行相应的工作流
- 可选择跳过构建，仅部署已有的 artifact
- 可以手动选择部署到其他轨道（Alpha、Beta、Production）

**所需 GitHub Secrets**：

在 GitHub Repository Settings → Secrets and variables → Actions 中配置以下 secrets：

1. `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
   - Google Play Service Account 的完整 JSON 凭证内容
   - 获取方式：Google Play Console → 设置 → API 访问 → 创建服务账号 → 下载 JSON 密钥

2. `ANDROID_KEYSTORE_BASE64`
   - keystore 文件的 base64 编码
   - **注意**：lite 和 pro 版本共用同一个 keystore（因为包名不同，不会冲突）
   - 获取方式：`base64 -i granoflow-keystore.jks | pbcopy`（macOS）或 `base64 -i granoflow-keystore.jks`（Linux）
   - 也可以用于其他项目，只要包名不同即可

3. `ANDROID_KEYSTORE_PASSWORD`
   - keystore 密码

4. `ANDROID_KEY_ALIAS`
   - 密钥别名（通常是 `granoflow` 或 `upload`）

5. `ANDROID_KEY_PASSWORD`
   - 密钥密码

**Google Play Service Account 设置步骤**：

1. 访问 [Google Play Console](https://play.google.com/console/)
2. 进入 **设置** → **API 访问**
3. 创建新的服务账号（如果还没有）
4. 创建新的服务账号密钥，下载 JSON 文件
5. 在 Google Play Console 中，为该服务账号授予 **发布应用** 权限
6. 将 JSON 文件内容复制到 `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` secret

**Google Play 测试轨道说明**：

- **Internal Testing**（develop 分支自动部署）
  - 用于团队内部快速迭代测试（最多100人）
  - 首次提交需要审核（1-3天），后续更新几乎无需审核（几秒内可用）
  - 适合：测试工程师发现 bug → 程序员修复 → 立即提交 → 继续测试的循环
  - 一天多次提交完全没问题

- **Alpha (Closed Testing)**
  - 封闭测试，无人数限制
  - 审核时间：几分钟到几小时
  - 适合：中等频率的封闭测试

- **Beta (Open Testing)**
  - 公开测试，无人数限制
  - 审核时间：几小时到几天
  - 适合：公开测试，收集用户反馈

- **Production**
  - 正式发布版本
  - 审核时间：几天
  - 适合：正式发布给所有用户

**注意事项**：
- 首次部署前需在 Google Play Console 创建应用并完成基本信息设置
- 首次提交到 Internal Testing 需要审核（1-3天），后续更新几乎无需等待
- 需要在 Google Play Console 中添加测试人员到 Internal Testing 测试计划
- keystore 必须与 Google Play Console 中配置的签名密钥一致
- **keystore 共享**：lite 和 pro 版本共用同一个 keystore 文件（`granoflow-keystore.jks`），因为它们的包名不同（`com.granoflow.lite` 和 `com.granoflow.pro`），不会产生冲突。同一个 keystore 也可以用于其他项目，只要包名不同即可。
- versionCode 必须递增，否则上传会失败（需手动更新 `pubspec.yaml` 中的 build 号）
- 工作流会跳过 metadata 和 screenshots 上传，仅上传 AAB 文件

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
