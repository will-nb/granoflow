import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/milestone.dart';
import '../../../../data/models/project.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../milestones/milestone_card.dart';
import '../../widgets/empty_placeholder.dart';
import 'milestone_edit_sheet.dart';

/// 项目详情组件
/// 
/// 显示项目的里程碑列表和添加里程碑按钮
class ProjectDetails extends ConsumerWidget {
  const ProjectDetails({
    super.key,
    required this.project,
    required this.milestones,
  });

  final Project project;
  final List<Milestone> milestones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        if (milestones.isEmpty)
          EmptyPlaceholder(message: l10n.projectNoMilestonesHint)
        else
          ...milestones.map<Widget>(
            (milestone) => MilestoneCard(milestone: milestone),
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _addMilestone(context, ref),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('添加里程碑'),
        ),
      ],
    );
  }

  Future<void> _addMilestone(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => MilestoneEditSheet(
        projectId: project.projectId,
      ),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('里程碑已添加')),
      );
    }
  }
}

