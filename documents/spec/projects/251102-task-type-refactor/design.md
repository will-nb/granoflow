# 任务类型抽象重构设计

## 1. 背景与动机

- 现状：`Task` 单一模型承担普通任务、项目、里程碑三种语义，业务层与 UI 通过 `taskKind` 做分支，判断散落在服务、仓库、Provider、Widget 等多个层级。
- 问题：
  - 新增逻辑时容易遗漏分支，导致项目/里程碑被当作普通任务处理。
  - 代码阅读和测试负担大；调试时难以追踪“当前 task 是哪种语义”。
  - 若直接拆表改动面巨大，短期内容易破坏既有功能。
- 目标：在 **不拆表、保持数据结构稳定** 的前提下，收束 `taskKind` 判断、提升类型语义清晰度，为未来可能的分表或模型演进预留挂点。

## 2. 设计目标

1. 针对项目与里程碑提供集中、类型化的访问方式，弱化散点判断。
2. 将 Repository/Service 对外暴露的接口调整为类型化 API，调用方不再直接依赖 `Task.taskKind`。
3. 保持现有数据库结构（`TaskEntity` 单表 + `taskKind` 字段）与业务行为不变，确保平滑迁移。
4. 为未来拆表或新增专有字段预留扩展点，减少后续重构工作量。

## 3. 适用范围

- 范围内：`lib/data/models`, `lib/data/repositories`, `lib/core/services`, `lib/core/providers`, `lib/presentation` 中所有使用 `taskKind` 的业务逻辑；相关测试代码。
- 范围外：数据库 Schema、外部 API、Flutter UI 交互行为保持不变；不引入新的后端依赖。

## 4. 现状分析摘要

- `TaskKind` 相关判断集中在：
  - `TaskService` 的项目创建、转换、层级更新、拖拽逻辑。
  - `TaskRepository` 的查询、批量更新、树构建等。
  - Provider 与 UI 工具类（如 `hierarchy_utils.dart`）中关于层级、过滤的判断。
- 这些判断普遍遵循模式：`task.taskKind == TaskKind.project || task.taskKind == TaskKind.milestone`。
- 当前接口直接返回 `Task`，调用方需要自行判断类型。

## 5. 设计原则

1. **类型显式**：为不同语义的任务提供独立的包装类型或接口，使调用方无需再写 `taskKind` 分支。
2. **向后兼容**：底层存储与外部接口不变；逐步迁移调用方，允许新旧方式在一段时间内并存。
3. **渐进重构**：按层次（Domain → Repository → Service → Presentation）逐步替换，期间每个阶段都可回滚。
4. **可测试性**：为新增抽象提供单元测试，确保包装逻辑和分类逻辑稳定。

## 6. 新方案概述

### 6.1 Domain 层：任务变体封装

- 新增文件 `lib/data/models/task_variant.dart`，定义不可变封装：
  ```dart
  abstract class TaskVariant {
    Task get base;
    TaskKind get kind;

    bool get isProject => kind == TaskKind.project;
    bool get isMilestone => kind == TaskKind.milestone;
    bool get isRegular => kind == TaskKind.regular;

    static TaskVariant from(Task task);
  }

  class RegularTaskVariant extends TaskVariant { ... }
  class ProjectTaskVariant extends TaskVariant { ... }
  class MilestoneTaskVariant extends TaskVariant { ... }
  ```
- 提供便捷扩展：
  - `TaskVariant.assertProject()`/`asProject()` 抛出受检异常，避免误用。
  - `TaskExtensions`（`extension on Task`）仅用于迁移期，引导改用 `TaskVariant`。
- 后续一旦拆表，可让 `ProjectTaskVariant` 持有新的 `Project` 模型而不是 `Task`，上层代码无需改动。

### 6.2 Utility 层：集中判定

- 新增 `TaskTypeGuards` 静态工具，替换散落的 `taskKind` 判断：
  ```dart
  class TaskTypeGuards {
    static bool isProjectOrMilestone(TaskVariant task);
    static Never throwIfNotProject(TaskVariant task, {String? context});
    // ...
  }
  ```
- `hierarchy_utils.dart` 等文件改为依赖 `TaskTypeGuards`，避免直接访问 `Task.taskKind`。

### 6.3 Repository 层：类型化接口

- 在 `TaskRepository` 中新增、调整方法：
  - `Future<ProjectTaskVariant?> findProjectById(int id);`
  - `Stream<List<ProjectTaskVariant>> watchProjects();`
  - `Stream<List<MilestoneTaskVariant>> watchMilestones(ProjectId projectId);`
  - 原有方法仍保留，但内部复用新的私有帮助函数，逐步迁移调用方。
