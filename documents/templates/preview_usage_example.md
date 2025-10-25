# Preview 模板使用示例

## 如何使用 preview_template.yaml

### 1. 基本使用流程

1. **复制模板**：将 `preview_template.yaml` 复制到 `documents/plan/` 目录
2. **重命名文件**：按照 `YYMMDD-N-preview.yaml` 格式命名
3. **填写内容**：根据实际需求填写所有必需字段
4. **验证完整性**：确保所有字段都已正确填写

### 2. 关键字段填写指南

#### meta 部分
```yaml
meta:
  version: 1
  type: preview
  iteration: "251025-1"  # 当前日期-序号
  generated_at: "2025-01-25 14:30:00"  # 当前时间
```

#### summary 部分
```yaml
summary:
  objective: "明确描述本次重构/开发的目标"
  requirements: 
    - "需求1: 具体描述"
    - "需求2: 具体描述"
```

#### new_files 部分
每个新建文件必须包含：
- 完整的属性定义
- 子组件结构
- 方法定义
- 依赖关系
- **调用关系**（`called_by` 和 `calls`）

#### modified_files 部分
每个修改文件必须包含：
- 当前结构 vs 新结构对比
- 属性变更详情
- 实现变更说明
- **调用关系**（`called_by` 和 `calls`）

### 3. 调用关系填写规范

#### called_by 字段
列出所有调用此文件的文件路径：
```yaml
called_by:
  - "lib/presentation/navigation/app_shell.dart"
  - "lib/presentation/navigation/responsive_navigation.dart"
```

#### calls 字段
列出此文件调用的所有文件路径：
```yaml
calls:
  - "package:flutter/material.dart"
  - "lib/presentation/navigation/navigation_destinations.dart"
  - "lib/core/providers/app_providers.dart"
```

### 4. 质量检查清单

- [ ] 所有 `new_files` 都包含完整的 `called_by` 和 `calls` 字段
- [ ] 所有 `modified_files` 都包含完整的 `called_by` 和 `calls` 字段
- [ ] 调用关系准确反映文件间的实际依赖
- [ ] 所有必需字段都已填写，没有留空
- [ ] 文档结构完整，可以作为设计稿使用

### 5. 常见错误避免

❌ **错误示例**：
```yaml
# 缺少调用关系字段
- file: "lib/presentation/navigation/drawer_menu.dart"
  type: "StatelessWidget"
  class_name: "DrawerMenu"
  # 缺少 called_by 和 calls 字段
```

✅ **正确示例**：
```yaml
- file: "lib/presentation/navigation/drawer_menu.dart"
  type: "StatelessWidget"
  class_name: "DrawerMenu"
  # ... 其他字段 ...
  called_by:
    - "lib/presentation/navigation/app_shell.dart"
  calls:
    - "package:flutter/material.dart"
    - "lib/presentation/navigation/navigation_destinations.dart"
```