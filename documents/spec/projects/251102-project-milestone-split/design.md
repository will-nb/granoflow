# 项目 / 里程碑拆表设计

## 1. 背景与目标

- **现状**：所有任务（普通任务、项目、里程碑）存储在单一 `TaskEntity` 表，通过 `taskKind` 字段区分。业务层和 UI 需频繁执行 `taskKind` 判断，逻辑分散且易出错。
- **问题**：
  1. 模型语义混杂，类型安全差，未来为项目/里程碑扩展专有字段困难。
  2. 查询需要频繁过滤 `taskKind`，难以针对项目/里程碑优化索引。
  3. 层级关系复杂：`parentId` 同时承载任务之间及项目/里程碑关系，导致拖拽、批量更新等逻辑臃肿。
- **目标**：
  - 将项目、里程碑拆分为独立的 Isar 集合和领域模型。
  - 重新设计任务与项目/里程碑的关联方式，提升类型语义和未来扩展性。
  - 提供明确的迁移、回滚、测试策略，确保在开发环境中安全演进。
- **非目标**：
  - 本轮不引入新的外部服务或后端接口；保持 Flutter 层 API/状态管理方案不变。
  - 不改变现有 UI 交互行为（拖拽、排序、过滤等）。

## 2. 新架构概览

### 2.1 数据模型与实体

| 领域实体 | Isar 集合 | 说明 |
| --- | --- | --- |
| `Project` | `ProjectEntity` | 项目根节点，承载截止日期、标签、描述等字段。 |
| `Milestone` | `MilestoneEntity` | 附属于项目的阶段，指向 `ProjectEntity`。 |
| `Task` | `TaskEntity` | 普通任务，支持层级嵌套，并可关联项目/里程碑。 |

#### 2.1.1 ProjectEntity
```dart
@collection
class ProjectEntity {
  Id id = Isar.autoIncrement;
  late String projectId;        // 业务 UUID
  late String title;
  @enumerated
  late TaskStatus status;
  DateTime? dueAt;
  DateTime? startedAt;
  DateTime? endedAt;
  late DateTime createdAt;
  late DateTime updatedAt;
  double sortIndex = 0;
  List<String> tags = [];
  int templateLockCount = 0;
  String? seedSlug;
  bool allowInstantComplete = false;
  String? description;
  List<ProjectLogEntryEntity> logs = [];
}
```

#### 2.1.2 MilestoneEntity
```dart
@collection
class MilestoneEntity {
  Id id = Isar.autoIncrement;
  late String milestoneId;
  late Id projectIsarId;        // 指向 ProjectEntity.id
  late String title;
  @enumerated
  late TaskStatus status;
  DateTime? dueAt;
  DateTime? startedAt;
  DateTime? endedAt;
  late DateTime createdAt;
  late DateTime updatedAt;
  double sortIndex = 0;
  List<String> tags = [];
  int templateLockCount = 0;
  String? seedSlug;
  bool allowInstantComplete = false;
  String? description;
  List<MilestoneLogEntryEntity> logs = [];
}
```

#### 2.1.3 TaskEntity（重构版）
```dart
@collection
class TaskEntity {
  Id id = Isar.autoIncrement;
  late String taskId;
  late String title;
  @enumerated
  late TaskStatus status;
  DateTime? dueAt;
  DateTime? startedAt;
  DateTime? endedAt;
  late DateTime createdAt;
  late DateTime updatedAt;
  Id? parentTaskId;             // 仅指向 TaskEntity
  double sortIndex = 0;
  List<String> tags = [];
  int templateLockCount = 0;
  String? seedSlug;
  bool allowInstantComplete = false;
  String? description;
  List<TaskLogEntryEntity> logs = [];

  Id? projectIsarId;            // 任务所属项目，可为空
  Id? milestoneIsarId;          // 任务所属里程碑，可为空
}
```

### 2.2 关系设计

```
Project (1) ──► (N) Milestone
  │                 │
  │                 └─► 里程碑任务：Task.projectIsarId = Project.id,
  │                                   Task.milestoneIsarId = Milestone.id
  │
  └─► 项目直接任务：Task.projectIsarId = Project.id, milestoneIsarId = null

Task 层级：Task.parentTaskId 仅引用 TaskEntity.id（不再引用项目/里程碑）。
```

- 任务与项目/里程碑的归属通过 `projectIsarId` / `milestoneIsarId` 字段表达，不再依赖 `parentId` 跨集合引用。
- 里程碑强制关联一个项目；删除项目需要级联处理里程碑与关联任务。
- 保留任务自身的树形结构（父任务只能是普通任务），与项目/里程碑归属解耦。

