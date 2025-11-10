# ObjectBox 迁移执行计划（Milestone/Project/Task）

最后更新：2025-11-08

## 参考文档
- 主蓝图：`documents/json5/repository/business-id-as-primary-key.json5`（ObjectBox + 业务 ID 迁移权威规划）

## 当前阶段
- [x] 步骤 1：分支创建与依赖替换
- [x] 步骤 2：删除 Isar 代码并搭建 ObjectBox 框架
- [ ] 步骤 3：实现 ObjectBox Repository 并接入 Provider
- [ ] 步骤 4：模型与 Service 层统一 String id
- [ ] 步骤 5：UI 与 Provider 层同步
- [ ] 步骤 6：测试与脚本更新
- [ ] 步骤 7：全面验证与文档收尾

> 每完成一个步骤，请勾选对应复选框并在备注区记录验证结果（含 `flutter analyze` / `flutter test` 等输出）。

## 阶段目标
- [ ] 梳理并补齐实体字段与关联定义（步骤 2 核心）
- [ ] 迁移仓库（repository）读写逻辑到 ObjectBox（步骤 3 核心）
- [ ] 为新逻辑补充/调整测试（单元与集成）（步骤 6 核心）
- [ ] 同步文档，记录迁移影响（步骤 7 核心）

## 当前状态速记
- [x] `MilestoneEntity`、`ProjectEntity`、`TaskEntity` 已建立基础字段，`tags` 使用 `stringVector`。
- [ ] 关联（`ToOne`/`ToMany`）尚未定义，`logs` 暂为 `@Transient`。
- [ ] `converters.dart` 中仅有状态枚举转换，尚未覆盖全部枚举/自定义类型。
- [x] UI 层字符串 ID 迁移（任务/拖拽/计时器/项目树等组件）已完成，项目入口操作同步改为字符串 ID。

## 待办清单（文件粒度）

### 抽象层与基础设施
- [x] `lib/data/database/database_adapter.dart`：补全接口定义（CRUD、批量、事务、查询、Stream）。_接口已定义，后续如有新增能力再扩展。_
- [x] `lib/data/database/query_builder.dart`：定义抽象查询构建器（filter/sort/limit/offset）。_接口保持函数式 API，不再调整。_
- [x] `lib/data/database/objectbox_adapter.dart`：实现 `DatabaseAdapter`（封装 Store/Box/Query/事务/监听）。_已接入 ObjectBox 事务与监听。_
- [x] `lib/data/database/objectbox_query_builder.dart`：实现 `QueryBuilder` 抽象接口。_当前采用内存筛选/排序，后续可视性能优化。_
- [ ] `scripts/anz` 及 `scripts/anz_modules/**`：替换数据生成/诊断命令为 ObjectBox 版本。

-### 实体定义
- [x] `lib/data/objectbox/converters.dart`：补齐所有需要的转换器（含 TaskStatus 等）。_状态字段暂以 index 存储，供 Repository 层转换。_
- [ ] `lib/data/objectbox/project_entity.dart`：统一主键字段为字符串业务 ID，定义与 `MilestoneEntity` 的关系，确定日志存储策略。_主键/状态字段已调整；日志拆分至 `ProjectLogEntity`；待补 `ToMany` 关联。_
- [ ] `lib/data/objectbox/milestone_entity.dart`：统一主键字段、补齐 `project` 关联与任务集合、日志方案。_主键/状态字段已调整；与项目的 `ToOne` 已建立；日志拆分至 `MilestoneLogEntity`；待补任务集合关联。_
- [ ] `lib/data/objectbox/task_entity.dart`：清理 Isar 遗留字段、建立父子任务与项目/里程碑关联、日志方案。_主键/状态字段已调整；`project`/`parent`/`milestone` 关系已定义；日志拆分至 `TaskLogEntity`；待补 `@Backlink` 级联策略。_
- [x] `lib/data/objectbox/preference_entity.dart`、`focus_session_entity.dart`、`tag_entity.dart`、`task_template_entity.dart`、`seed_import_log_entity.dart`：根据主文档创建或补全。_全部新增完成，ID 统一为 String。_
- [x] `lib/data/objectbox/*_log_entity.dart`：如采用日志独立表，新增对应实体及索引（待方案确认）。_`ProjectLogEntity`/`MilestoneLogEntity`/`TaskLogEntity` 已创建。_
- [ ] `objectbox-model.json` / `objectbox.g.dart`：确保生成并纳入版本控制。

### 数据访问层
- [ ] `lib/data/repositories/objectbox/objectbox_project_repository.dart`：实现 CRUD、关系维护、Stream 监听。
- [ ] `lib/data/repositories/objectbox/objectbox_milestone_repository.dart`：实现 CRUD、日志支持、关联维护。
- [ ] `lib/data/repositories/objectbox/objectbox_task_repository.dart`：实现 CRUD、层级处理、批量操作。
- [ ] 其他 ObjectBox repository 文件：Preference、Tag、TaskTemplate、FocusSession、Seed 等实现。
- [ ] `lib/data/repositories/*.dart`：现有接口调整为依赖 `DatabaseAdapter`，移除 Isar 特殊方法。
- [ ] 清理/更新旧迁移脚本与引用（例如 `task_table_split` 等）。

