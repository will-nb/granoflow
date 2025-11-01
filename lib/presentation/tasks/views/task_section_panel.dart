import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../utils/task_collection_utils.dart';
import '../widgets/empty_section_hint.dart';
import '../widgets/error_banner.dart';
import 'task_section_list.dart';

class TaskSectionPanel extends ConsumerWidget {
  const TaskSectionPanel({
    super.key,
    required this.section,
    required this.title,
    required this.editMode,
    required this.onQuickAdd,
    this.tasks,
  });

  final TaskSection section;
  final String title;
  final bool editMode;
  final VoidCallback onQuickAdd;
  final List<Task>? tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = tasks != null
        ? AsyncValue<List<Task>>.data(tasks!)
        : ref.watch(taskSectionsProvider(section));
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  onPressed: onQuickAdd,
                  icon: const Icon(Icons.add_task_outlined),
                  tooltip: l10n.taskListQuickAddTooltip,
                ),
              ],
            ),
            const SizedBox(height: 12),
            tasksAsync.when(
              data: (tasks) {
                if (kDebugMode) {
                  debugPrint('[TaskSectionPanel] section=${section.name}, tasks.length=${tasks.length}');
                }
                if (tasks.isEmpty) {
                  if (kDebugMode) {
                    debugPrint('[TaskSectionPanel] 任务为空，显示空状态提示');
                  }
                  return EmptySectionHint(
                    message: l10n.taskListEmptySectionHint,
                  );
                }
                final roots = collectRoots(tasks);
                if (kDebugMode) {
                  debugPrint('[TaskSectionPanel] section=${section.name}, roots.length=${roots.length}');
                  for (final root in roots.take(3)) {
                    debugPrint('  - root: id=${root.id}, title=${root.title}, parentId=${root.parentId}');
                  }
                }
                if (roots.isEmpty) {
                  if (kDebugMode) {
                    debugPrint('[TaskSectionPanel] 根任务为空，显示空状态提示');
                  }
                  return EmptySectionHint(
                    message: l10n.taskListEmptySectionHint,
                  );
                }
                if (editMode) {
                  if (kDebugMode) {
                    debugPrint('[TaskSectionPanel] 使用项目模式显示');
                  }
                  return TaskSectionProjectModePanel(
                    section: section,
                    roots: roots,
                  );
                }
                if (kDebugMode) {
                  debugPrint('[TaskSectionPanel] 使用任务模式显示');
                }
                return TaskSectionTaskModeList(section: section, roots: roots);
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => ErrorBanner(message: '$error'),
            ),
          ],
        ),
      ),
    );
  }
}

