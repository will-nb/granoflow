import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/main_drawer.dart';
import '../widgets/page_app_bar.dart';
import 'projects/projects_dashboard.dart';
import 'quick_tasks/quick_add_sheet.dart';
import 'views/task_section_panel.dart';

class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
  bool _showProjects = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editActions = ref.watch(taskEditActionsNotifierProvider);
    final bool showLinearProgress = !_showProjects && editActions.isLoading;

    // 动态获取有任务的分组
    final sectionMetas = <_SectionMeta>[
      _SectionMeta(
        section: TaskSection.overdue,
        title: l10n.plannerSectionOverdueTitle,
      ),
      _SectionMeta(
        section: TaskSection.today,
        title: l10n.plannerSectionTodayTitle,
      ),
      _SectionMeta(
        section: TaskSection.tomorrow,
        title: l10n.plannerSectionTomorrowTitle,
      ),
      _SectionMeta(
        section: TaskSection.thisWeek,
        title: l10n.plannerSectionThisWeekTitle,
      ),
      _SectionMeta(
        section: TaskSection.thisMonth,
        title: l10n.plannerSectionThisMonthTitle,
      ),
      _SectionMeta(
        section: TaskSection.later,
        title: l10n.plannerSectionLaterTitle,
      ),
    ];

    return GradientPageScaffold(
      appBar: const PageAppBar(title: 'Tasks'),
      drawer: const MainDrawer(),
      body: GestureDetector(
        onTap: () {
          // 点击空白区域时移除焦点
          FocusManager.instance.primaryFocus?.unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
        children: [
          // 模式切换控件
          if (showLinearProgress) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: <bool>[!_showProjects, _showProjects],
                  onPressed: (index) {
                    setState(() {
                      _showProjects = index == 1;
                    });
                  },
                  constraints: const BoxConstraints(
                    minHeight: 36,
                    minWidth: 72,
                  ),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(l10n.taskListModeTask),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(l10n.taskListModeProject),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _showProjects
                ? const ProjectsDashboard()
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: sectionMetas
                        .map(
                          (meta) => Consumer(
                            builder: (context, ref, child) {
                              final tasksAsync = ref.watch(
                                taskSectionsProvider(meta.section),
                              );
                              return tasksAsync.when(
                                data: (tasks) {
                                  if (tasks.isEmpty)
                                    return const SizedBox.shrink();
                                  return TaskSectionPanel(
                                    key: ValueKey(
                                      '${meta.section}-${_showProjects.toString()}',
                                    ),
                                    section: meta.section,
                                    title: meta.title,
                                    editMode: _showProjects,
                                    onQuickAdd: () =>
                                        _handleQuickAdd(context, meta.section),
                                    tasks: tasks,
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _handleQuickAdd(
    BuildContext context,
    TaskSection section,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<QuickAddResult>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => QuickAddSheet(section: section),
    );
    if (result == null) {
      return;
    }

    final taskService = ref.read(taskServiceProvider);
    try {
      final newTask = await taskService.captureInboxTask(title: result.title);
      await taskService.planTask(
        taskId: newTask.id,
        dueDateLocal: result.dueDate,
        section: section,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.taskListAddedToast)));
    } catch (error, stackTrace) {
      debugPrint('Failed to add task: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.taskListAddError)));
    }
  }
}

class _SectionMeta {
  const _SectionMeta({required this.section, required this.title});

  final TaskSection section;
  final String title;
}
