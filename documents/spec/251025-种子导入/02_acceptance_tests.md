## 验收测试（Seed 导入）

目标：首次启动时根据系统语言导入种子数据，且导入过程可重入、幂等，不产生重复数据；标签、任务、收集箱均可在 UI 中正确显示。

### 预置条件
- 本地数据库为空（执行 `scripts/anz clean` 会自动清空 Isar 数据库并重建项目缓存）。
- 系统语言为 zh_CN（或 en/zh_HK，断言逻辑相同，仅断言数量）。

### 验收项
1) 首次启动自动导入
   - 运行 `flutter run -d macos`，启动日志应包含：
     - `SeedImportService: Loading payload for locale=zh_CN`
     - `SeedImportService: Version recorded, import complete!`
   - 不应出现异常堆栈。

2) 标签导入成功
   - 日志包含：
     - `TagRepository.ensureSeeded: incoming=11`
     - `TagRepository.ensureSeeded: done (created=11, updated=0, total=11)`
     - `TagRepository.listByKind(TagKind.context): count>0`
   - UI：在 Inbox 展开区能看到 `@home/@desk/...` 和 `#urgent/#important/...` 的 chips。

3) 任务导入成功
   - UI：Tasks 页面 `Today` 区有 5 条任务（因为导入时为种子任务设置了 `dueAt=今天`）。

4) 收集箱导入成功
   - UI：Inbox 有 5 条示例任务。

5) 幂等与并发保护
   - 热重启或再次进入首页，日志可能出现多次 `SeedInitializer: locale = zh_CN`，但：
     - 仅第一次出现 `Starting import ...`，其余出现 `Import already in progress, skipping` 或 `Already imported=true`。
   - UI/数据库中不应出现重复的 Inbox/Task 记录（按 `seedSlug` 唯一）。

### 回归测试命令
```bash
scripts/anz clean
flutter run -d macos
```

### 通过准则
- 日志与 UI 符合上述断言；
- 无重复数据；
- 标签 chips 可见；
- Today 任务数=5，Inbox 任务数=5。

### 备注
- 当前仓库存在与主题配色相关的历史测试失败（core/theme 测试）。与本改动无关，建议另起任务对比设计规范更新测试快照或调整主题 token。

