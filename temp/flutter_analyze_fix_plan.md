# Flutter Analyze 错误修复计划

## 目标
系统化修复所有 `flutter analyze` 发现的错误，通过迭代循环逐步减少 issues 数量，直到所有适合用脚本修复的问题全部解决。

## 工作流程

### 阶段 0：初始状态记录
1. 运行 `dart analyze --format=json`，统计当前 issues：
   - ERROR 数量
   - WARNING 数量  
   - INFO 数量
   - 按错误代码（code）分组统计
2. 强制 git commit（跳过 pre-commit）记录当前状态
   ```bash
   git commit --no-verify -m "chore: record initial analyze state - X errors, Y warnings, Z info"
   ```

### 阶段 1-N：AI 控制的迭代修复循环

**重要：每次循环只处理一种错误类型，由 AI 控制循环流程**

每个循环包含以下步骤：

#### 步骤 1：AI 运行 analyze 并分析当前状态
```bash
# AI 执行：运行 analyze 并保存结果
dart analyze --format=json > .tmp/analyze_before.json

# AI 执行：统计 issues
python3 scripts/anz_modules/fix/analyze_stats.py .tmp/analyze_before.json
```

**AI 分析输出：**
```
[analyze:stats] Current issues:
  ERROR: 45
  WARNING: 12
  INFO: 8
  Total: 65

[analyze:stats] Top error codes:
  1. invalid_override: 18 (integration_test/)
  2. argument_type_not_assignable: 15 (integration_test/, test/)
  3. uri_does_not_exist: 8 (integration_test/, lib/)
  4. undefined_function: 4 (lib/core/providers/)
  ...
```

#### 步骤 2：AI 选择目标错误类型并分析
- **AI 决策**：选择出现次数最多的错误代码（优先 ERROR，其次 WARNING）
- **AI 分析**：查看具体错误示例，理解错误模式
- **AI 判断**：是否适合脚本修复？修复范围是什么？

#### 步骤 3：AI 编写/增强修复脚本
**AI 在 `scripts/anz_modules/fix/fixers/` 中创建或修改修复器：**

**修复器要求：**
1. **自动发现目标文件**：根据 analyze 结果自动识别需要修复的文件（已在 `issues.py` 中实现）
2. **严格限制范围**：通过文件路径模式（predicate 函数）限制修复范围
3. **可测试性**：修复逻辑应该可以独立测试
4. **可回滚性**：修复前自动备份，失败时自动恢复（已在 `issues.py` 中实现）

**修复器模板：**
```python
# fixers/xxx_fixer.py
def apply_xxx_fix(path: Path, diagnostics: List[Diagnostic]) -> bool:
    """修复 xxx 类型错误"""
    # 1. 检查文件是否在修复范围内
    if not _should_fix(path):
        return False
    
    # 2. 读取文件内容
    content = path.read_text(encoding="utf-8")
    original = content
    
    # 3. 根据 diagnostics 定位问题并修复
    # ...
    
    # 4. 写入修复后的内容
    if content != original:
        path.write_text(content, encoding="utf-8")
        return True
    return False

def _should_fix(path: Path) -> bool:
    """判断文件是否在修复范围内"""
    # 严格限制修复范围
    # 例如：只修复 integration_test/ 下的特定文件
    return ...
```

**AI 在 `issues.py` 中注册修复器：**
```python
FIXERS: Dict[str, tuple[Fixer, Callable[[Path], bool]]] = {
    # ... 现有修复器
    "xxx_error_code": (apply_xxx_fix, _should_fix_xxx),
}
```

#### 步骤 4：AI 执行修复脚本（只执行一次）
```bash
# AI 执行：运行修复脚本（只修复当前目标错误类型）
python3 scripts/anz_modules/fix/issues.py

# 脚本内部流程（自动）：
# 1. 自动运行 dart analyze --format=json
# 2. 识别目标错误类型的所有文件（通过 FIXERS 注册的修复器）
# 3. 对每个文件执行修复（带备份）
# 4. 运行 dart format 格式化修改的文件
# 5. 再次运行 dart analyze --format=json
# 6. 比对修复前后的结果，生成报告
```

**修复报告示例：**
```
[anz:fix] Fixing 'invalid_override' issues...
[anz:fix] Found 18 issues in 5 files
[anz:fix] Applying fixes...
  - integration_test/clock_wave_layout_test.dart: 8 fixes
  - integration_test/fixtures/task_test_data.dart: 5 fixes
  - integration_test/helpers/task_drag_test_helper.dart: 3 fixes
  - integration_test/helpers/task_section_test_helper.dart: 2 fixes
[anz:fix] Running dart format...
[anz:fix] Verifying fixes...
[anz:fix] Results:
  ✅ Fixed: 18 issues resolved
  ❌ Remaining: 0 issues still present
  ⚠️  New: 0 new issues introduced
[anz:fix] Successfully fixed 5 files
```

#### 步骤 5：AI 评估修复结果并决策
**AI 根据修复报告判断：**

**情况 A：修复成功（所有目标错误已解决，无新错误）**
- ✅ **AI 决策**：继续下一轮循环
- **AI 执行**：步骤 6（git commit），然后返回步骤 1

