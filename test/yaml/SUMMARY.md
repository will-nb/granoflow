# YAML 一致性测试系统总结

## 📊 完成情况

✅ **已完成**：创建了全新的 YAML 一致性测试系统

## 🎯 核心原则

### AI 行为规范（最重要）

当这些测试失败时，**AI 必须**：

1. ✅ **明确报告**哪些地方不一致
2. ✅ **列出对比** YAML 中的定义 vs 代码中的实际情况
3. ✅ **退出并等待人工判断**

**AI 绝对不能**：

1. ❌ 直接修改代码使其符合 YAML
2. ❌ 直接修改 YAML 使其符合代码
3. ❌ 猜测哪一边是"正确"的

### 原因

AI 无法判断是 YAML 过时了还是代码写错了，这需要人工确定真正的"源头"。

## 📁 文件结构

```
test/yaml/
├── README.md                         # 详细文档
├── SUMMARY.md                        # 本文件
├── helpers/
│   └── yaml_test_utils.dart         # 通用工具函数
├── schema_validation_test.dart      # Schema 验证
├── field_completeness_test.dart     # 字段完整性
├── reference_consistency_test.dart  # 引用一致性
└── code_sync_test.dart              # 代码同步
```

## 🧪 测试类型

### 1. Schema 验证测试 (`schema_validation_test.dart`)
- ✅ 检查必填字段存在（`meta.name`, `meta.file_path`, `meta.type`）
- ✅ 检查 `schema_version` 有效
- ✅ 检查 `file_path` 指向存在的文件
- ✅ 特殊检查 `routers.yaml` 存在

### 2. 字段完整性测试 (`field_completeness_test.dart`)
- ✅ `i18n_keys` 中的键存在于 `.arb` 文件
- ✅ `design_tokens` 中的令牌存在于 `lib/core/theme/` 文件
- ✅ `source_of_truth` 路径有效

### 3. 引用一致性测试 (`reference_consistency_test.dart`)
- ✅ `calls` 指向的文件存在
- ✅ `supersedes` 指向的 YAML 存在（如果非空）
- ✅ 避免循环依赖

### 4. 代码同步测试 (`code_sync_test.dart`)
- ✅ `meta.file_path` 指向存在的 Dart 文件
- ✅ Dart 文件中的类名与 `meta.name` 一致
- ✅ YAML `type` 与目录分类匹配

## 🚀 使用方法

### 运行所有测试
```bash
# 使用脚本
./scripts/run_yaml_tests.sh

# 使用 Flutter 命令
flutter test test/yaml/
```

### 运行特定测试
```bash
# Schema 验证
./scripts/run_yaml_tests.sh --schema

# 字段完整性
./scripts/run_yaml_tests.sh --fields

# 引用一致性
./scripts/run_yaml_tests.sh --refs

# 代码同步
./scripts/run_yaml_tests.sh --sync

# 详细模式
./scripts/run_yaml_tests.sh --sync -v
```

### 在 Git Hooks 中自动运行
- **pre-push**: 自动运行完整的 YAML 一致性测试

## 🔧 测试失败处理流程

1. **阅读失败消息**
   - 每个失败消息都包含详细的诊断信息
   - 明确指出 YAML 中的值和期望值

2. **人工判断根因**
   - 是代码被修改了，YAML 未更新？
   - 还是 YAML 记录错误，代码是对的？
   - 或者两者都有问题？

3. **修复源头**
   - 如果代码错了 → 修复代码
   - 如果 YAML 过时了 → 运行 `scripts/anz yaml:create --from <dart_file>`
   - 如果两者都有问题 → 分别修复

4. **重新运行测试**
   ```bash
   ./scripts/run_yaml_tests.sh
   ```

## 📊 覆盖范围

### 测试的 YAML 文档类型
仅测试六种核心类型：
1. **Models** (`documents/architecture/models/`)
2. **Pages** (`documents/architecture/pages/`)
3. **Widgets** (`documents/architecture/widgets/`)
4. **Providers** (`documents/architecture/providers/`)
5. **Repositories** (`documents/architecture/repositories/`)
6. **Services** (`documents/architecture/services/`)

特殊情况：
- `routers.yaml` 作为路由地图保留

### 不测试的类型
- Constants、Config、Theme、Enums
- Utils、Helpers、Extensions
- `generated/` 下的代码

