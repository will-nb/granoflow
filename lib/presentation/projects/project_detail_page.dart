import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/providers/task_query_providers.dart';
import '../../data/models/milestone.dart';
import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import '../tasks/widgets/empty_placeholder.dart';
import '../tasks/quick_tasks/quick_add_sheet.dart';
import '../widgets/error_banner.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/main_drawer.dart';
import '../widgets/page_app_bar.dart';
import 'utils/milestone_date_utils.dart';
import 'widgets/milestone_section_panel.dart';
import 'widgets/project_info_header.dart';

/// 项目详情页
///
/// 显示项目信息、进度和按里程碑分区的任务列表
class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // 获取项目信息
    final projectAsync = ref.watch(projectProvider(projectId));

    // 获取项目里程碑列表
    final milestonesAsync = ref.watch(projectMilestonesDomainProvider(projectId));

    // 在项目详情页加载时，确保任务都有里程碑
    projectAsync.whenData((project) async {
      if (project != null) {
        final projectService = await ref.read(projectServiceProvider.future);
        await projectService.ensureTasksHaveMilestone(projectId);
      }
    });

    return GradientPageScaffold(
      appBar: PageAppBar(
        title: projectAsync.when(
          data: (project) => project?.title ?? l10n.projectListTitle,
          loading: () => l10n.projectListTitle,
          error: (_, __) => l10n.projectListTitle,
        ),
      ),
      drawer: const MainDrawer(),
      body: projectAsync.when(
        data: (project) {
          if (project == null) {
            return Center(
              child: EmptyPlaceholder(
                message: l10n.projectNotFound,
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              // 点击页面空白区域时，移除输入框的焦点（收起键盘）
              FocusManager.instance.primaryFocus?.unfocus();
            },
            behavior: HitTestBehavior.translucent,
            child: CustomScrollView(
              slivers: [
                // 项目信息头部
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: ProjectInfoHeader(project: project),
                  ),
                ),
                // 里程碑分区列表
                milestonesAsync.when(
                  data: (milestones) {
                    if (milestones.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: EmptyPlaceholder(
                            message: l10n.projectNoMilestonesHint,
                          ),
                        ),
                      );
                    }

                    // 按截止日期和 sortIndex 排序里程碑
                    final sortedMilestones = List<Milestone>.from(milestones);
                    sortedMilestones.sort((a, b) {
                      // 首先按截止日期排序（升序）
                      if (a.dueAt != null && b.dueAt != null) {
                        final dateCompare = a.dueAt!.compareTo(b.dueAt!);
                        if (dateCompare != 0) {
                          return dateCompare;
                        }
                      } else if (a.dueAt != null) {
                        return -1; // a 有截止日期，b 没有，a 排在前面
                      } else if (b.dueAt != null) {
                        return 1; // b 有截止日期，a 没有，b 排在前面
                      }
                      // 如果截止日期相同或都没有，按 sortIndex 排序（升序）
                      return a.sortIndex.compareTo(b.sortIndex);
                    });

                    return SliverList(
                      delegate: SliverChildListDelegate(
                        sortedMilestones.map((milestone) {
                          return MilestoneSectionPanel(
                            key: ValueKey('milestone-${milestone.id}'),
                            milestone: milestone,
                            onQuickAdd: () => _handleQuickAdd(context, ref, project, milestone),
                          );
                        }).toList(),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (error, stackTrace) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ErrorBanner(
                        message: l10n.milestonesLoadError('$error'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: ErrorBanner(
            message: l10n.projectLoadError('$error'),
          ),
        ),
      ),
    );
  }
}

/// Provider for getting a single project by ID
final projectProvider = FutureProvider.family<Project?, String>((ref, projectId) async {
  final projectService = await ref.read(projectServiceProvider.future);
  return projectService.findById(projectId);
});

/// 处理快速添加任务到里程碑
Future<void> _handleQuickAdd(
  BuildContext context,
  WidgetRef ref,
  Project project,
  Milestone milestone,
) async {
  final l10n = AppLocalizations.of(context);
  final mediaQuery = MediaQuery.of(context);
  final isLandscape = mediaQuery.orientation == Orientation.landscape;
  final maxHeight = isLandscape
      ? mediaQuery.size.height * 0.5
      : double.infinity;

  // 获取里程碑的任务列表，计算默认日期
  DateTime? defaultDueDate;
  try {
    final taskRepository = await ref.read(taskRepositoryProvider.future);
    final tasks = await taskRepository.listTasksByMilestoneId(milestone.id);
    defaultDueDate = MilestoneDateUtils.calculateMilestoneDefaultDueDate(tasks);
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint(
        '[ProjectDetailPage._handleQuickAdd] {event: calculateDefaultDate:failed, milestoneId: ${milestone.id}, error: $e, stackTrace: $stackTrace}',
      );
    }
    // 如果获取任务列表失败，使用明天作为默认日期
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    defaultDueDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59, 999);
  }

  // 弹出底部弹窗，让用户输入任务信息
  final result = await showModalBottomSheet<QuickAddResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示器
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // QuickAddSheet（传入计算出的默认日期）
            QuickAddSheet(
              section: null,
              defaultDate: defaultDueDate,
            ),
            // 底部安全区域
            SizedBox(height: mediaQuery.viewPadding.bottom + 20),
          ],
        ),
      ),
    ),
  );

  // 如果用户取消输入，就不做任何操作
  if (result == null || !context.mounted) {
    return;
  }

  final taskService = await ref.read(taskServiceProvider.future);
  try {
    // 创建新任务并分配到里程碑
    final newTask = await taskService.captureInboxTask(title: result.title);
    
    // 更新任务的 projectId 和 milestoneId
    await taskService.updateDetails(
      taskId: newTask.id,
      payload: TaskUpdate(
        projectId: project.id,
        milestoneId: milestone.id,
        dueAt: result.dueDate, // 如果用户选择了日期，使用用户选择的日期；否则使用里程碑的截止日期（如果有）
      ),
    );

    if (!context.mounted) {
      return;
    }

    // 显示成功提示消息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.taskListAddedToast)),
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Failed to add task to milestone: $error\n$stackTrace');
    }
    if (!context.mounted) {
      return;
    }
    // 显示失败提示消息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.loadFailed)),
    );
  }
}

