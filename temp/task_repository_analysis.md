# task_repository.dart 行数增长分析

## 时间线对比

| 时间点 | 行数 | 差异 |
|--------|------|------|
| 2025-11-03 (b6e4ac3) | 1630 行 | 基准 |
| 2025-11-04 (当前) | 1857 行 | +227 行 |

## 关键发现

**文件在 11月3日就已经严重超标**：
- 11月3日：**1630 行**（MAX: 500 行，超出 **226%**）
- 当前版本：**1857 行**（MAX: 500 行，超出 **271%**）

文件**不是最近才变大的**，而是在11月3日就已经远超限制，最近只是继续增长。

## 最近增加的代码（227 行）

### 1. 子任务状态同步功能（~150 行）
- `_syncDescendantsStatusInTransaction()` 方法：~65 行
- `_getAllDescendantsIncludingTrashed()` 方法：~10 行
- `listChildrenIncludingTrashed()` 方法：~15 行
- 修改 `markStatus()`、`updateTask()`、`softDelete()` 添加同步逻辑：~70 行

### 2. 清空回收站功能（~35 行）
- `clearAllTrashedTasks()` 方法：~35 行

### 3. 区域边界统一（~100 行）
- 重构 `_fetchSection()` 使用 `TaskSectionUtils`：~100 行（主要是替换和添加注释）

### 4. 已完成/归档页面过滤（~10 行）
- 在 `listCompletedTasks`、`listArchivedTasks`、`countCompletedTasks`、`countArchivedTasks` 中添加 `parentIdIsNull()` 过滤

## 结论

**问题根源**：文件在11月3日就已经严重超标（1630行），说明之前虽然有重构，但**没有真正按照规范拆分文件**。

**建议**：
1. 按照规范要求，将文件拆分为：
   - `task_repository_queries.dart` - 查询方法
   - `task_repository_mutations.dart` - 变更方法
   - `task_repository_streams.dart` - Stream 方法
   - `task_repository_section_queries.dart` - 区域查询方法
   - `task_repository_task_hierarchy.dart` - 任务层级相关方法（子任务、状态同步等）

2. 或者按功能模块拆分：
   - 基础 CRUD
   - 区域查询
   - 任务层级管理
   - 状态管理
   - Stream 监听

3. **立即重构**：这个文件已经严重违反规范，应该立即拆分。