### 2.3 域模型

- 新增 `Project`, `ProjectDraft`, `ProjectUpdate` 等领域模型，对应 `ProjectEntity`。
- 新增 `Milestone`, `MilestoneDraft`, `MilestoneUpdate`。
- 更新 `Task` 模型：移除 `taskKind`，增加 `projectId`、`milestoneId`（业务 ID，而非 Isar `Id`）。
- 提供聚合模型 `ProjectWithMilestones`、`ProjectContext` 方便 UI 组合查询。

## 3. 迁移策略

虽然当前环境无生产数据，仍按可回滚的方式组织迁移，确保脚本可复用。

### 3.1 迁移阶段

1. **准备阶段**
   - 添加新实体与领域模型，运行 `build_runner` 生成代码。
   - 在现有 `TaskRepository` 中实现并行读写：新增存取接口操作新集合，同时保留旧逻辑。
2. **数据迁移阶段**
   - 编写 `TaskTableSplitMigrator`（一次性脚本），步骤：
     1. 扫描所有 `taskKind == project` 记录 → 转化为 `ProjectEntity`。
     2. 扫描 `taskKind == milestone` → 转化为 `MilestoneEntity`，建立 `milestone.projectIsarId`。
     3. 遍历剩余普通任务：
        - 若 `parentId` 指向项目：设置 `projectIsarId`，`milestoneIsarId = null`。
        - 若 `parentId` 指向里程碑：设置 `projectIsarId`、`milestoneIsarId`。
        - 若 `parentId` 指向普通任务：迁移到 `parentTaskId`。
     4. 删除被迁移的旧项目/里程碑记录；移除 `taskKind` 字段。
   - 迁移脚本运行在事务中（Isar 支持单库事务），确保失败时回滚。
3. **切换阶段**
   - 更新 Repository/Service 仅访问新表结构。
   - 删除旧字段与兼容逻辑。

### 3.2 回滚策略

- 在迁移前导出全量 `TaskEntity` snapshot（Isar 提供 `copyTo`/`exportJson`），若迁移失败可还原。
- 迁移脚本使用双写策略：迁移完成后比对新旧统计（数量、关联关系）并生成对账报告。
- 若需要回退，执行 `TaskTableSplitMigrator.rollback()`：
  - 重建 `TaskEntity` 原始结构，将 `ProjectEntity`、`MilestoneEntity` 合并回单表。
  - 删除 `projectIsarId`、`milestoneIsarId` 字段。

## 4. Repository 与 Service 重构

### 4.1 仓库层划分

- `ProjectRepository`
  - `Future<Project> create(ProjectDraft draft);`
  - `Future<void> update(int projectId, ProjectUpdate update);`
  - `Stream<List<Project>> watchActiveProjects();`
  - `Future<Project?> findById(int id);`

- `MilestoneRepository`
  - `Future<Milestone> create(int projectId, MilestoneDraft draft);`
  - `Stream<List<Milestone>> watchByProject(int projectId);`
  - `Future<void> update(int milestoneId, MilestoneUpdate update);`

- `TaskRepository`
  - 任务 CRUD 保持，但新增过滤条件：`projectId`、`milestoneId`、`parentTaskId`。
  - 为树构建提供 `listChildren(int parentTaskId)`（仅普通任务）。

### 4.2 服务层调整

- 拆分 `TaskService`：
  1. `ProjectService`：负责项目生命周期、统计、归档。
  2. `MilestoneService`：负责项目下里程碑的创建、排序、状态同步。
  3. `TaskService`：聚焦普通任务（含与项目/里程碑的归属管理）。

- 同步逻辑示例：
  - 项目截止日期变更 → 影响里程碑默认截止日期 → 调用 `MilestoneService`。
  - 项目归档 → 级联归档项目任务与里程碑。
  - 任务拖拽：
    - 拖入项目区域 → 更新 `projectId`。若同时拖入里程碑 → 更新 `milestoneId`。
    - 层级拖拽仍通过 `parentTaskId` 实现。

### 4.3 Provider/UI 更新

- Provider 层引入新的仓库：
  - `projectRepositoryProvider`、`milestoneRepositoryProvider`、`taskRepositoryProvider`。
  - 为 UI 提供聚合数据：`projectDashboardProvider` 返回 `ProjectWithMilestones`。

- UI 组件调整：
  - 项目面板使用 `Project` 模型，里程碑列表使用 `Milestone` 模型。
  - Inbox/任务列表根据 `projectId/milestoneId` 显示面包屑。
  - 层级工具 `hierarchy_utils.dart` 调整为：
    - 任务层级仅考虑 `parentTaskId`。
    - 通过 `projectId/milestoneId` 获取项目上下文。

