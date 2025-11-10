# Drift 迁移 - AI 开发前需要确认的问题清单

## 当前文档明确度评估

### ✅ 已明确的部分

1. **所有 Repository 方法**：已明确列出所有方法及其实现逻辑
2. **所有 Table 定义**：已明确列出所有字段、类型、外键关系
3. **数据迁移流程**：已明确迁移顺序、验证步骤、错误处理
4. **测试策略**：已明确单元测试和集成测试的用例
5. **实现步骤**：已明确 5 个阶段的详细任务

### ⚠️ 需要确认的问题

#### 1. 依赖版本号（高优先级）

**问题**：文档中未明确指定 Drift 相关依赖的版本号

**需要确认**：
- `drift` 的版本号（建议使用最新稳定版，如 `^2.14.0`）
- `drift_dev` 的版本号（需要与 `drift` 版本匹配）
- `sqlite3_flutter_libs` 的版本号（建议使用 `^2.3.0`）
- `drift_web` 的版本号（建议使用 `^2.14.0`）

**建议**：在 `modifications` 中明确指定版本号，例如：
```yaml
"添加 drift: ^2.14.0 和 drift_dev: ^2.14.0 依赖（用于代码生成）。",
"添加 sqlite3_flutter_libs: ^2.3.0 依赖（用于移动端 SQLite）。",
"添加 drift_web: ^2.14.0 依赖（用于 Web 平台 IndexedDB）。",
```

#### 2. 数据库初始化细节（高优先级）

**问题**：文档中未明确说明如何在不同平台初始化 Drift 数据库

**需要确认**：
- Web 平台：如何使用 `drift_web` 初始化 IndexedDB？
- 移动端：数据库文件路径如何配置？使用 `path_provider` 的哪个目录？
- 数据库文件名：使用什么名称？（如 `granoflow.db`）
- 数据库版本：初始版本号是多少？如何管理版本升级？

**建议**：在 `lib/data/drift/database.dart` 的 details 中补充：
```yaml
"Web 平台初始化：使用 drift_web 的 WebDatabase 构造函数，数据库名称使用 'granoflow'。",
"移动端初始化：使用 path_provider 的 getApplicationSupportDirectory() 获取目录，数据库文件名为 'granoflow.db'。",
"数据库版本：初始版本为 1，使用 @DriftDatabase(version: 1) 注解。",
"版本升级：后续版本变更时，在 onUpgrade 方法中定义迁移逻辑。",
```

#### 3. 实体到模型的转换逻辑（中优先级）

**问题**：文档中提到了转换方法，但未明确转换的具体实现

**需要确认**：
- 转换方法的位置：是在 Repository 中实现，还是在单独的转换器类中？
- 转换方法的命名：使用 `_toModel` 还是 `_fromEntity`？
- 日志（Log）的转换：如何从 LogEntity 转换为 LogEntry？
- 枚举转换：TaskStatus、ProjectStatus 等枚举如何转换？

**建议**：在 Repository 的 details 中补充：
```yaml
"转换方法命名：使用 _toTask、_toProject 等命名（Entity → Model），在 Repository 类中实现。",
"日志转换：TaskLogEntity → TaskLogEntry，ProjectLogEntity → ProjectLogEntry，MilestoneLogEntity → MilestoneLogEntry。",
"枚举转换：使用 converters.dart 中的转换器函数（taskStatusFromIndex、taskStatusToIndex 等）。",
```

#### 4. 外键约束处理（中优先级）

**问题**：文档中提到外键关系，但未明确是否启用外键约束

**需要确认**：
- SQLite 外键约束：是否启用 `PRAGMA foreign_keys = ON`？
- 外键约束的影响：如果启用，删除操作需要级联处理吗？
- 外键约束的性能影响：是否会影响插入/更新性能？

**建议**：在 `lib/data/drift/database.dart` 的 details 中补充：
```yaml
"外键约束：启用 SQLite 外键约束（PRAGMA foreign_keys = ON），确保数据完整性。",
"级联删除：配置外键的 onDelete 策略（CASCADE 或 RESTRICT），根据业务需求决定。",
"性能考虑：外键约束可能略微影响性能，但可以保证数据完整性，建议启用。",
```

#### 5. Repository 中的关系查询实现（中优先级）

**问题**：文档中提到关系查询，但未明确使用 JOIN 还是多次查询

