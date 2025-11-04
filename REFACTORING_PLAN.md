# 文件重构拆分方案

## 1. lib/data/repositories/task_repository_mutations.dart (504行)

### 当前结构
- 这是一个 `part of 'task_repository.dart'` 文件
- 包含所有数据变更方法（mutations）
- 使用 mixin 模式：`TaskRepositoryMutations`

### 拆分方案

**按职责分组拆分**：

1. **task_repository_mutations_core.dart** (~150行)
   - `createTask` - 创建任务
   - `_applyTaskUpdate` - 应用任务更新（私有辅助方法）
   - 基础更新逻辑

2. **task_repository_mutations_status.dart** (~200行)
   - `updateTask` - 更新任务（包含状态同步逻辑）
   - `markStatus` - 标记状态
   - `archiveTask` - 归档任务
   - 状态相关的更新逻辑

3. **task_repository_mutations_move.dart** (~100行)
   - `moveTask` - 移动任务
   - 任务移动相关的逻辑

4. **task_repository_mutations_batch.dart** (~100行)
   - `softDelete` - 软删除
   - `purgeObsolete` - 清理过期任务
   - `clearAllTrashedTasks` - 清空回收站
   - `upsertTasks` - 批量插入/更新
   - `batchUpdate` - 批量更新
   - `adjustTemplateLock` - 调整模板锁

### 实施步骤
1. 创建新的 part 文件
2. 将方法按分组移动到对应文件
3. 保持 mixin 结构，在 task_repository.dart 中组合所有 part

---

## 2. lib/data/migrations/task_table_split_migrator.dart (537行)

### 当前结构
- 独立的迁移类 `TaskTableSplitMigrator`
- 包含多个阶段：dryRun, apply, rollback
- 包含辅助类和数据结构

### 拆分方案

**按功能阶段拆分**：

1. **task_table_split_migrator.dart** (~150行) - 主文件
   - `TaskTableSplitMigrator` 类定义
   - 主要入口方法：`dryRun`, `apply`, `rollback`
   - 协调调用各个阶段

2. **task_table_split_migrator_models.dart** (~100行)
   - `MigrationReport` 类
   - `MigrationProgress` 类
   - `MigrationStage` 枚举（如果存在）
   - `_MigrationContext` 类

3. **task_table_split_migrator_stages.dart** (~150行)
   - `_migrateProjects` - 迁移项目
   - `_migrateMilestones` - 迁移里程碑
   - `_migrateTasks` - 迁移任务
   - `_cleanup` - 清理

4. **task_table_split_migrator_helpers.dart** (~100行)
   - `_convertToProjectLog` - 日志转换
   - `_convertToMilestoneLog` - 日志转换
   - 其他辅助方法

### 注意事项
- 这个文件标记为已废弃，但保留用于参考
- 拆分后保持向后兼容性

---

## 3. lib/core/providers/task_pagination_providers.dart (425行)

### 当前结构
- 包含三个分页状态类：`CompletedTasksPaginationState`, `ArchivedTasksPaginationState`, `TrashedTasksPaginationState`
- 包含三个对应的 Notifier 类

### 拆分方案

**按分页类型拆分**：

1. **task_pagination_providers.dart** (~80行) - 主文件
   - 导出所有 provider
   - 通用类型定义（如果有）

2. **completed_tasks_pagination_provider.dart** (~120行)
   - `CompletedTasksPaginationState` 类
   - `CompletedTasksPaginationNotifier` 类
   - 对应的 provider 定义

3. **archived_tasks_pagination_provider.dart** (~120行)
   - `ArchivedTasksPaginationState` 类
   - `ArchivedTasksPaginationNotifier` 类
   - 对应的 provider 定义

4. **trashed_tasks_pagination_provider.dart** (~120行)
   - `TrashedTasksPaginationState` 类
   - `TrashedTasksPaginationNotifier` 类
   - 对应的 provider 定义

### 实施步骤
1. 创建三个独立的 provider 文件
2. 在原文件中保留导出，或直接使用新文件
3. 更新所有导入路径

---

## 4. lib/core/services/project_service.dart (468行)

