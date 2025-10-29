# YAML 一致性测试

## 📋 测试目的

这些测试用于检测 `documents/architecture/` 下的 YAML 文档与实际代码之间的不一致。

## ⚠️ 重要：AI 行为规范

当这些测试失败时，**AI 应该**：

✅ **明确报告**哪些地方不一致  
✅ **列出** YAML 中的定义 vs 代码中的实际情况  
✅ **退出**并等待人工判断  

**AI 不应该**：

❌ 直接修改代码使其符合 YAML  
❌ 直接修改 YAML 使其符合代码  
❌ 猜测哪一边是"正确"的  

### 原因

AI 很难确定是 YAML 过时了还是代码写错了，需要人工判断正确的源头。

## 🧪 测试文件

### 1. `schema_validation_test.dart`
校验 YAML 是否符合模板规范：
- 检查必填字段存在（`meta.name`, `meta.file_path`, `meta.type` 等）
- 检查字段类型正确
- 检查 `schema_version` 有效
- 检查特定类型的必填字段（如 Provider 的 `notifier_type`）

### 2. `field_completeness_test.dart`
校验 YAML 字段的完整性：
- `i18n_keys` 中的键存在于 `.arb` 文件
- `design_tokens` 中的令牌存在于 `lib/core/theme/` 文件
- `test_mapping` 指向的测试文件存在
- `source_of_truth` 路径有效

### 3. `reference_consistency_test.dart`
校验跨文件引用的一致性：
- `called_by` 和 `calls` 的双向引用一致
- `calls` 指向的文件存在对应的 YAML
- `supersedes` 指向的文件存在
- 避免循环依赖

### 4. `code_sync_test.dart`
校验 YAML 与实际代码的同步：
- `meta.file_path` 指向的 Dart 文件存在
- Dart 文件中的类名与 `meta.name` 一致
- Dart 文件的类型与 YAML `type` 一致

## 🚀 运行测试

### 运行所有 YAML 测试
```bash
flutter test test/yaml/
```

### 运行单个测试文件
```bash
flutter test test/yaml/schema_validation_test.dart
flutter test test/yaml/field_completeness_test.dart
flutter test test/yaml/reference_consistency_test.dart
flutter test test/yaml/code_sync_test.dart
```

### 在 CI 中运行（pre-push）
这些测试会在 `pre-push` hook 中自动运行。

## 🔧 测试失败时的处理流程

1. **阅读失败消息**：每个失败消息都会详细说明不一致的地方
2. **人工判断**：确定是代码错了还是 YAML 过时了
3. **修复源头**：
   - 如果代码错了 → 修复代码
   - 如果 YAML 过时了 → 运行 `scripts/anz yaml:create --from <dart_file>` 更新 YAML
   - 如果两者都有问题 → 分别修复
4. **重新运行测试**：确保修复正确

## 📂 YAML 文档范围

仅为以下六种核心类型生成和维护 YAML 文档：

1. **Models** (`documents/architecture/models/`)
2. **Pages** (`documents/architecture/pages/`)
3. **Widgets** (`documents/architecture/widgets/`)
4. **Providers** (`documents/architecture/providers/`)
5. **Repositories** (`documents/architecture/repositories/`)
6. **Services** (`documents/architecture/services/`)

特殊情况：
- `routers.yaml` 作为路由地图保留

不生成 YAML 的类型：
- Constants、Config、Theme、Enums
- Utils、Helpers、Extensions
- generated/ 下的代码

## 🛠️ 工具集成

### 本地验证
```bash
# 在 pre-commit 中运行（快速检查）
flutter test test/yaml/schema_validation_test.dart

# 在 pre-push 中运行（完整检查）
flutter test test/yaml/
```

### Python Linter
`scripts/anz_modules/architecture/architecture_linter.py` 提供了额外的验证：
- YAML 语法检查
- 必填字段验证
- 路径有效性检查

```bash
python scripts/anz_modules/architecture/architecture_linter.py documents/architecture/
```

### 快速运行
```bash
scripts/anz yaml:test
scripts/anz yaml:test --schema
scripts/anz yaml:test --sync -v
```

### 重新生成 YAML
如果发现 YAML 大量过时，可以批量重新生成：

```bash
# 重新生成所有 YAML（会备份现有文件）
scripts/anz yaml:create:all

# 重新生成单个 YAML
scripts/anz yaml:create --from lib/presentation/widgets/modern_tag.dart
```

## 📊 测试输出示例

### 成功情况
```
═════════════════════════════════════════════════════════════════════
⚠️  YAML 一致性测试
═════════════════════════════════════════════════════════════════════

📋 测试目的：检测 YAML 文档与代码的不一致

🤖 AI 行为规范：
   如果测试失败，AI 应该：
   ✅ 明确报告哪些地方不一致
   ✅ 列出 YAML 定义 vs 代码实际情况
   ✅ 退出并等待人工判断

   AI 不应该：
   ❌ 直接修改代码使其符合 YAML
   ❌ 直接修改 YAML 使其符合代码
   ❌ 猜测哪一边是"正确"的

💡 原因：
   AI 很难确定是 YAML 过时了还是代码写错了
   需要人工判断正确的源头

═════════════════════════════════════════════════════════════════════

✅ All tests passed!
```

### 失败情况
```
❌ modern_tag.yaml 的类名与代码不一致
   YAML 中的类名: ModernTag
   代码文件: lib/presentation/widgets/modern_tag.dart
   
   在代码中未找到 "class ModernTag"
   
   这可能意味着:
   1. 类被重命名了，YAML 未更新
   2. YAML 中的类名拼写错误
   3. 代码文件内容已完全改变
   
   👉 AI 不要修改！请人工判断：
      - 代码中的正确类名是什么？
      - YAML 是否需要更新？
      - 这个 YAML 是否应该重新生成？
```

## 🔄 维护指南

### 添加新的测试检查
在相应的测试文件中添加新的 `test()` 块，确保：
- 在 `setUpAll` 中调用 `YamlTestUtils.printTestWarning()`
- 失败消息包含详细的诊断信息
- 失败消息提醒 AI 不要自动修改

### 更新测试工具
修改 `helpers/yaml_test_utils.dart` 来添加通用的辅助函数。

## 📚 相关文档

- [13-plan-workflow.mdc](../../documents/project/13-plan-workflow.mdc) - YAML 文档工作流
- [architecture_linter.py](../../scripts/anz_modules/architecture/architecture_linter.py) - Python 验证脚本
- [anz yaml:create](../../scripts/anz) - YAML 生成命令

## 🤝 贡献指南

1. 在添加新代码前，确保相关的 YAML 文档存在且正确
2. 重构代码后，运行 `scripts/anz yaml:create --from <file>` 更新 YAML
3. 提交前运行 `flutter test test/yaml/` 确保一致性
4. 如果测试失败，先判断根因再修复，不要盲目修改

## 📞 故障排除

### 测试运行失败
```bash
# 检查 Flutter 环境
flutter doctor

# 清理并重新获取依赖
flutter clean
flutter pub get

# 再次运行测试
flutter test test/yaml/
```

### 大量 YAML 过时
```bash
# 备份并重新生成所有 YAML
scripts/anz yaml:create:all

# 检查生成结果
flutter test test/yaml/
```

### Python Linter 报错
```bash
# 检查 Python 环境
python --version

# 安装依赖
pip install pyyaml

# 运行 linter
python scripts/anz_modules/architecture/architecture_linter.py documents/architecture/
```