**情况 B：部分修复（部分错误已解决，但仍有残留）**
- ⚠️ **AI 分析**：查看残留错误的具体位置和原因
- **AI 决策**：
  - 如果修复逻辑不完善 → 增强修复器，返回步骤 3
  - 如果错误类型不适合脚本修复 → 标记为"需要手动修复"，返回步骤 1（选择下一个错误类型）

**情况 C：修复失败（错误未解决或引入新错误）**
- ❌ **AI 分析**：查看修复输出和错误详情
- **AI 决策**：
  - 修复逻辑错误 → 重写修复器，返回步骤 3
  - 文件范围判断错误 → 调整 predicate 函数，返回步骤 3
  - 错误类型不适合脚本修复 → 标记为"需要手动修复"，返回步骤 1
- **AI 执行**：如果需要回滚，执行 `git checkout` 恢复文件

#### 步骤 6：AI 提交修复结果
```bash
# AI 执行：强制提交（跳过 pre-commit）
git add -A
git commit --no-verify -m "fix: auto-fix xxx_error_code issues (X files, Y issues resolved)"
```

#### 步骤 7：AI 决定是否继续
- **AI 判断**：如果还有适合脚本修复的错误类型 → 返回步骤 1
- **AI 判断**：如果所有适合脚本修复的错误都已处理 → 进入阶段 2

### 阶段 2：手动修复剩余问题
对于不适合脚本修复的问题：
1. 列出所有剩余问题
2. 逐个手动修复
3. 每修复一批后运行 analyze 验证
4. 提交修复结果

## 错误类型修复状态

### ✅ 已实现修复器
- `unused_import`: 删除未使用的导入
- `uri_does_not_exist`: 删除或重映射不存在的 URI 导入
- `undefined_class`, `non_type_as_type_argument`, `undefined_identifier`: ObjectBox repository 导入修复
- `map_key_type_not_assignable`, `set_element_type_not_assignable`, `invalid_assignment`: 测试文件 ID 类型修复（部分）

### ⚠️ 需要改进的修复器
- `invalid_override`: 已实现基础版本，但只修复参数声明，未处理调用处。需要同时修改：
  - 方法参数类型声明（int → String）
  - 方法调用处的参数值（int 字面量/变量 → String）

### ❌ 需要手动修复或更复杂修复器的错误类型
- `argument_type_not_assignable` (281 个): 需要同时修改：
  - 参数类型声明
  - 调用处的参数值（包括表达式如 `startId + i` 需要转换为 `(startId + i).toString()`）
  - 可能需要 AST 分析或更精确的模式匹配

### ❌ 需要手动修复或更复杂修复器的错误类型（续）
- `undefined_named_parameter` (101 个): 参数名变更相关。已实现基础版本，但：
  - 需要处理参数已存在的情况（删除而不是重命名）
  - 需要更智能的上下文分析
  - 修复后可能引入类型错误

### 🔄 待处理的错误类型
- `return_of_invalid_type_from_closure` (72 个): 闭包返回类型问题
- `undefined_getter` (44 个): 属性访问问题
- `uri_does_not_exist` (4 个): 已大幅减少，现有修复器有效
- 其他较小的错误类型

## 辅助工具脚本

### 1. analyze_stats.py
统计 analyze 结果，输出错误分类和统计信息。

```python
# scripts/anz_modules/fix/analyze_stats.py
"""
统计 dart analyze 结果，输出错误分类和统计信息。
"""
```

### 2. 增强 issues.py
在现有 `issues.py` 基础上增强：

1. **自动发现目标错误类型**：
   - 运行 analyze 后自动统计错误代码
   - 按出现次数排序
   - 提示用户选择要修复的错误类型

2. **修复前后对比**：
   - 保存修复前的 analyze 结果
   - 修复后再次运行 analyze
   - 生成详细的对比报告

3. **智能回滚**：
   - 如果修复后错误数量增加，自动回滚
   - 如果修复后仍有残留，生成详细报告供 AI 分析

## 实施步骤

### 第一步：创建辅助脚本
- [ ] 创建 `scripts/anz_modules/fix/analyze_stats.py`
- [ ] 增强 `scripts/anz_modules/fix/issues.py` 的修复前后对比功能

### 第二步：执行初始状态记录
- [ ] 运行 `dart analyze --format=json` 并保存结果
- [ ] 运行统计脚本，记录初始状态
- [ ] 强制 git commit 记录初始状态

### 第三步：开始迭代修复循环
- [ ] 循环执行阶段 1-N 的步骤
- [ ] 每次修复后提交结果
- [ ] 直到所有适合脚本修复的问题都解决

### 第四步：处理剩余问题
- [ ] 列出所有剩余问题
- [ ] 手动修复或标记为已知问题

## 注意事项

1. **严格限制修复范围**：每个修复器必须有明确的文件范围限制，避免误修复
2. **保持备份**：所有修复前都要备份，失败时自动恢复
3. **验证修复效果**：每次修复后都要重新运行 analyze 验证
4. **渐进式修复**：一次只修复一种错误类型，避免引入新问题
5. **记录修复历史**：每次修复都要 git commit，方便追踪和回滚

## 预期成果

- 所有适合脚本修复的 analyze 错误都被自动修复
- 修复过程可追溯（通过 git commit 历史）
- 修复脚本可复用（未来遇到类似错误可以快速修复）
- 代码质量提升（减少 analyze 错误数量）