### 当前结构
- `ProjectService` 类
- 包含项目 CRUD、里程碑管理、任务操作等方法

### 拆分方案

**按职责拆分**：

1. **project_service.dart** (~150行) - 主文件
   - `ProjectService` 类定义
   - 构造函数和依赖注入
   - 基础查询方法：`watchActiveProjects`, `findByIsarId`, `findByProjectId`
   - `updateProject` - 更新项目

2. **project_service_create.dart** (~100行)
   - `createProject` - 创建项目
   - `convertTaskToProject` - 转换任务为项目
   - 创建相关的辅助方法

3. **project_service_lifecycle.dart** (~150行)
   - `archiveProject` - 归档项目
   - `completeProject` - 完成项目
   - `trashProject` - 移到回收站
   - `restoreProject` - 恢复项目
   - `reactivateProject` - 重新激活项目
   - `deleteProject` - 删除项目
   - `snoozeProject` - 暂停项目

4. **project_service_helpers.dart** (~100行)
   - `listTasksForProject` - 列出项目任务
   - `hasActiveTasks` - 检查活跃任务
   - `_getAllDescendants` - 获取所有后代
   - `_archiveActiveTasksForProject` - 归档活跃任务
   - `_trashAllTasksForProject` - 删除所有任务
   - `_deleteAllTasksForProject` - 永久删除所有任务
   - `_assignProjectToDescendants` - 分配项目给后代
   - 其他私有辅助方法

5. **project_service_milestones.dart** (~70行)
   - `findMilestoneById` - 查找里程碑
   - `watchMilestones` - 监听里程碑
   - `listMilestones` - 列出里程碑

### 实施步骤
1. 创建新的 part 文件或独立文件
2. 将方法移动到对应文件
3. 使用 mixin 或直接拆分到独立文件

---

## 5. lib/core/services/sort_index_service.dart (375行)

### 当前结构
- `SortIndexService` 类
- 包含排序比较函数和排序索引计算方法

### 拆分方案

**按功能拆分**：

1. **sort_index_service.dart** (~150行) - 主文件
   - `SortIndexService` 类定义
   - 构造函数
   - 主要公共方法

2. **sort_index_comparators.dart** (~100行)
   - `_compareTasksForInbox` - Inbox 排序比较
   - `_compareTasksForTasksPage` - Tasks 页面排序比较
   - `_compareTasksForChildren` - 子任务排序比较
   - 所有静态比较函数

3. **sort_index_calculator.dart** (~150行)
   - 排序索引计算逻辑
   - 取中值插入逻辑
   - 局部重排逻辑
   - 批量重排逻辑

---

## 6. lib/core/services/task_crud_service.dart (376行)

### 当前结构
- `TaskCrudService` 类
- 包含任务 CRUD 操作和状态管理

### 拆分方案

**按操作类型拆分**：

1. **task_crud_service.dart** (~100行) - 主文件
   - `TaskCrudService` 类定义
   - 构造函数
   - 基础查询方法

2. **task_crud_service_create.dart** (~80行)
   - `captureInboxTask` - 创建 Inbox 任务
   - `createTask` - 创建任务（如果有）
   - 创建相关的辅助方法

3. **task_crud_service_update.dart** (~120行)
   - `planTask` - 规划任务
   - `updateTask` - 更新任务
   - `updateTaskTitle` - 更新标题
   - `updateTaskDescription` - 更新描述
   - 更新相关的辅助方法

4. **task_crud_service_status.dart** (~100行)
   - `markTaskCompleted` - 标记完成
   - `markTaskDoing` - 标记进行中
   - `markTaskPending` - 标记待处理
   - `archiveTask` - 归档任务
   - `restoreTask` - 恢复任务
   - 状态相关的辅助方法

5. **task_crud_service_hierarchy.dart** (~80行)
   - `getAllDescendantTasks` - 获取所有后代
   - `addSubtask` - 添加子任务
   - `moveTask` - 移动任务
   - 层级相关的辅助方法

---

## 7. lib/core/theme/app_theme.dart (372行)

### 当前结构
- `AppTheme` 类（静态类）
- 包含 `light()` 和 `dark()` 方法
- 包含 `_buildTextTheme` 辅助方法

