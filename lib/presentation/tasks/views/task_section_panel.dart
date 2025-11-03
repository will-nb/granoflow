import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_spacing_tokens.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../utils/task_collection_utils.dart';
import '../widgets/empty_section_hint.dart';
import '../widgets/error_banner.dart';
import 'task_section_list.dart';
import 'tasks_section_task_list.dart';

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
    final spacing = Theme.of(context).extension<AppSpacingTokens>();
    final spacingTokens = spacing ?? AppSpacingTokens.light;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacingTokens.cardHorizontalPadding,
          vertical: spacingTokens.cardVerticalPadding,
        ),
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
            SizedBox(height: spacingTokens.sectionInternalSpacing),
            tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return EmptySectionHint(
                    message: l10n.taskListEmptySectionHint,
                  );
                }
                final roots = collectRoots(tasks);
                if (roots.isEmpty) {
                  return EmptySectionHint(
                    message: l10n.taskListEmptySectionHint,
                  );
                }
                if (editMode) {
                  return TaskSectionProjectModePanel(
                    section: section,
                    roots: roots,
                  );
                }
                return TasksSectionTaskList(section: section, tasks: tasks);
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

