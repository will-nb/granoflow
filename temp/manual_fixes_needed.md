# 需要手动修复的错误

## 当前状态
- 错误数：355（从 428 减少到 355，已修复 73 个，17% 修复率）

## 需要手动修复的错误

### 1. `non_type_as_type_argument` (2个) - Isar 相关
**文件：**
- `lib/core/providers/repository_providers.dart:13` - `Provider<Isar>`
- `lib/main.dart:56` - `Future<Isar>`

**问题：** Isar 已经不存在，需要重写为使用 ObjectBox

**修复方案：**
1. 创建 `DatabaseAdapter` provider
2. 将所有 `IsarRepository` 改为 `ObjectBoxRepository`
3. 更新 `main.dart` 移除 Isar 相关代码

### 2. `undefined_class` (1个) - Isar 相关
**文件：**
- `lib/main.dart:14` - `Isar? _isarInstance;`

**问题：** Isar 类不存在

**修复方案：** 移除 Isar 相关代码，使用 ObjectBox

### 3. `return_of_invalid_type` (1个)
**文件：**
- `lib/data/database/objectbox_adapter.dart:54`

**问题：** `runInTransactionAsync` 的返回类型不匹配

**修复方案：** 需要检查 ObjectBox API 的正确用法

### 4. `undefined_method` (1个)
**文件：**
- `lib/data/database/objectbox_adapter.dart:39` - `Box.watch()`

**问题：** `Box.watch()` 方法不存在

**修复方案：** 需要使用 ObjectBox 的正确 API

### 5. `wrong_number_of_type_arguments_method` (1个)
**文件：**
- `lib/data/database/objectbox_adapter.dart:54` - `runInTransactionAsync`

**问题：** 类型参数数量不匹配

**修复方案：** 需要检查 ObjectBox API 的正确用法

### 6. `undefined_identifier` (10个) - lib
**问题：** 可能是 Isar 相关的标识符

### 7. `undefined_function` (8个) - lib
**问题：** 可能是 Isar 相关的函数

## 建议

这些错误都需要手动修复，因为它们涉及到：
1. Isar -> ObjectBox 迁移的核心代码
2. ObjectBox API 的正确用法
3. 应用程序初始化逻辑

建议：
1. 先修复 `repository_providers.dart` 和 `main.dart` 的 Isar 相关代码
2. 然后修复 `objectbox_adapter.dart` 的 API 用法
3. 最后处理其他 `undefined_identifier` 和 `undefined_function` 错误