### 拆分方案

**按主题拆分**：

1. **app_theme.dart** (~100行) - 主文件
   - `AppTheme` 类定义
   - `light()` 方法（简化为调用其他方法）
   - `dark()` 方法（简化为调用其他方法）
   - 通用主题配置

2. **app_theme_light.dart** (~150行)
   - `_buildLightTheme()` - 构建浅色主题
   - 浅色主题的所有配置
   - 浅色主题特有的组件样式

3. **app_theme_dark.dart** (~150行)
   - `_buildDarkTheme()` - 构建深色主题
   - 深色主题的所有配置
   - 深色主题特有的组件样式

4. **app_theme_helpers.dart** (~100行)
   - `_buildTextTheme` - 构建文本主题
   - `_buildIconTheme` - 构建图标主题（如果有）
   - 其他共享的辅助方法

---

## 8. lib/core/services/seed_import_service.dart (340行)

### 当前结构
- `SeedImportService` 类
- 包含种子数据导入的各种方法

### 拆分方案

**按导入阶段拆分**：

1. **seed_import_service.dart** (~100行) - 主文件
   - `SeedImportService` 类定义
   - `importIfNeeded` - 主入口方法
   - `loadSeedPayload` - 加载种子数据
   - 协调各个导入阶段

2. **seed_import_service_tasks.dart** (~100行)
   - `_applyTasks` - 应用任务
   - 任务导入相关的辅助方法

3. **seed_import_service_inbox.dart** (~80行)
   - `_applyInboxItems` - 应用 Inbox 项目
   - Inbox 导入相关的辅助方法

4. **seed_import_service_helpers.dart** (~80行)
   - `_clearAllTags` - 清空标签
   - `_generateProjectId` - 生成项目 ID（如果有）
   - 其他辅助方法

---

## 9. lib/presentation/tasks/task_list_page.dart (386行)

### 当前结构
- `TaskListPage` - 页面组件
- `_TaskListPageState` - 状态管理类
- 包含滚动控制、自动滚动等逻辑

### 拆分方案

**按功能拆分**：

1. **task_list_page.dart** (~150行) - 主文件
   - `TaskListPage` 组件
   - `_TaskListPageState` 类定义
   - `build` 方法
   - 主要 UI 结构

2. **task_list_page_scroll.dart** (~120行)
   - 滚动控制逻辑
   - `_scrollController` 相关方法
   - `_sectionKeys` 管理
   - `_maybeAutoScroll` - 自动滚动逻辑
   - `_scrollToSection` - 滚动到分区

3. **task_list_page_state.dart** (~120行)
   - 状态管理逻辑
   - `_didAutoScroll` 管理
   - `_hasCompletedInitialBuild` 管理
   - `initState` 和 `dispose` 方法
   - 生命周期管理

---

## 拆分优先级建议

### P0（立即重构 - 超过硬性阈值）
1. ✅ `task_repository_mutations.dart` (504行) - 已使用 part 模式，拆分相对容易
2. ✅ `task_table_split_migrator.dart` (537行) - 已废弃，但需要保持结构清晰

### P1（优先重构 - 超过 core 硬性阈值）
3. ✅ `task_pagination_providers.dart` (425行) - 结构清晰，按类型拆分
4. ✅ `project_service.dart` (468行) - 职责明确，按功能拆分

### P2（计划重构 - 超过警告阈值）
5. `sort_index_service.dart` (375行)
6. `task_crud_service.dart` (376行)
7. `app_theme.dart` (372行)
8. `seed_import_service.dart` (340行)
9. `task_list_page.dart` (386行)

---

## 通用拆分原则

1. **保持向后兼容**：拆分后保持公共 API 不变
2. **按职责拆分**：每个文件应该有明确的单一职责
3. **避免循环依赖**：拆分后的文件之间不应该有循环依赖
4. **保持测试覆盖**：拆分后需要更新测试文件
5. **使用合适模式**：
   - Repository/Service 类：可以使用 part 文件或 mixin
   - Provider：可以拆分为独立文件
   - Widget：可以拆分为子组件
   - Theme：可以拆分为独立文件