## 5. API 与数据转换

- **业务 ID 保持**：`projectId`、`milestoneId`、`taskId` 继续使用原 UUID；服务层返回业务 ID，UI 不感知 Isar `Id`。
- **Domain ↔ Entity 转换**：
  - 项目转换器：`ProjectMapper` 负责 `ProjectEntity` <-> `Project`。
  - 任务转换器：更新 `_toDomain` / `_fromDomain`，处理新增的 `projectId/milestoneId`。
- **日志结构**：拆分为 `ProjectLogEntry`、`MilestoneLogEntry`、`TaskLogEntry`，保留字段一致性，便于复用。

## 6. 测试策略

### 6.1 单元测试

- `ProjectRepository` / `MilestoneRepository` CRUD 与排序。
- `TaskRepository` 过滤逻辑：按项目、按里程碑、按父任务。
- 迁移脚本：
  - 使用内存数据库跑 `TaskTableSplitMigrator`，校验迁移前后数量一致、关联正确。

### 6.2 Widget 测试

- 项目列表、里程碑列表、任务树。
- 拖拽场景：从任务拖入项目、拖入里程碑、层级拖拽。

### 6.3 集成测试

- 端到端场景：创建项目 → 添加里程碑 → 添加任务 → 拖拽 → 归档。
- 验证同步逻辑（里程碑删除 → 任务解除 `milestoneId`）。

## 7. 上线与推进计划

| 阶段 | 内容 | 核心交付 | 验证 |
| --- | --- | --- | --- |
| P0 | 基础设施 | 新实体、领域模型、仓库骨架、迁移脚本 | `flutter analyze`、基础单测 |
| P1 | 迁移执行 | 在开发环境执行迁移，完成数据验证 | 迁移日志、对账报告 |
| P2 | 服务层重构 | 拆分服务，项目/里程碑业务逻辑迁移 | 单测、集成测试 |
| P3 | UI 适配 | Provider/组件改造、拖拽逻辑更新 | Widget 测试、人工验收 |
| P4 | 清理收尾 | 删除旧字段/代码、更新文档、编写验收记录 | 全量回归、`flutter test` |

每阶段结束运行 `flutter analyze`、`flutter test`，并更新 `documents/spec/.../02_acceptance_tests.md`。

## 8. 风险与缓解

| 风险 | 说明 | 缓解措施 |
| --- | --- | --- |
| 层级关系断裂 | 迁移过程中任务父子关系与项目归属可能不同步 | 迁移脚本内置校验：遍历任务确认父节点存在；迁移后生成校验报告 |
| ID 映射错误 | 业务 ID 与 Isar `Id` 对不上 | 统一由 `IdRegistry` 管理映射；迁移时构建 `Map<int, Id>` 缓存 |
| 逻辑缺口 | Service/UI 仍依赖旧 `taskKind` | 迁移前全局搜索 `taskKind`，逐项替换、写测试覆盖 |
| 性能退化 | 跨表查询增加 | 为 `projectIsarId`、`milestoneIsarId`、`parentTaskId` 添加索引；监控常用查询 |
| 回滚困难 | 迁移失败无快速回退手段 | 迁移前导出 Snapshot，提供 rollback 脚本 |

## 9. 开发注意事项

1. 在所有模型移除 `taskKind` 前，保持旧逻辑只读，避免同时写旧字段。
2. 迁移完成后立即运行 `dart format`、`flutter analyze`、`flutter test` 作为验收门槛。
3. 更新文档：
   - `documents/spec/projects/251102-project-milestone-split/02_acceptance_tests.md`
   - 相关 PR/变更说明需附迁移脚本与执行记录。
4. 后续新增字段按新表结构直接添加，避免再回写 `TaskEntity`。

## 10. 未决问题

1. **任务父级约束**：是否允许任务直接挂在里程碑下再有子任务？（当前假设允许，需要确认业务规则。）
2. **日志差异化**：项目/里程碑是否需要与任务不同的日志 schema？若相同可共用结构；若不同需单独设计。
3. **外部接口**：如果未来导出或同步到外部系统，是否需要统一视图？建议后续通过聚合层提供 `ProjectTimeline` API。

---

该设计提供了拆表后的完整蓝图：数据结构、迁移路径、服务/UI 重构、测试与风险控制均给出了可执行方案。下一步建议先评审迁移脚本与实体定义，确认无争议后进入 P0 阶段实施。