- `IsarTaskRepository` 内部仍查询 `TaskEntity`，但在 `_toDomain` 阶段直接转换为 `TaskVariant`。
- 为避免大面积改动，一次迭代优先改所有“项目/里程碑”接口，其他选项保持返回 `Task`，等待后续迭代。

### 6.4 Service 层：业务逻辑解耦

- `TaskService` 内部增加专用私有方法：
  ```dart
  Future<ProjectTaskVariant> _requireProject(int taskId);
  Future<MilestoneTaskVariant> _requireMilestone(int taskId);
  ```
- 项目/里程碑相关逻辑改用 `TaskVariant`，移除直接的 `taskKind` 判断。
- 对外公开 API 不变（保持向后兼容），但内部实现切换到新的封装。
- 若出现需要专门服务的场景，再拆分 `ProjectService`，但本轮不立即完成，以控制变更面。

### 6.5 Presentation 层：有序迁移

- 将 Provider 与 Widget 中触及 `taskKind` 的逻辑逐步替换：
  - Provider 侧先调用新的 Repository 方法，返回 `ProjectTaskVariant` / `MilestoneTaskVariant` 列表。
  - UI 工具类（如 `hierarchy_utils.dart`）改为接收 `TaskVariant`。
  - 拖拽、排序、过滤等行为保持一致，仅更换判断方式。
- 迁移顺序：
  1. `core/providers/app_providers.dart`
  2. `presentation/tasks/utils/hierarchy_utils.dart`
  3. Inbox/Task 列表相关 Widget
  4. 其他零散引用

## 7. 迁移步骤与交付节奏

| 阶段 | 交付内容 | 验证方式 |
| --- | --- | --- |
| 阶段 0 | 补充单元测试覆盖当前关键路径（确保有安全网） | `flutter test` 全量 |
| 阶段 1 | 引入 `TaskVariant`、`TaskTypeGuards`，并在 Repository/Service 内部最小范围试用 | 新增单元测试覆盖变体转换 |
| 阶段 2 | Repository 公共方法返回 `TaskVariant`，Provider/Service 逐步迁移 | 对应模块单元 & widget 测试 |
| 阶段 3 | UI 工具与组件改用新抽象，移除直接 `taskKind` 判断 | `flutter analyze` + 相关 widget 测试 |
| 阶段 4 | 清理遗留扩展、标记 TODO，为未来拆表列出挂点 | 回归测试 + 验收文档 |

- 每个阶段末尾运行 `flutter analyze`、`flutter test`，必要时补充针对性 widget test。
- 迭代过程中保留旧接口的向下兼容实现（例如临时的 `TaskVariant.fromTask`），待所有调用方迁移完毕后再集中删除。

## 8. 测试策略

1. **单元测试**：
   - `TaskVariant` 构造与类型转换。
   - `TaskTypeGuards` 的判定逻辑。
   - Repository 新增方法的结果类型与排序。
2. **Widget 测试**：
   - 项目列表、里程碑列表、任务树组件在 `TaskVariant` 输入下的渲染。
3. **集成测试**：
   - 保留现有流程，不新增外部依赖。
4. **回归测试**：
   - 项目创建、里程碑创建、拖拽、批量更新等核心路径。

## 9. 风险与缓解

| 风险 | 说明 | 缓解措施 |
| --- | --- | --- |
| 类型封装误用 | 调用层仍可能直接访问 `Task` | 暂保留 `Task` API，但在代码审查 & lint 中提示迁移；为 `TaskVariant` 补充断言 |
| 迁移阶段代码同时支持两套方式，维护成本上升 | 过渡期内存在双轨逻辑 | 通过 TODO 标记和阶段性清理计划控制时长 |
| 测试覆盖不足导致回归 | 新的抽象未被测试覆盖 | 阶段 0 先补测试，重构后跑全量测试 |

## 10. 未决事项

1. `TaskVariant` 是否需要持有衍生字段（例如项目统计信息）？本轮保留最小实现，待业务明确后再扩展。
2. 是否引入 lint/自定义 analyzer 规则强制禁止直接访问 `task.taskKind`？暂不执行，观察迁移进度再决定。
3. `TaskService` 是否延伸出 `ProjectService`/`MilestoneService` 独立类？视阶段 2 实施情况评估，若内部私有方法过多再拆分。

---

通过该方案，我们可以在 **不修改数据库结构** 的情况下，把项目和里程碑的语义封装为第一类对象，减少未来拆表或新增字段时的工作量，同时确保现有功能稳定。后续若真要拆分表结构，只需替换 `TaskVariant` 的底层实现与 Repository 查询逻辑，其他层级的改动将显著降低。

