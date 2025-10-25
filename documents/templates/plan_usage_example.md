# Plan 模板使用示例

## 如何使用 plan_template.yaml

### 1. 基本使用流程

1. **复制模板**：将 `plan_template.yaml` 复制到 `documents/plan/` 目录
2. **重命名文件**：按照 `YYMMDD-N-plan.yaml` 格式命名
3. **基于 preview 填写**：根据对应的 preview 文档填写实施计划
4. **执行跟踪**：按照 execution_tracking 进行状态管理

### 2. 四大核心要素详解

#### 3.1 实现规范YAML生成/修改计划

```yaml
yaml_specification_updates:
  updates:
    - file: "documents/architecture/widgets/drawer_menu.yaml"
      action: "create"
      based_on: "preview中的new_files部分"
      changes:
        - field: "class_name"
          value: "DrawerMenu"
          source: "preview中drawer_menu.dart的class_name定义"
        - field: "properties"
          value: "displayMode, onDestinationSelected, onClose"
          source: "preview中drawer_menu.dart的properties部分"
```

#### 3.2 验收测试用例计划

**现有测试修改**：
```yaml
existing_tests:
  tests:
    - file: "test/presentation/navigation/app_shell_test.dart"
      test_name: "test_app_shell_navigation"
      modification_type: "modify"
      reason: "根据preview变更，AppShell不再直接管理NavigationRail"
      current_expectation: "测试AppShell直接创建NavigationRail"
      new_expectation: "测试AppShell使用ResponsiveNavigation"
```

**新测试创建**：
```yaml
new_tests:
  tests:
    - file: "test/presentation/navigation/drawer_menu_test.dart"
      test_name: "test_drawer_menu_display_modes"
      test_type: "widget_test"
      description: "测试DrawerMenu的三种显示模式"
      expectation: "验证hidden/iconOnly/full三种模式正确切换"
```

**配置验证测试**：
```yaml
configuration_tests:
  tests:
    - test_name: "test_theme_configuration_consistency"
      description: "验证主题配置与YAML文件一致"
      validation_method: "读取documents/config/theme.yaml进行验证"
      expectation: "配置值不是硬编码，且与YAML文件内容一致"
      yaml_files:
        - "documents/config/theme.yaml"
```

#### 3.3 实现代码计划

```yaml
implementation_plan:
  code_changes:
    - file: "lib/presentation/navigation/drawer_menu.dart"
      action: "create"
      based_on: "preview中的drawer_menu.dart设计"
      changes:
        - type: "class_creation"
          description: "创建DrawerMenu类"
          implementation: |
            class DrawerMenu extends StatelessWidget {
              final DrawerDisplayMode displayMode;
              // ... 实现代码
            }
```

#### 3.4 执行状态跟踪

```yaml
execution_tracking:
  overall_status: "pending"
  current_phase: "yaml_updates"
  completed_phases: []
  
  phases:
    - name: "yaml_updates"
      status: "in_progress"
      tasks:
        - task: "更新widgets规范文件"
          status: "completed"
          retry_count: 0
        - task: "更新pages规范文件"
          status: "in_progress"
          retry_count: 1
          failure_reasons: ["YAML格式错误"]
```

### 3. 重试和跳过机制

#### 重试记录
```yaml
# 在对应任务的failure_reasons中记录
failure_reasons:
  - "第1次尝试：YAML格式错误，缺少必需字段"
  - "第2次尝试：字段值类型不匹配，应为string但提供了int"
  - "第3次尝试：文件路径错误，找不到目标文件"
```

#### 跳过记录
```yaml
skip_records:
  - task_id: "TASK-001"
    task_name: "更新widgets规范文件"
    skip_reason: "YAML格式问题无法解决"
    attempts:
      - attempt: 1
        approach: "直接修改YAML文件"
        failure_manifestation: "YAML解析错误：缺少必需字段"
        excluded_possibilities: "排除了模板问题，确认是内容问题"
      - attempt: 2
        approach: "使用YAML验证工具检查"
        failure_manifestation: "验证工具显示字段类型不匹配"
        excluded_possibilities: "排除了语法问题，确认是数据类型问题"
      - attempt: 3
        approach: "重新生成YAML文件"
        failure_manifestation: "生成的文件仍然有格式问题"
        excluded_possibilities: "排除了手动修改问题，可能是模板本身有问题"
    final_conclusion: "YAML模板可能存在格式问题，需要先修复模板再继续"
```

### 4. 质量检查清单

- [ ] 所有 YAML 文件变更都有明确的来源（基于 preview 的哪个部分）
- [ ] 测试用例明确区分现有测试修改和新测试创建
- [ ] 配置相关测试包含 YAML 文件验证
- [ ] 实现代码计划包含具体的代码片段
- [ ] 执行状态跟踪包含完整的阶段划分
- [ ] 重试机制最多3次，记录每次失败原因
- [ ] 跳过记录包含详细的问题分析和解决尝试

### 5. 执行流程

1. **YAML 更新阶段**：根据 preview 更新实现规范文件
2. **测试准备阶段**：创建/修改测试用例
3. **代码实现阶段**：实现具体代码
4. **验证阶段**：运行测试验证实现

每个阶段完成后更新 `execution_tracking` 中的状态，遇到问题时记录重试或跳过原因。