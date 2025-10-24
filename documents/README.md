# Documents 目录结构说明

本文档目录采用分类组织方式，便于管理和维护项目文档。

## 📁 目录结构

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

## 📖 使用指南

### 📋 文档类型说明

- **spec/**: 产品规格和需求定义，是项目开发的基础依据
- **config/**: 技术配置和环境设置，影响代码运行行为
- **architecture/**: 系统架构和组件设计，指导代码实现
- **project/**: 项目管理和进度跟踪，确保项目按计划推进
- **plan/**: 迭代执行计划，阶段性文档，完成后可归档
- **deployment/**: 部署和发布相关，确保上线过程顺利
- **legal/**: 法律合规文档，保护项目和用户权益
- **test_reports/**: 测试验证结果，为质量把关

### 🔄 文档生命周期

- **spec/config/architecture/project**: 长期维护，随着项目演进持续更新
- **plan/**: 阶段性文档，迭代完成后可移至归档目录
- **deployment/test_reports**: 按版本或时间保留历史记录

### 📝 命名规范

- YAML文件: `snake_case.yaml`
- Markdown文件: `snake_case.md`
- 迭代相关: `YYMMDD-iteration_name.yaml`
- 技术规范: `YYMMDD-技术规范.yaml`

## 🤝 贡献指南

1. **新文档**: 根据内容类型选择合适的文件夹
2. **现有文档**: 如需重命名或移动，请同步更新相关引用
3. **迭代文档**: plan/ 下的文档在迭代完成后应考虑归档
4. **引用路径**: 文档间引用请使用相对路径，方便维护

## 📞 联系与支持

如有文档组织或分类问题，请及时提出建议，共同维护良好的文档结构。