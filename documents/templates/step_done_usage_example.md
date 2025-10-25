# Step-Done 模板使用示例

## 如何使用 step_done_template.yaml

### 1. 基本使用流程

1. **触发条件**：用户执行"step-done"命令
2. **前提条件**：代码实现已完成且用户手工测试通过
3. **复制模板**：将 `step_done_template.yaml` 复制到 `documents/plan/` 目录
4. **重命名文件**：按照 `YYMMDD-N-step-done.yaml` 格式命名
5. **基于 step 填写**：根据对应的 step 文档填写YAML和测试补充计划
6. **执行跟踪**：按照 execution_tracking 进行状态管理

### 2. 核心字段详解

#### 2.1 规范YAML文件更新计划

```yaml
yaml_updates:
  new_yaml_files:
    files:
      - file: "documents/architecture/widgets/drawer_menu.yaml"
        based_on: "step文档中drawer_menu.dart的代码实现"
        class_name: "DrawerMenu"
        type: "StatelessWidget"
        description: "增强抽屉菜单组件，支持三种显示模式"
        properties:
          - name: "displayMode"
            type: "DrawerDisplayMode"
            description: "当前显示模式"
          - name: "onDestinationSelected"
            type: "ValueChanged<NavigationDestinations>?"
            description: "菜单项选择回调"
        methods:
          - name: "_getDrawerWidth"
            return_type: "double"
            description: "根据显示模式获取抽屉宽度"
        dependencies:
          - "package:flutter/material.dart"
          - "navigation_destinations.dart"
        called_by:
          - "app_shell.dart"
          - "responsive_navigation.dart"
        calls:
          - "package:flutter/material.dart"
          - "navigation_destinations.dart"
```

#### 2.2 测试用例创建计划

```yaml
test_creation:
  unit_tests:
    tests:
      - file: "test/presentation/navigation/drawer_menu_test.dart"
        test_name: "test_drawer_menu_display_modes"
        test_type: "unit_test"
        description: "测试DrawerMenu的三种显示模式"
        based_on: "step文档中drawer_menu.dart的代码实现"
        implementation: |
          void main() {
            group('DrawerMenu', () {
              test('should have correct display modes', () {
                expect(DrawerDisplayMode.values.length, 3);
                expect(DrawerDisplayMode.values, contains(DrawerDisplayMode.hidden));
                expect(DrawerDisplayMode.values, contains(DrawerDisplayMode.iconOnly));
                expect(DrawerDisplayMode.values, contains(DrawerDisplayMode.full));
              });
              
              test('should calculate width correctly', () {
                final drawer = DrawerMenu(displayMode: DrawerDisplayMode.hidden);
                // 测试宽度计算
              });
            });
          }
        expectation: "验证DrawerMenu基本功能正确"
  
  widget_tests:
    tests:
      - file: "test/presentation/navigation/drawer_menu_widget_test.dart"
        test_name: "test_drawer_menu_rendering"
        test_type: "widget_test"
        description: "测试DrawerMenu的UI渲染"
        based_on: "step文档中drawer_menu.dart的代码实现"
        implementation: |
          void main() {
            group('DrawerMenu Widget', () {
              testWidgets('should render hidden mode correctly', (WidgetTester tester) async {
                await tester.pumpWidget(
                  MaterialApp(
                    home: DrawerMenu(
                      displayMode: DrawerDisplayMode.hidden,
                      onDestinationSelected: null,
                    ),
                  ),
                );
                
                expect(find.byType(Drawer), findsOneWidget);
                final drawer = tester.widget<Drawer>(find.byType(Drawer));
                expect(drawer.width, 0);
              });
              
              testWidgets('should render iconOnly mode correctly', (WidgetTester tester) async {
                await tester.pumpWidget(
                  MaterialApp(
                    home: DrawerMenu(
                      displayMode: DrawerDisplayMode.iconOnly,
                      onDestinationSelected: null,
                    ),
                  ),
                );
                
                expect(find.byType(Drawer), findsOneWidget);
                final drawer = tester.widget<Drawer>(find.byType(Drawer));
                expect(drawer.width, 80);
                expect(find.byType(Icon), findsWidgets);
                expect(find.text('Home'), findsNothing);
              });
            });
          }
        expectation: "验证DrawerMenu UI渲染正确"
```

