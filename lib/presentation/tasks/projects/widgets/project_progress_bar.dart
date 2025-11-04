import 'package:flutter/material.dart';

import '../../../../generated/l10n/app_localizations.dart';

/// 项目进度条组件
/// 
/// 显示项目的完成进度，包括进度条和进度文字
class ProjectProgressBar extends StatelessWidget {
  const ProjectProgressBar({
    super.key,
    required this.progress,
    required this.completed,
    required this.total,
    required this.overdue,
  });

  final double progress;
  final int completed;
  final int total;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final percentage = (progress * 100).clamp(0, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: total == 0 ? 0 : progress,
          minHeight: 6,
          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          valueColor: AlwaysStoppedAnimation<Color>(
            overdue ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          total == 0
              ? l10n.projectProgressEmpty
              : l10n.projectProgressLabel(percentage, completed, total),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

