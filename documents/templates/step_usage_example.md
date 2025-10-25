# Step 模板使用示例

## 如何使用 step_template.yaml

### 1. 基本使用流程

1. **基于 preview 生成**：将 `step_template.yaml` 复制到 `documents/plan/` 目录
2. **重命名文件**：按照 `YYMMDD-N-step.yaml` 格式命名
3. **基于 preview 填写**：根据对应的 preview 文档填写代码实现计划
4. **执行跟踪**：按照 execution_tracking 进行状态管理
5. **用户测试**：代码实现完成后等待用户手工测试
6. **step-done**：用户测试通过后执行 step-done 补充 YAML 和测试

### 2. 核心字段详解

#### 2.1 实现计划（基于preview文档）

```yaml
implementation_plan:
  new_files:
    files:
      - file: "lib/presentation/navigation/drawer_menu.dart"
        based_on: "preview中new_files的drawer_menu.dart设计"
        class_name: "DrawerMenu"
        type: "StatelessWidget"
        description: "增强抽屉菜单组件，支持三种显示模式"
        implementation: |
          enum DrawerDisplayMode {
            hidden,
            iconOnly,
            full,
          }
          
          class DrawerMenu extends StatelessWidget {
            const DrawerMenu({
              super.key,
              required this.displayMode,
              this.onDestinationSelected,
              this.onClose,
            });
            
            final DrawerDisplayMode displayMode;
            final ValueChanged<NavigationDestinations>? onDestinationSelected;
            final VoidCallback? onClose;
            
            @override
            Widget build(BuildContext context) {
              return Drawer(
                width: _getDrawerWidth(),
                child: Column(
                  children: [
                    if (displayMode == DrawerDisplayMode.full)
                      const DrawerHeader(
                        decoration: BoxDecoration(color: Colors.blue),
                        child: Text('GranoFlow'),
                      ),
                    Expanded(
                      child: ListView(
                        children: NavigationDestinations.values.map((destination) {
                          return ListTile(
                            leading: Icon(destination.icon),
                            title: displayMode == DrawerDisplayMode.full 
                              ? Text(destination.label(context))
                              : null,
                            onTap: () {
                              onDestinationSelected?.call(destination);
                              onClose?.call();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            double _getDrawerWidth() {
              switch (displayMode) {
                case DrawerDisplayMode.hidden:
                  return 0;
                case DrawerDisplayMode.iconOnly:
                  return 80;
                case DrawerDisplayMode.full:
                  return 280;
              }
            }
          }
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

#### 2.2 代码变更内容

```yaml
code_changes:
  new_files:
    - file: "lib/presentation/navigation/drawer_menu.dart"
      action: "create"
      based_on: "preview中new_files的drawer_menu.dart设计"
      content: |
        // 基于preview设计的完整代码实现
        // 包含DrawerDisplayMode枚举和DrawerMenu类
        // 支持三种显示模式：hidden/iconOnly/full
        // 动态宽度和条件内容显示
```

#### 2.3 验证计划

```yaml
verification_plan:
  compilation_check:
    steps:
      - step: "运行flutter analyze"
        command: "flutter analyze"
        expectation: "无错误和警告"
      - step: "运行flutter pub get"
        command: "flutter pub get"
        expectation: "依赖包安装成功"
  
  basic_functionality:
    steps:
      - step: "验证新文件创建"
        method: "检查文件是否存在且内容正确"
        expectation: "DrawerMenu文件按preview设计创建"
      - step: "验证枚举定义"
        method: "检查DrawerDisplayMode枚举"
        expectation: "枚举包含hidden/iconOnly/full三个值"
      - step: "验证类实现"
        method: "检查DrawerMenu类实现"
        expectation: "类包含所有必需的属性和方法"
```

### 3. 执行状态跟踪

#### 状态管理
```yaml
execution_status:
  overall_status: "in_progress"
  current_phase: "implementation"
  completed_phases: ["analysis"]
  
  phases:
    - name: "analysis"
      status: "completed"
      tasks:
        - task: "分析preview文档需求"
          status: "completed"
          retry_count: 0
          failure_reasons: []
    
    - name: "implementation"
      status: "in_progress"
      tasks:
        - task: "创建新文件"
          status: "in_progress"
          retry_count: 0
          failure_reasons: []
```

#### 重试机制
```yaml
retry_mechanism:
  max_retries: 3
  retry_conditions:
    - "编译错误"
    - "语法错误"
    - "依赖包问题"
    - "文件创建失败"
  
  skip_records: []
```

### 4. 质量检查清单

- [ ] 所有新文件基于 preview 设计创建
- [ ] 所有现有文件基于 preview 设计修改
- [ ] 代码编译无错误
- [ ] 基本功能验证通过
- [ ] 集成检查通过
- [ ] 文件间调用关系正确
- [ ] 依赖关系正确建立

### 5. 执行流程

1. **分析阶段**：分析 preview 文档需求，确定实现文件列表
2. **实现阶段**：创建新文件和修改现有文件
3. **验证阶段**：编译检查、基本功能验证、集成检查
4. **用户测试**：等待用户手工测试
5. **step-done**：用户测试通过后执行 step-done 补充 YAML 和测试

### 6. 注意事项

1. **基于 preview 设计**：所有代码实现必须严格按照 preview 文档设计
2. **不包含 YAML 和测试**：step 专注于代码实现，不涉及规范文件和测试
3. **用户测试确认**：代码实现完成后必须等待用户手工测试
4. **step-done 补充**：用户测试通过后执行 step-done 才补充 YAML 和测试
5. **状态跟踪完整**：实时更新执行状态，记录每个环节的进展
6. **重试机制完善**：每个任务最多重试3次，记录详细的问题分析