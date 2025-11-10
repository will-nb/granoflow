# `argument_type_not_assignable` 修复逻辑复用性分析

## 当前错误的本质

从错误信息看，`argument_type_not_assignable` 错误主要是：
- `int` 类型不能赋值给 `String` 类型参数
- `String` 类型不能赋值给 `int?` 类型参数
- 这是 **Isar -> ObjectBox 迁移** 导致的 ID 类型变更（`int` -> `String`）

## 复用性评估

### ❌ **当前修复逻辑：高度特定于项目**

**原因：**
1. **硬编码的类型映射**：`int` -> `String` 是硬编码的
2. **硬编码的参数名模式**：`taskId`, `parentId`, `projectId` 等是特定于这个项目的
3. **特定的迁移场景**：Isar -> ObjectBox 迁移是特定场景

**示例代码（当前修复器）：**
```python
# 硬编码的 ID 参数模式
ID_PARAM_PATTERN = re.compile(
    r"\b(required\s+)?int(\?)?\s+((task|session|parent|project|milestone|focus)[Ii]d|id|parentTaskId|transferToTaskId)\b"
)

# 硬编码的类型转换
def _fix_id_parameter_type(match: re.Match[str]) -> str:
    # 直接转换为 String
    return f"{prefix}String{suffix} {param_name}"
```

### ✅ **修复框架和思路：可以复用**

**可复用的部分：**
1. **修复框架**（`scripts/anz_modules/fix/issues.py`）：
   - 运行 `dart analyze --format=json`
   - 解析诊断信息
   - 按文件分组
   - 应用修复器
   - 验证修复结果
   - 生成报告

2. **修复器架构**：
   - 每个修复器是独立的模块
   - 统一的接口：`apply_xxx_fix(path: Path, diagnostics: List[Diagnostic]) -> bool`
   - 支持条件过滤（哪些文件需要修复）

3. **修复思路**：
   - 从错误信息中提取关键信息（类型、参数名、位置）
   - 使用正则表达式或 AST 分析代码
   - 应用类型转换规则
   - 验证修复结果

### 🔄 **如果要通用化，需要做的抽象**

#### 1. **可配置的类型映射规则**

```yaml
# fix_rules.yaml
type_mappings:
  - from: int
    to: String
    context: id_parameters  # 只在 ID 参数中应用
    parameter_patterns:
      - taskId
      - parentId
      - projectId
      - milestoneId
      - sessionId
      - focusId
      - id
```

#### 2. **可配置的转换策略**

```yaml
conversion_strategies:
  literal_int_to_string:
    pattern: \d+
    replacement: "'{match}'"
  
  variable_to_string:
    pattern: \w+
    replacement: "{match}.toString()"
  
  expression_to_string:
    pattern: .+
    replacement: "({match}).toString()"
```

#### 3. **上下文感知的修复**

```python
class TypeMigrationFixer:
    def __init__(self, config: Dict):
        self.type_mappings = config['type_mappings']
        self.conversion_strategies = config['conversion_strategies']
        self.parameter_patterns = config['parameter_patterns']
    
    def should_fix(self, diagnostic: Diagnostic) -> bool:
        # 根据配置判断是否需要修复
        pass
    
    def fix(self, code: str, diagnostic: Diagnostic) -> str:
        # 根据配置应用修复规则
        pass
```

#### 4. **AST 分析支持**

对于复杂情况（表达式、嵌套调用等），需要 AST 分析：

```python
import dart_ast  # 假设的 Dart AST 库

def fix_with_ast(code: str, diagnostic: Diagnostic) -> str:
    tree = dart_ast.parse(code)
    # 使用 AST 精确找到需要修复的位置
    # 应用类型转换
    return dart_ast.unparse(tree)
```

## 结论

### 当前状态
- ❌ **修复逻辑本身**：**不能直接复用**，高度特定于 Isar -> ObjectBox 迁移
- ✅ **修复框架**：**可以复用**，适用于任何 Flutter 项目的错误修复
- ✅ **修复思路**：**可以复用**，但需要根据具体场景调整

### 通用化建议

如果要让修复逻辑在其他 Flutter 项目中复用，需要：

1. **抽象配置层**：
   - 将类型映射、参数模式、转换策略提取到配置文件
   - 支持多种迁移场景（不仅仅是 int -> String）

2. **增强代码分析能力**：
   - 使用 AST 分析而不是简单的正则表达式
   - 支持更复杂的表达式和上下文

3. **模块化设计**：
   - 将修复逻辑拆分为可组合的模块
   - 每个模块处理一种特定的转换场景

4. **测试覆盖**：
   - 为通用修复器编写测试用例
   - 覆盖各种边界情况

### 实际建议

**对于当前项目：**
- 继续使用项目特定的修复逻辑
- 专注于修复当前迁移场景的错误

**对于未来项目：**
- 如果遇到类似的类型迁移场景，可以：
  1. 复用修复框架（`issues.py`）
  2. 参考当前修复器的实现思路
  3. 根据新项目的具体情况调整规则和模式
  4. 考虑使用 AST 分析处理复杂情况

**通用化优先级：**
- 🔴 **高优先级**：修复框架（已实现，可直接复用）
- 🟡 **中优先级**：修复器架构和接口（已实现，需要小调整）
- 🟢 **低优先级**：通用类型迁移修复器（需要大量抽象工作，ROI 较低）