### 模型与服务层
- [ ] `lib/data/models/*.dart`：统一所有实体主键与关联字段为 `String`（UUID v4），删除 `taskId/projectId/milestoneId` 等别名。
- [ ] `lib/data/models/*_update.dart`：同步字段类型。
- [ ] `lib/core/utils/id_generator.dart`：重命名 `generateId()` → `generate()` 并保证返回 UUID v4。
- [ ] `lib/core/services/**`：CRUD、状态、层级、拖拽、排序、导入导出、种子导入等服务全部改用字符串 ID，调整依赖的新 repository。
- [ ] `lib/core/providers/**`：更新 repository/service provider 注入逻辑，移除 Isar provider。
- [ ] `lib/main.dart`：初始化 `ObjectBoxAdapter`，替换 Isar 初始化流程。

### UI 与脚本
- [ ] `lib/presentation/**`：确保所有组件/状态使用字符串 ID，更新 key/trackBy/Map 逻辑。
- [ ] `scripts/anz`：命令改为执行 ObjectBox 生成/诊断。
- [ ] `scripts/anz_modules/**`：同步替换相关命令。

### 测试与文档
- [ ] `test/**`：更新所有单元测试和 Widget 测试至字符串 ID，新增 ObjectBox Adapter/Repository 测试。
- [ ] `integration_test/**`：制定但暂不执行的 ObjectBox 集成测试用例（setup/business_id_flow/diagnose_16kb）。
- [ ] `documents/spec/**` 与 `documents/README.md` 等：补充迁移后的行为说明、验收标准。
- [ ] `README.md` / `CHANGELOG`：记录 ObjectBox 环境准备与 Breaking Changes。
- [ ] `documents/spec/YYMMDD-<module>/02_acceptance_tests.md`：更新对应验收条目。
- [ ] `documents/project/` / `documents/plan-logs/`：如有需要，补写迁移日志。

## 关键决策点
1. **日志存储方式**  
   - 选项 A：独立 `LogEntity`，通过 `ToMany` 关联。  
   - 选项 B：序列化到单字段（JSON/BLOB）。  
   - 需评估查询需求与性能，确认后执行。
2. **任务层级关系**  
   - ObjectBox 是否使用 `ToOne<TaskEntity>` 表示父任务？  
   - 是否保留 `parentTaskId` 以兼容外部接口？
3. **主键策略冲突**  
   - 主文档要求 `@Id(assignable: true) String id`，ObjectBox 官方仅支持整数型 `@Id`。  
   - 待确认是否采用双主键方案（内部自增 ID + 业务 String id），或探索 ObjectBox `@Unique` + 自定义 ID 字段。
4. **数据迁移方案**  
   - 从旧 Isar 导出的数据如何迁移到 ObjectBox（脚本/一次性工具）。

## 计划执行顺序（建议）
1. 定稿实体结构与日志方案（含 converters）。
2. 调整仓库层，保证编译与单元测试通过。
3. 扩展集成测试验证真实流程。
4. 更新文档与迁移脚本说明。

> 每完成一项子任务，请在本文件相应复选框标记为完成，并注明关键信息（如相关 commit、测试证据）。

## 步骤验证记录
- 步骤 2 预期验证：`flutter analyze`、`flutter test test/data/database/`（只覆盖数据库层测试）。**状态：待统一补跑（Step 3 完成后执行）**
- 步骤 3 预期验证：`flutter analyze`、`flutter test test/data/repositories/objectbox_*_repository_test.dart`。**状态：未执行**
- 步骤 4 预期验证：`flutter analyze`、`flutter test test/core/services/`。**状态：未执行**
- 步骤 5 预期验证：`flutter analyze`、`flutter test test/presentation/`。**状态：未执行**
- 步骤 6 预期验证：`flutter analyze`、`flutter test --coverage`。**状态：未执行**
- 步骤 7 预期验证：`flutter analyze`、`flutter test`（全量）、文档更新记录。**状态：未执行**

## 开放问题与待确认
- ObjectBox 字符串主键实现策略待确认（内部 int ID 与业务 String ID 的折中方案）。
- 日志字段存储方式（独立实体 vs JSON/BLOB）待决策。
- 集成测试执行时点与环境准备（特别是 Android 16KB Emulator 手动验证）需在步骤 6 前确定。

> 每完成一项子任务，请在本文件相应复选框标记为完成，并注明关键信息（如相关 commit、测试证据）。

## 中断恢复指引
1. 执行 `git status`，确认环境仍在 `refactor/objectbox-business-id` 分支且改动未丢失。  
2. 回顾本文件顶部“当前阶段”“待办清单”，明确目前停留在步骤 4（模型与 Service 层统一 String id）。  
3. 快速检查关键模型文件（`lib/data/models/project.dart`、`milestone.dart`、`task.dart`、`task_update.dart`、`task_template.dart`、`focus_session.dart`、`tag.dart`、`preference.dart`、`seed_import_log.dart`、`metric_snapshot.dart`），确认主键与关联字段均已切换为字符串；必要时利用 `rg "int id" lib/data/models`、`rg "taskId" lib/data/models` 等命令排查遗留。  
4. 按“模型与服务层”子任务顺序继续：先完成模型清理，再迁移服务与仓库接口，完成一项即在此文档勾选并记录关键影响。  
5. 当模型与服务层统一完成后，再回到仓库实现、Provider 接入及 UI 层更新，最后统一执行 `flutter analyze` 和必要测试。

