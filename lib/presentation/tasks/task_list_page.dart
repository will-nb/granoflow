import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/main_drawer.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/drag_to_remove_handler.dart';
import 'quick_tasks/quick_add_sheet.dart';
import 'views/task_section_panel.dart';

class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key, this.initialSection});

  /// 可选：通过路由参数传入的初始分区字符串（例如 today、tomorrow、thisWeek 等）
  final String? initialSection;

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<TaskSection, GlobalKey> _sectionKeys = {
    TaskSection.overdue: GlobalKey(),
    TaskSection.today: GlobalKey(),
    TaskSection.tomorrow: GlobalKey(),
    TaskSection.thisWeek: GlobalKey(),
    TaskSection.thisMonth: GlobalKey(),
    TaskSection.later: GlobalKey(),
  };

  bool _didAutoScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editActions = ref.watch(taskEditActionsNotifierProvider);
    final bool showLinearProgress = editActions.isLoading;

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
          if (showLinearProgress) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: sectionMetas
                        .expand((meta) => [
                              if (meta.section == sectionMetas.first.section)
                                const DragToRemoveHandler(),
                              Consumer(
                            builder: (context, ref, child) {
                              final tasksAsync = ref.watch(
                                taskSectionsProvider(meta.section),
                              );
                              return tasksAsync.when(
                                data: (tasks) {
                                      if (tasks.isEmpty) return const SizedBox.shrink();
                                      final panel = TaskSectionPanel(
                                        key: _sectionKeys[meta.section],
                                    section: meta.section,
                                    title: meta.title,
                                    editMode: false,
                                        onQuickAdd: () => _handleQuickAdd(context, meta.section),
                                    tasks: tasks,
                                  );
                                      _maybeAutoScroll(meta.section);
                                      return panel;
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                            ])
                        .toList(growable: false),
                  ),
          ),
        ],
        ),
      ),
    );
  }

  void _maybeAutoScroll(TaskSection builtSection) {
    if (_didAutoScroll) return;
    final target = _parseSection(widget.initialSection);
    if (target == null) return;
    // 当目标分区第一次构建到树中时，执行滚动
    if (builtSection != target) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final key = _sectionKeys[target];
      final ctx = key?.currentContext;
      if (ctx != null) {
        _didAutoScroll = true;
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          alignment: 0.05,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  TaskSection? _parseSection(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (raw) {
      case 'overdue':
        return TaskSection.overdue;
      case 'today':
        return TaskSection.today;
      case 'tomorrow':
        return TaskSection.tomorrow;
      case 'thisWeek':
        return TaskSection.thisWeek;
      case 'thisMonth':
        return TaskSection.thisMonth;
      case 'later':
        return TaskSection.later;
      default:
        return null;
    }
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
