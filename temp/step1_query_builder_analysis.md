# ObjectBoxQueryBuilder 现状分析

## 当前实现问题

### 1. 性能问题
- **行 65**: 使用 `_box.getAll()` 加载所有数据到内存
- 然后在内存中使用 `where()` 过滤，性能极差
- 对于大数据集会导致内存和性能问题

### 2. 未使用 ObjectBox 原生能力
- 未使用 ObjectBox 的 `QueryBuilder` 和 `Condition`
- 未利用索引优化查询
- 无法利用 ObjectBox 的查询优化

### 3. 缺少调试支持
- 没有 `describe()` 方法输出查询条件
- 无法在日志中查看实际执行的查询
- 调试困难

### 4. 使用情况
- **objectbox_project_repository.dart**: 使用了 `adapter.watch()` 和 QueryBuilder
- **其他仓储**: 主要直接使用 `Box.getAll()`，未使用 QueryBuilder
- **objectbox_task_repository.dart**: 
  - `listAll()` 使用 `taskBox.getAll()`
  - `findBySlug()` 使用 `taskBox.getAll()` 后遍历
  - `_findById()` 使用 `box.getAll()` 后遍历

## 扩展需求

### 1. 支持 ObjectBox Condition
- 将 `DatabasePredicate` 转换为 ObjectBox `Condition`
- 支持字段比较：equals, notEquals, greaterThan, lessThan, between
- 支持字符串操作：contains, startsWith, endsWith
- 支持组合条件：and, or, not

### 2. 支持原生排序
- 使用 `query.order(property, flags)` 而不是内存排序
- 支持多字段排序
- 支持升序/降序

### 3. 支持分页
- 使用 `offset` 和 `limit` 而不是 `sublist`
- 在数据库层面分页，减少内存使用

### 4. 添加调试方法
- `describe()`: 返回查询条件的结构化描述
- `explain()`: 返回查询执行计划（如果 ObjectBox 支持）

### 5. 字段映射
- 需要建立 Entity 字段到 ObjectBox Property 的映射
- 支持常用字段：TaskEntity, ProjectEntity, TagEntity 等

## 迁移计划

1. 创建 `FieldDescriptor` 和 `QueryDescriptor` 中间 DSL
2. 实现 Condition 转换逻辑
3. 替换 `getAll()` 为 `query.find()`
4. 添加 `describe()` 方法
5. 更新所有仓储使用新的 QueryBuilder
