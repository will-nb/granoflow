import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/task_search_providers.dart';
import '../../core/utils/task_section_utils.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import '../home/widgets/task_search_bar.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/main_drawer.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/simplified_task_row.dart';

/// 搜索页面
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  @override
  void initState() {
    super.initState();
    // 页面打开时清空搜索关键词
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskSearchQueryProvider.notifier).state = '';
    });
  }

  void _handleTaskTap(Task task) {
    // 如果任务有截止日期，跳转到该日期的日视图
    if (task.dueAt != null) {
      final date = task.dueAt!;
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      context.go('/achievements?date=$dateStr&viewMode=day');
      return;
    }
    
    // 如果没有截止日期，根据任务状态跳转
    switch (task.status) {
      case TaskStatus.inbox:
        context.go('/inbox');
        return;
      case TaskStatus.pending:
        final section = _locateSectionForTask(task);
        context.go('/tasks${section != null ? '?section=$section' : ''}');
        return;
      case TaskStatus.doing:
      case TaskStatus.paused:
        final section2 = _locateSectionForTask(task);
        context.go('/tasks${section2 != null ? '?section=$section2' : ''}');
        return;
      case TaskStatus.completedActive:
      case TaskStatus.archived:
      case TaskStatus.trashed:
      case TaskStatus.pseudoDeleted:
        context.go('/tasks');
        return;
    }
  }

  /// 基于任务状态与截止日期，推断其所在的任务分区（用于跳转定位）
  String? _locateSectionForTask(Task task) {
    final section = TaskSectionUtils.getSectionForDate(task.dueAt);
    switch (section) {
      case TaskSection.overdue:
        return 'overdue';
      case TaskSection.today:
        return 'today';
      case TaskSection.tomorrow:
        return 'tomorrow';
      case TaskSection.thisWeek:
        return 'thisWeek';
      case TaskSection.thisMonth:
        return 'thisMonth';
      case TaskSection.nextMonth:
        return 'nextMonth';
      case TaskSection.later:
        return 'later';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(taskSearchQueryProvider);
    final resultsAsync = ref.watch(taskSearchResultsProvider);

    return GradientPageScaffold(
      appBar: PageAppBar(
        title: l10n.searchPageTitle,
      ),
      drawer: const MainDrawer(),
      body: Column(
        children: [
          // 搜索栏
          TaskSearchBar(
            autofocus: true,
            onChanged: (value) {
              // 实时搜索已由 Provider 处理
            },
          ),
          // 搜索限制提示
          if (query.isNotEmpty && query.length < 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.searchMinLengthHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          // 搜索结果
          Expanded(
            child: resultsAsync.when(
              data: (tasks) {
                if (query.length < 3) {
                  return const SizedBox.shrink();
                }
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.searchNoResults,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return SimplifiedTaskRow(
                      task: task,
                      onTap: () => _handleTaskTap(task),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error: $error',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

