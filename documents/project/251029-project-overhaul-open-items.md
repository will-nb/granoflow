# 251029 Projects 改造剩余事项清单

本清单用于跟踪 `251029-project-overhaul` 设计/迭代中尚未完成的工作项，完成后请勾选并在相关 PR 或文档中引用。

## 功能缺口
- [ ] 项目/里程碑弹窗支持描述字段 **60,000** 字上限，默认展示 255 字并提供“展开全部”交互，同时在项目视图内显示描述折叠区。
- [ ] 项目卡片加入右滑手势，提供“归档 / 暂缓”操作；“暂缓”应弹出确认提示，与设计稿文案一致。
- [ ] 实现“暂缓”时的提示条（毛玻璃样式）及动画反馈，符合设计稿动效要求。
- [ ] 快速任务卡片左侧根据执行标签（`#timed/#fragmented/#waiting`）渲染番茄钟 / 闪电 / 握手机图标。
- [ ] 项目/里程碑卡片展示层级色条时，补充逾期与完成状态的视觉样式（暖色渐层、淡化处理），与设计稿保持一致。

## 数据 / 服务层待办
- [ ] `Task` / `TaskDraft` / `TaskEntity` 持久化 `description` 字段，支持长文本存取；代码生成文件需重新跑 `build_runner`。
- [ ] `TaskService` 新增 `snoozeProject`（暂缓）方法：在用户确认后将 `dueAt` 顺延一年，同时追加 `TaskLogEntry(action: 'deadline_snoozed')`。
- [ ] `TaskService.updateDetails` 支持外部传入日志列表 append，而非覆盖；确保父子任务 deadline 同步时写入日志不丢失既有记录。
- [ ] 项目创建蓝图写入 description 字段，并将“描述已填写”记录改为真实字段存储。
- [ ] 为后续多语言描述做准备：确认 `l10n` 文案涵盖新增提示与按钮。

## 测试与验收
- [ ] **Unit**：TaskService 暂缓逻辑应写入日志、顺延一年、避免重复顺延；Task description 持久化的序列化/反序列化测试。
- [ ] **Widget**：`ProjectCreateSheet` 验证描述展开、标签互斥、deadline 自动同步；`ProjectsDashboard` 验证进度条、手风琴展开、归档/暂缓交互。
- [ ] **手动验收**：按照设计稿流程检查项目创建、里程碑同步、快速任务转换、归档/暂缓提示，以及多语言显示。
- [ ] 执行 `flutter analyze`、`flutter test --tags projects`、`flutter test` 全量回归。

## 文档同步
- [ ] 更新 `documents/spec/projects/design/251029-project-overhaul.yaml`：标记已落地部分，补充描述字段、暂缓动效等细化文案。
- [ ] 更新 `documents/spec/projects/iteration/251029-project-overhaul.yaml`：将状态改为 **in_progress**，记录新增代码/测试范围与风险缓解措施。
- [ ] 在验收完成后补充 `documents/spec/projects/iteration/251029-project-overhaul.yaml` 的 verification 结果，并添加最新日期的手工验收记录。
- [ ] 若新增测试需说明，请增补 `documents/test_reports/` 或相应 README。

> 注：完成任一条目时，请同步在此文件勾选，并在提交描述中引用对应小节，确保可追溯性。