#### 2.3 验证计划

```yaml
verification:
  yaml_consistency:
    steps:
      - step: "验证YAML文件格式"
        method: "检查YAML文件语法"
        expectation: "YAML文件格式正确"
      - step: "验证YAML内容与代码一致"
        method: "对比YAML文件与代码实现"
        expectation: "YAML内容与代码实现一致"
  
  test_execution:
    steps:
      - step: "运行单元测试"
        command: "flutter test test/unit/"
        expectation: "所有单元测试通过"
      - step: "运行组件测试"
        command: "flutter test test/widget/"
        expectation: "所有组件测试通过"
  
  coverage_check:
    steps:
      - step: "生成测试覆盖率报告"
        command: "flutter test --coverage"
        expectation: "覆盖率报告生成成功"
      - step: "检查覆盖率阈值"
        method: "检查覆盖率是否达到80%"
        expectation: "测试覆盖率≥80%"
```

### 3. 执行状态跟踪

#### 状态管理
```yaml
execution_status:
  overall_status: "in_progress"
  current_phase: "yaml_updates"
  completed_phases: []
  
  phases:
    - name: "yaml_updates"
      status: "in_progress"
      tasks:
        - task: "生成新组件YAML文件"
          status: "in_progress"
          retry_count: 0
          failure_reasons: []
    
    - name: "test_creation"
      status: "pending"
      tasks:
        - task: "创建单元测试"
          status: "pending"
          retry_count: 0
          failure_reasons: []
```

#### 重试机制
```yaml
retry_mechanism:
  max_retries: 3
  retry_conditions:
    - "YAML文件格式错误"
    - "测试用例创建失败"
    - "测试执行失败"
    - "覆盖率不达标"
  
  skip_records: []
```

### 4. 质量检查清单

- [ ] 所有YAML文件与代码实现一致
- [ ] 所有测试用例创建完成
- [ ] 所有测试通过
- [ ] 测试覆盖率≥80%
- [ ] YAML文件格式正确
- [ ] 调用关系正确
- [ ] 架构文档更新完成

### 5. 执行流程

1. **YAML更新阶段**：根据代码实现生成/修改规范YAML文件
2. **测试创建阶段**：根据代码实现创建测试用例
3. **验证阶段**：运行测试验证，检查覆盖率
4. **Git提交阶段**：自动处理git提交，包含错误处理和重试机制

### 6. Git提交处理

#### 6.1 时间检查机制
```yaml
git_commit_handling:
  time_check:
    threshold: "30分钟"
    logic: |
      if (当前时间 - 上次提交时间) < 30分钟:
        执行pre_commit_check()
      else:
        执行direct_commit()
```

#### 6.2 错误处理和重试
```yaml
error_handling:
  max_retries: 5
  log_directory: "documents/plan-logs"
  log_format: "json"
  log_fields:
    - "timestamp": "错误发生时间"
    - "error_content": "报错内容"
    - "estimated_cause": "估计原因"
    - "solution_attempted": "解决方式"
    - "failure_manifestation": "失败表现"
    - "excluded_possibilities": "排除可能"
    - "retry_count": "重试次数"
```

#### 6.3 自动退出条件
- 重试次数达到5次
- 连续3次相同错误
- 严重系统错误

### 7. 注意事项

1. **基于 step 文档**：所有YAML和测试创建必须基于 step 文档中的代码实现
2. **代码实现确认**：确保代码实现已完成且用户手工测试通过
3. **YAML一致性**：确保YAML文件与代码实现完全一致
4. **测试完整性**：确保测试用例覆盖所有功能
5. **状态跟踪完整**：实时更新执行状态，记录每个环节的进展
6. **重试机制完善**：每个任务最多重试3次，记录详细的问题分析
7. **Git提交自动化**：自动处理git提交，包含时间检查和错误处理
8. **错误日志记录**：所有错误都记录到plan-logs目录，便于问题排查