**需要确认**：
- Task → Project：使用 JOIN 查询还是先查 Task 再查 Project？
- Task → Milestone：使用 JOIN 查询还是多次查询？
- 日志查询：如何加载 Task 的 logs？使用 JOIN 还是单独查询？

**建议**：在 Repository 的 details 中补充：
```yaml
"关系查询策略：优先使用 Drift 的 JOIN 查询（select(tasks).join([innerJoin(projects, ...)])），提高性能。",
"日志查询：Task 的 logs 使用单独查询（where taskId equals taskId），因为是一对多关系，JOIN 可能返回重复行。",
"性能优化：对于频繁查询的关系，考虑使用 JOIN；对于不频繁的关系，使用多次查询。",
```

#### 6. 代码生成配置（低优先级）

**问题**：文档中未明确 build_runner 的配置

**需要确认**：
- build.yaml 配置：是否需要创建 `build.yaml` 文件？
- 代码生成命令：使用 `build` 还是 `watch` 模式？
- 生成文件位置：生成的 `.drift.dart` 文件放在哪里？

**建议**：在实现步骤中补充：
```yaml
"代码生成配置：创建 build.yaml 文件（如果需要），配置代码生成选项。",
"代码生成命令：使用 'flutter pub run build_runner build --delete-conflicting-outputs' 生成代码。",
"生成文件位置：生成的 .drift.dart 文件与源文件放在同一目录。",
```

#### 7. 数据迁移的具体实现（中优先级）

**问题**：文档中提到了迁移流程，但未明确具体的实现细节

**需要确认**：
- 迁移时机：是在应用启动时自动迁移，还是用户手动触发？
- 迁移提示：如何提示用户进行迁移？使用对话框还是静默迁移？
- 迁移失败处理：如果迁移失败，如何回滚？如何通知用户？

**建议**：在 `lib/main.dart` 的 changes 中补充：
```yaml
"迁移检测：在应用启动时检测是否存在 ObjectBox 数据，如果存在且 Drift 数据库为空，提示用户迁移。",
"迁移提示：使用对话框提示用户是否迁移数据，提供'立即迁移'和'稍后提醒'选项。",
"迁移执行：用户确认后，调用迁移工具执行迁移，显示进度条。",
"迁移失败：如果迁移失败，记录错误日志，提示用户稍后重试，保留 ObjectBox 数据。",
```

#### 8. DatabaseConfig 的配置方式（中优先级）

**问题**：文档中提到通过配置切换数据库，但未明确配置的具体方式

**需要确认**：
- 配置存储：配置存储在什么地方？（环境变量、配置文件、SharedPreferences）
- 配置读取：如何读取配置？在应用启动时读取还是运行时读取？
- 配置切换：如何支持运行时切换？（开发环境可能需要）

**建议**：在 `lib/core/config/database_config.dart` 的 details 中补充：
```yaml
"配置存储：使用环境变量（kDebugMode 时）或 SharedPreferences（生产环境）存储配置。",
"配置读取：在应用启动时（main.dart）读取配置，创建对应的 DatabaseAdapter。",
"默认配置：生产环境默认使用 Drift，开发环境可以通过环境变量切换。",
"配置切换：支持通过环境变量 DATABASE_TYPE=objectbox|drift 切换数据库类型。",
```

#### 9. 索引策略（低优先级）

**问题**：文档中提到添加索引，但未明确哪些字段需要索引

**需要确认**：
- 主键索引：主键是否自动创建索引？
- 外键索引：外键字段是否需要显式创建索引？
- 查询字段索引：哪些字段需要索引？（如 status、sortIndex）

**建议**：在 Table 定义的 details 中已明确列出需要索引的字段，这部分已经足够明确。

#### 10. 类型转换器的实现细节（低优先级）

**问题**：文档中提到了类型转换器，但未明确具体的实现方式

**需要确认**：
- 枚举转换：使用 `intEnum<T>()` 还是自定义转换器？
- List<String> 转换：使用 JSON 存储还是关联表？
- DateTime 转换：Drift 的 `dateTime()` 是否足够？

**建议**：在 `lib/data/drift/converters.dart` 的 details 中已明确，这部分已经足够明确。

---

## 建议补充到文档的内容

### 1. 在 `modifications` 中补充依赖版本号

