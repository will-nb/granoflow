## 验收测试（Seed 导入）

目标：首次启动时根据系统语言导入种子数据，且导入过程可重入、幂等，不产生重复数据；标签、任务、收集箱均可在 UI 中正确显示。

### 预置条件
- 本地数据库为空（执行 `scripts/anz clean` 会自动清空 ObjectBox 数据库并重建项目缓存）。
- 系统语言为 zh_CN（或 en/zh_HK，断言逻辑相同，仅断言数量）。

### 验收项
1) 首次启动自动导入
   - 运行 `flutter run -d macos`，启动日志应包含：
     - `SeedImportService: Starting import for locale: zh_CN`
     - `SeedImportService: Pre-import state - Tasks: X, Projects: Y`
     - `SeedImportService: Seed data - Tasks: N, Projects: M, ...`
     - `SeedImportService: Post-import state - Tasks: X+N (+N), Projects: Y+M (+M)`
     - `SeedImportService: Import completed successfully`
   - 不应出现异常堆栈。

2) 标签导入成功
   - 日志包含：
     - `SeedImportService: Initializing tags from configuration`
     - `SeedImportService: Tags initialized successfully`
   - UI：在 Inbox 展开区能看到 `@home/@desk/...` 和 `#urgent/#important/...` 的 chips。

3) 任务导入成功
   - 日志包含：
     - `SeedImportService: Applying tasks (N tasks)`
     - `SeedImportService: Tasks applied in Xms`
   - UI：Tasks 页面 `Today` 区有任务（因为导入时为种子任务设置了 `dueAt=今天`）。
   - 验证：`taskRepository.listAll()` 返回的任务数量与种子数据一致。

4) 收集箱导入成功
   - 日志包含：
     - `SeedImportService: Applying inbox items (N items)`
     - `SeedImportService: Inbox items applied in Xms`
   - UI：Inbox 有示例任务。
   - 验证：`taskRepository.watchInbox()` 返回的任务列表不为空。

5) 项目与里程碑导入成功
   - 日志包含项目、里程碑的导入信息。
   - 验证：`projectRepository.listAll()` 和 `milestoneRepository.listAll()` 返回的数据不为空。
   - 验证：里程碑的 `projectId` 正确关联到项目。

6) 任务可见性验证
   - 验证：`taskRepository.listRoots()` 返回根任务列表。
   - 验证：`taskRepository.listChildren(parentId)` 返回子任务列表。
   - 验证：`taskRepository.findBySlug(slug)` 可以通过 seedSlug 查找任务。
   - 验证：`taskRepository.watchSection(section)` 可以监听不同 section 的任务变化。

7) 幂等与并发保护
   - 热重启或再次进入首页，日志可能出现多次 `SeedImportService: Starting import`，但：
     - 仅第一次出现 `Starting import ...`，其余出现 `Import already in progress, skipping` 或 `Already imported=true`。
   - UI/数据库中不应出现重复的 Inbox/Task 记录（按 `seedSlug` 唯一）。

8) 导入前后计数比对
   - 日志应显示导入前后的任务和项目数量对比。
   - 如果导入数量与预期不符，应显示警告信息。

### 回归测试命令
```bash
# 方式1：手动测试
scripts/anz clean
flutter run -d macos

# 方式2：自动化集成测试
scripts/anz test:macos
```

### 集成测试
- `integration_test/seed_import_test.dart`: 验证基本导入功能
- `integration_test/seed_import_visibility_test.dart`: 验证任务在 UI 中的可见性
- `integration_test/seed_import_duplicate_test.dart`: 验证幂等性

### 通过准则
- 日志与 UI 符合上述断言；
- 无重复数据；
- 标签 chips 可见；
- 任务、项目、里程碑数量与种子数据一致；
- 所有 watch 方法正常工作；
- 集成测试全部通过。

### 备注
- 当前使用 ObjectBox 作为数据库，所有操作通过 DatabaseAdapter 抽象层进行。
- 导入过程使用 DatabaseAdapter 的 CRUD 方法，确保抽象层正确性。
- 导入前后会记录数据计数，便于诊断问题。

