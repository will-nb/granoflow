# YAML 一致性测试文档

## 📋 概述

这个文档描述了基于 YAML 的一致性测试框架，确保代码实现与设计文档的一致性。测试框架遵循以下原则：

- **YAML 作为单一数据源**：所有测试必须读取 YAML 文件，不能硬编码
- **变更约束**：禁止减少、重命名或修改现有定义，必须先修改 YAML
- **完整性验证**：YAML 文件丢失时测试必须失败

## 🎯 测试目标

### 1. 导航组件一致性
- `NavigationDestinations` 枚举与 YAML 定义一致
- `DrawerMenu` 组件与 YAML 定义一致
- `ResponsiveNavigation` 组件与 YAML 定义一致

### 2. UI 组件一致性
- `MainDrawer` 组件与 YAML 定义一致
- `PageAppBar` 组件与 YAML 定义一致
- `CreateTaskDialog` 组件与 YAML 定义一致

### 3. YAML 完整性
- 所有必需的 YAML 文件存在
- YAML 语法正确
- YAML 结构完整

### 4. 集成一致性
- 导航组件之间的集成一致
- 主题色使用一致
- 响应式行为一致

## 🧪 测试文件结构

```
test/
├── presentation/
│   ├── navigation/
│   │   ├── yaml_based_consistency_test.dart      # 导航组件一致性测试
│   │   └── integration_consistency_test.dart     # 集成一致性测试
│   └── widgets/
│       └── yaml_based_widget_test.dart           # 组件一致性测试
├── documentation/
│   └── yaml_integrity_test.dart                  # YAML 完整性测试
├── run_yaml_tests.dart                           # 测试运行器
├── yaml_test_config.yaml                        # 测试配置
└── README_YAML_TESTS.md                          # 本文档
```

## 🔧 测试配置

### 测试组配置
- **导航组件测试**：验证导航组件与 YAML 的一致性
- **组件测试**：验证 UI 组件与 YAML 的一致性
- **YAML 完整性测试**：验证 YAML 文档的完整性
- **集成一致性测试**：验证组件间的集成一致性

### 约束规则
- ✅ **允许**：增加新的图标、路由、文本
- ❌ **禁止**：减少现有的图标、路由、文本
- ❌ **禁止**：重命名现有的变量名、路由名、图标名
- ❌ **禁止**：修改现有的图标、路由、文本定义

### 变更流程
1. 必须先修改 YAML 文档
2. 然后修改代码实现
3. 最后运行一致性测试
4. 测试通过后才能提交

## 🚀 运行测试

### 1. 使用脚本运行
```bash
# 运行所有测试
./scripts/run_yaml_tests.sh --all

# 运行特定测试组
./scripts/run_yaml_tests.sh --navigation
./scripts/run_yaml_tests.sh --widgets
./scripts/run_yaml_tests.sh --documentation
./scripts/run_yaml_tests.sh --integration

# 显示详细输出
./scripts/run_yaml_tests.sh --all --verbose
```

### 2. 使用 Flutter 命令运行
```bash
# 运行导航组件测试
flutter test test/presentation/navigation/yaml_based_consistency_test.dart

# 运行组件测试
flutter test test/presentation/widgets/yaml_based_widget_test.dart

# 运行 YAML 完整性测试
flutter test test/documentation/yaml_integrity_test.dart

# 运行集成一致性测试
flutter test test/presentation/navigation/integration_consistency_test.dart
```

### 3. 使用测试运行器
```bash
# 运行所有 YAML 测试
dart test/run_yaml_tests.dart
```

## 🔍 测试详情

### 导航组件一致性测试
- **NavigationDestinations 一致性**：验证枚举值与 YAML 定义一致
- **图标定义一致性**：验证图标定义与 YAML 匹配
- **路由定义一致性**：验证路由定义与 YAML 匹配
- **DrawerMenu 一致性**：验证组件属性与方法与 YAML 一致
- **ResponsiveNavigation 一致性**：验证响应式行为与 YAML 一致

### 组件一致性测试
- **MainDrawer 一致性**：验证抽屉组件与 YAML 定义一致
- **PageAppBar 一致性**：验证页面顶部导航栏与 YAML 定义一致
- **CreateTaskDialog 一致性**：验证创建任务对话框与 YAML 定义一致

### YAML 完整性测试
- **文件存在性**：验证所有必需的 YAML 文件存在
- **语法有效性**：验证 YAML 文件语法正确
- **结构完整性**：验证 YAML 文件结构完整
- **组件完整性**：验证导航和业务组件定义完整
- **依赖完整性**：验证依赖关系定义完整

### 集成一致性测试
- **导航目标一致性**：验证导航目标定义一致
- **主题色一致性**：验证主题色使用一致
- **响应式行为一致性**：验证响应式行为一致
- **方法实现一致性**：验证方法实现一致
- **依赖关系一致性**：验证依赖关系一致

## 🛡️ 约束机制

### Pre-commit 钩子
每次提交前自动运行 YAML 一致性测试，如果测试失败则阻止提交。

### CI/CD 集成
GitHub Actions 工作流在每次推送和 PR 时运行测试，确保代码与设计文档一致。

### 开发工作流
1. 修改代码前必须先更新 YAML 文档
2. 提交前必须运行 YAML 一致性测试
3. 合并前必须确保所有测试通过

## 📊 测试报告

### 报告格式
- **JSON 格式**：机器可读的测试报告
- **控制台输出**：人类可读的测试结果
- **摘要信息**：测试通过率、失败详情等

### 报告内容
- 测试执行时间
- 测试通过率
- 失败测试详情
- 新增内容警告
- 一致性检查结果

## 🚨 错误处理

### 错误类型
- **关键错误**：YAML 文件丢失、语法错误、一致性检查失败
- **警告**：检测到新增内容

### 错误处理策略
- **YAML 文件丢失**：阻止提交，要求创建文件
- **YAML 语法错误**：阻止提交，要求修复语法
- **一致性检查失败**：阻止提交，要求修复不一致
- **新增内容警告**：发出警告，但允许继续

## 🔄 维护指南

### 添加新测试
1. 在相应的测试文件中添加新的测试用例
2. 更新 `yaml_test_config.yaml` 配置
3. 运行测试确保新测试正常工作

### 修改现有测试
1. 必须先修改 YAML 文档
2. 然后修改测试代码
3. 运行测试确保修改正确

### 删除测试
1. 必须先修改 YAML 文档
2. 然后删除测试代码
3. 更新配置文件

## 📚 相关文档

- [YAML 测试配置文件](yaml_test_config.yaml)
- [测试运行脚本](../scripts/run_yaml_tests.sh)
- [Pre-commit 钩子](../.git/hooks/pre-commit)
- [GitHub Actions 工作流](../.github/workflows/yaml-consistency.yml)

## 🤝 贡献指南

1. 在修改代码前，请先更新相应的 YAML 文档
2. 运行 YAML 一致性测试确保修改正确
3. 提交代码前确保所有测试通过
4. 如果遇到测试失败，请检查 YAML 文档和代码实现的一致性

## 📞 支持

如果您在使用 YAML 一致性测试时遇到问题，请：

1. 检查 YAML 文件是否存在且语法正确
2. 确保代码实现与 YAML 文档一致
3. 运行本地测试：`./scripts/run_yaml_tests.sh --all`
4. 查看测试报告了解具体失败原因
