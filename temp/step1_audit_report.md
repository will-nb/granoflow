# 步骤1：现状审计报告

## 1. 直接使用 Store/Box 的代码清单

### 应用入口层
- **lib/main.dart** (行 45, 59-80)
  - `_openObjectBoxStore()` 直接创建 Store
  - 需要改为通过 DatabaseAdapter 工厂方法

### 适配器层
- **lib/data/database/objectbox_adapter.dart** (行 14, 28, 58)
  - 直接持有 `Store store`
  - `_box<E>()` 方法直接返回 `store.box<E>()`
  - 需要迁移至统一 CRUD 接口

### 仓储层（所有 ObjectBox 仓储都直接使用 Box）
以下文件直接调用 `store.box` 或持有 `Box<T>`，需替换为 BaseRepository + DatabaseAdapter 封装：

1. **lib/data/repositories/objectbox/objectbox_task_repository.dart**
   - 行 28-30: `_taskBox` 和 `_taskLogBox` 直接获取 Box
   - 多处直接使用 `_taskBox.put()`, `_taskBox.get()`, `_taskBox.getAll()` 等

2. **lib/data/repositories/objectbox/objectbox_task_template_repository.dart**
   - 直接使用 Box<TaskTemplateEntity>

3. **lib/data/repositories/objectbox/objectbox_milestone_repository.dart**
   - 直接使用 Box<MilestoneEntity>

4. **lib/data/repositories/objectbox/objectbox_focus_session_repository.dart**
   - 直接使用 Box<FocusSessionEntity>

5. **lib/data/repositories/objectbox/objectbox_project_repository.dart**
   - 直接使用 Box<ProjectEntity> 和 Box<ProjectLogEntity>

6. **lib/data/repositories/objectbox/objectbox_seed_repository.dart**
   - 直接使用 Box<SeedImportLogEntity>

7. **lib/data/repositories/objectbox/objectbox_tag_repository.dart**
   - 直接使用 Box<TagEntity>

8. **lib/data/repositories/objectbox/objectbox_preference_repository.dart**
   - 直接使用 Box<PreferenceEntity>

### 查询构建层
- **lib/data/database/objectbox_query_builder.dart** (行 14, 65)
  - 直接持有 `Box<E> _box`
  - 行 65: 使用 `_box.getAll()` 在内存中过滤，性能差
  - 需要改为使用 ObjectBox 原生 QueryBuilder 和 Condition

## 2. 当前实现问题总结

### DatabaseAdapter 接口问题
- 缺少 CRUD 方法（put, putMany, remove, findById, findAll, count）
- 缺少 watchList 方法（当前只有 watch，且实现是轮询）
- 缺少错误上下文（DatabaseOperationContext）
- 缺少 instrumentation 支持

### ObjectBoxAdapter 实现问题
- 事务未使用 `Store.runInTransaction`，只是简单包装
- watch 方法使用 `Stream.periodic` 轮询，不是真正的 ObjectBox watch
- 缺少批量操作支持
- 缺少错误上下文记录

### ObjectBoxQueryBuilder 问题
- 使用 `getAll()` 后在内存过滤，性能差
- 未使用 ObjectBox 原生 QueryBuilder 和 Condition
- 缺少 describe() 方法用于调试
- 不支持复杂条件组合

### 仓储层问题
- 所有仓储直接访问 Box，违反抽象层原则
- 缺少统一的实体转换和日志记录
- 多个方法抛出 UnimplementedError
- 缺少统一的错误处理

## 3. 种子导入流程现状

### 现有测试
- `integration_test/seed_import_test.dart` - 基础集成测试
- `integration_test/seed_import_duplicate_test.dart` - 重复导入测试

### 导入服务问题
- `lib/core/services/seed_import_service.dart` 缺少导入前后计数比对
- 缺少失败回滚日志
- 缺少结构化日志输出
- 缺少 describe() 查询条件输出

## 4. 迁移优先级

### 高优先级（影响功能）
1. ObjectBoxTaskRepository - 任务查询和监听方法未实现
2. ObjectBoxQueryBuilder - 性能问题，需要改用原生查询
3. ObjectBoxAdapter - watch 方法需要改用真正的 watch

### 中优先级（影响可维护性）
1. 创建 BaseObjectBoxRepository - 统一仓储逻辑
2. 扩展 DatabaseAdapter 接口 - 提供完整 CRUD
3. 添加 instrumentation - 便于调试和监控

### 低优先级（优化）
1. 其他仓储迁移到 BaseRepository
2. 添加 InMemoryAdapter 用于测试
3. Drift 兼容性准备

## 5. 下一步行动

1. ✅ 完成审计（当前步骤）
2. 执行现有种子导入测试，收集日志
3. 梳理 ObjectBoxQueryBuilder 扩展需求
4. 开始实施步骤2：补全 DatabaseAdapter 与 QueryBuilder