## 🗑️ 已删除的旧测试

为确保测试一致性，已删除以下旧测试文件：

### 已删除的文件（共 14 个）
1. `test/documentation/models_yaml_test.dart`
2. `test/documentation/pages_yaml_test.dart`
3. `test/documentation/widgets_yaml_test.dart`
4. `test/documentation/providers_yaml_test.dart`
5. `test/documentation/repositories_yaml_test.dart`
6. `test/documentation/services_yaml_test.dart`
7. `test/documentation/yaml_integrity_test.dart`
8. `test/documentation/yaml_test_helper.dart`
9. `test/data/repositories/task_repository_yaml_consistency_test.dart`
10. `test/data/repositories/task_id_generation_consistency_test.dart`
11. `test/presentation/inbox/inbox_yaml_consistency_test.dart`
12. `test/presentation/inbox/inbox_core_consistency_test.dart`
13. `test/yaml_test_config.yaml`
14. `test/run_yaml_tests.dart`
15. `test/README_YAML_TESTS.md`
16. `test/YAML_TESTING_SUMMARY.md`

## 🎨 测试输出特色

### 警告横幅
每个测试文件运行时都会显示：
```
══════════════════════════════════════════════════════════════════════
⚠️  YAML 一致性测试
══════════════════════════════════════════════════════════════════════

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

══════════════════════════════════════════════════════════════════════
```

### 详细的失败消息
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

## 🔗 相关文档

- [test/yaml/README.md](README.md) - 完整的测试文档
- [scripts/run_yaml_tests.sh](../../scripts/run_yaml_tests.sh) - 测试运行脚本
- [scripts/architecture_linter.py](../../scripts/architecture_linter.py) - Python Linter
- [documents/project/13-plan-workflow.mdc](../../documents/project/13-plan-workflow.mdc) - 工作流文档

## 📈 统计信息

- **测试文件数**: 4 个核心测试文件
- **工具文件数**: 1 个（`yaml_test_utils.dart`）
- **覆盖的 YAML 类型**: 6 种核心类型 + `routers.yaml`
- **删除的旧测试**: 16 个文件
- **新增的脚本**: 1 个（`run_yaml_tests.sh`）

## 🎯 设计目标

1. **防止 AI 幻觉**: 通过明确的警告和失败消息，阻止 AI 自行修改
2. **清晰的错误信息**: 每个失败都提供详细的诊断和可能原因
3. **易于维护**: 统一的测试结构，便于扩展和修改
4. **自动化集成**: 通过 Git Hooks 自动运行，确保一致性
5. **灵活运行**: 支持运行所有测试或特定类型的测试

## ✨ 下一步

1. ✅ 测试系统已完全建立
2. ⏳ 等待实际运行发现不一致
3. ⏳ 人工判断并修复不一致
4. ⏳ 持续监控和维护

## 🤝 贡献指南

如需添加新的测试检查：

1. 在相应的测试文件中添加新的 `test()` 块
2. 确保在 `setUpAll` 中调用 `YamlTestUtils.printTestWarning()`
3. 失败消息必须包含：
   - 明确的问题描述
   - YAML 值 vs 实际值对比
   - 可能的原因列表
   - AI 不要修改的提醒

示例：
```dart
test('example test', () {
  // ... 测试逻辑 ...
  
  if (somethingWrong) {
    fail('❌ 问题描述\n'
        '   YAML 中的值: $yamlValue\n'
        '   实际值: $actualValue\n'
        '   \n'
        '   这可能意味着:\n'
        '   1. 原因1\n'
        '   2. 原因2\n'
        '   \n'
        '   👉 AI 不要修改！请人工判断：\n'
        '      - 问题1？\n'
        '      - 问题2？');
  }
});
```

## 📞 故障排除

### 测试运行失败
```bash
flutter clean
flutter pub get
flutter test test/yaml/
```

### 大量 YAML 过时
```bash
# 备份并重新生成所有 YAML
scripts/anz yaml:create:all

# 检查生成结果
./scripts/run_yaml_tests.sh
```

### Python Linter 报错
```bash
python --version  # 确保 Python 3.x
pip install pyyaml
python scripts/architecture_linter.py documents/architecture/
```

---

**创建日期**: 2025-10-27  
**最后更新**: 2025-10-27  
**维护者**: GranoFlow 开发团队

