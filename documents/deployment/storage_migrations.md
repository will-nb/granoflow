# GranoFlow 数据模式与迁移策略

## 模式版本总览
| 版本 | 生效日期 | 说明 |
| --- | --- | --- |
| v1 | 2025-10-23 | 首次发布。定义任务、标签、模板、偏好、计时会话与种子导入日志等集合。 |

当前应用的 `IsarSchema.version = 1`。所有集合（`TaskEntity`、`TagEntity`、`TaskTemplateEntity`、`FocusSessionEntity`、`PreferenceEntity`、`SeedImportLogEntity`）均处于同一版本号，后续升级需同步维护。

## v1 模式详情
### TaskEntity
- 主键：`id (autoIncrement)`
- 关键字段：`taskId`（用户可见 ID）、`status`（枚举 `TaskStatus`）、`parentId`（树形结构）、`sortIndex`（排序调度）。
- 元数据：`createdAt`、`updatedAt`。
- 扩展：`tags`（字符串列表）、`templateLockCount`、`seedSlug`、`allowInstantComplete`。

### TagEntity
- 主键：`id (autoIncrement)`
- 字段：`slug`（唯一）、`name`、`type`（区分 context / priority）、`createdAt`。

### TaskTemplateEntity
- 主键：`id (autoIncrement)`
- 字段：`slug`、`title`、`description`、`suggestedDurationMinutes`、`steps`（字符串列表）、`createdAt`、`updatedAt`、`usageCount`。

### FocusSessionEntity
- 主键：`id (autoIncrement)`
- 字段：`taskId`、`startedAt`、`endedAt`、`actualMinutes`、`estimateMinutes`、`alarmEnabled`、`transferredToTaskId`、`reflectionNote`。

### PreferenceEntity
- 主键：`id (autoIncrement)`
- 字段：`localeCode`、`themeMode`（枚举 `ThemeMode`）、`fontScale`、`updatedAt`。

### SeedImportLogEntity
- 主键：`id (autoIncrement)`
- 字段：`seedVersion`、`localeCode`、`importedAt`、`checksum`。

## 迁移策略
1. **版本递增**
   - 修改任一集合结构（新增字段、调整索引、修改枚举）时，将 `Isar.open` 中的 `schemas` 版本号递增（例如 `v2`）。
   - 在 `documents/storage_migrations.md` 中记录变更缘由、字段影响和回滚策略。

2. **数据演化流程**
   1. 创建 `migration_scripts/v{n}_to_v{n+1}.dart`，编写 `Isar` 的 `writeTxn` 脚本，对旧数据补全默认值或重构结构。
   2. 在 `SeedImportService` 中验证种子数据与新结构兼容（必要时升级 `assets/seeds/version.json`）。
   3. 编写/更新集成测试（`integration_test/data_migrations/`）验证升级流程。

3. **安全防护**
   - 使用 `isar.autoIncrement` 的集合，在迁移脚本中避免覆盖 `id`，仅追加或更新字段。
   - 新增枚举成员时同步更新 `TaskStatus` 等 Dart 枚举，确保序列化一致。
   - 迁移期间若需删除字段，先引入废弃标记（`deprecatedAt`）并清理数据，再在后续版本真正移除。

4. **回滚策略**
   - 发布前保留旧版本 `Isar` 备份（`isar.copyToFile`）。
   - 若迁移失败，阻止应用继续写入，提示用户提交日志；通过热修复或补丁版本执行修复脚本。

## 执行清单
- [x] 定义 v1 模式与字段。
- [ ] 为未来 v2 设计迁移脚本模板。
- [ ] 建立 `integration_test/data_migrations/` 目录与首个基线测试。

> 后续版本需在本文件最前方追加版本记录，并在迁移完成后勾选执行清单中的相关项。
