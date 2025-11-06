import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/task_hierarchy_providers.dart';
import '../../../data/models/task.dart';
import '../../widgets/inline_project_milestone_display.dart';

/// 番茄时钟任务信息卡片
///
/// 显示任务名称、所属项目和里程碑
class PomodoroTaskInfoCard extends ConsumerWidget {
  const PomodoroTaskInfoCard({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hierarchyAsync = ref.watch(taskProjectHierarchyProvider(task.id));

    final divider = Container(
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white12, Colors.white54, Colors.white12],
        ),
      ),
    );

    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 21,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            divider,
            const SizedBox(height: 10),
            hierarchyAsync.when(
              data: (hierarchy) {
                if (hierarchy == null) {
                  return const SizedBox.shrink();
                }
                return InlineProjectMilestoneDisplay(
                  project: hierarchy.project,
                  milestone: hierarchy.milestone,
                  onSelected: (_) {},
                  readOnly: true,
                  showIcon: true,
                );
              },
              loading: () => const SizedBox(
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