```yaml
changes: [
  "添加 drift: ^2.14.0 和 drift_dev: ^2.14.0 依赖（用于代码生成）。",
  "添加 sqlite3_flutter_libs: ^2.3.0 依赖（用于移动端 SQLite）。",
  "添加 drift_web: ^2.14.0 依赖（用于 Web 平台 IndexedDB）。",
  "保留 objectbox: ^4.0.0 和 objectbox_flutter_libs: ^4.0.0 依赖（迁移期间需要）。",
]
```

### 2. 在 `lib/data/drift/database.dart` 的 details 中补充初始化细节

```yaml
details: [
  // ... 现有内容 ...
  "Web 平台初始化：使用 drift_web 的 WebDatabase 构造函数，数据库名称使用 'granoflow'，使用 LazyDatabase 延迟初始化。",
  "移动端初始化：使用 path_provider 的 getApplicationSupportDirectory() 获取目录，数据库文件名为 'granoflow.db'，使用 LazyDatabase 延迟初始化。",
  "数据库版本：初始版本为 1，使用 @DriftDatabase(version: 1) 注解，后续版本变更时在 onUpgrade 方法中定义迁移逻辑。",
  "外键约束：在数据库打开时执行 PRAGMA foreign_keys = ON，启用外键约束，确保数据完整性。",
  "数据库连接：使用 LazyDatabase 延迟初始化，避免在应用启动时阻塞。",
]
```

### 3. 在 `lib/core/config/database_config.dart` 的 details 中补充配置方式

```yaml
details: [
  // ... 现有内容 ...
  "配置存储：使用环境变量（kDebugMode 时，通过 const String.fromEnvironment('DATABASE_TYPE')）或 SharedPreferences（生产环境）存储配置。",
  "配置读取：在应用启动时（main.dart）读取配置，根据配置创建对应的 DatabaseAdapter（ObjectBox 或 Drift）。",
  "默认配置：生产环境默认使用 Drift，开发环境可以通过环境变量 DATABASE_TYPE=objectbox|drift 切换数据库类型。",
  "配置切换：支持通过环境变量切换（开发环境），生产环境使用 SharedPreferences 存储用户选择。",
]
```

### 4. 在 `lib/main.dart` 的 changes 中补充迁移逻辑

```yaml
changes: [
  // ... 现有内容 ...
  "迁移检测：在应用启动时检测是否存在 ObjectBox 数据（检查 ObjectBox 数据库文件是否存在），如果存在且 Drift 数据库为空，提示用户迁移。",
  "迁移提示：使用对话框提示用户是否迁移数据，提供'立即迁移'和'稍后提醒'选项，用户选择后保存到 SharedPreferences。",
  "迁移执行：用户确认后，调用 ObjectBoxToDriftMigrator 执行迁移，显示进度条（使用 Stream 监听迁移进度）。",
  "迁移失败：如果迁移失败，记录错误日志，提示用户稍后重试，保留 ObjectBox 数据，不删除 ObjectBox 数据库。",
  "迁移成功：迁移成功后，标记迁移完成（保存到 SharedPreferences），后续启动不再提示。",
]
```

### 5. 在 Repository 的 details 中补充关系查询策略

对于 TaskRepository、ProjectRepository 等需要关系查询的 Repository，补充：
```yaml
"关系查询策略：优先使用 Drift 的 JOIN 查询（select(tasks).join([innerJoin(projects, tasks.projectId.equalsExp(projects.id))])），提高性能，减少数据库查询次数。",
"日志查询：Task 的 logs 使用单独查询（select(taskLogs).where((t) => t.taskId.equals(taskId))），因为是一对多关系，JOIN 可能返回重复行，单独查询更清晰。",
"性能优化：对于频繁查询的关系（如 Task → Project），使用 JOIN；对于不频繁的关系（如 Task → Logs），使用多次查询。",
```

---

## 总结

### 当前文档明确度：85%

**已明确**：
- ✅ 所有方法列表和实现逻辑
- ✅ 所有字段定义和类型
- ✅ 测试策略和用例
- ✅ 实现步骤和任务

**需要补充**：
- ⚠️ 依赖版本号（高优先级）
- ⚠️ 数据库初始化细节（高优先级）
- ⚠️ 数据迁移的用户交互（中优先级）
- ⚠️ 关系查询策略（中优先级）
- ⚠️ 配置管理方式（中优先级）

**建议**：在开始开发前，先补充上述高优先级和中优先级的问题，确保 AI 可以顺利实现。

