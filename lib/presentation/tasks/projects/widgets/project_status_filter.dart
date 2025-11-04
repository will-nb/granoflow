import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../widgets/modern_tag.dart';

/// 项目状态筛选器组件
/// 使用水平滚动的ModernTag（dot变体）实现状态筛选，与情境按钮风格一致
class ProjectStatusFilter extends ConsumerWidget {
  const ProjectStatusFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(projectFilterStatusProvider);
    final l10n = AppLocalizations.of(context);

    final statusOptions = [
      ProjectFilterStatus.all,
      ProjectFilterStatus.active,
      ProjectFilterStatus.completed,
      ProjectFilterStatus.archived,
      ProjectFilterStatus.trash,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: statusOptions.map((status) {
          final label = _getStatusLabel(status, l10n);
          final isSelected = selectedStatus == status;
          final color = _getStatusColor(status, context);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ModernTag(
              label: label,
              color: color,
              selected: isSelected,
              variant: TagVariant.dot,
              size: TagSize.medium,
              showCheckmark: false,
              onTap: () {
                ref.read(projectFilterStatusProvider.notifier).state = status;
              },
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  String _getStatusLabel(ProjectFilterStatus status, AppLocalizations l10n) {
    switch (status) {
      case ProjectFilterStatus.all:
        return '全部';
      case ProjectFilterStatus.active:
        return '活跃';
      case ProjectFilterStatus.completed:
        return l10n.completedTab;
      case ProjectFilterStatus.archived:
        return l10n.archivedTab;
      case ProjectFilterStatus.trash:
        return l10n.navTrashTitle;
    }
  }

  Color _getStatusColor(ProjectFilterStatus status, BuildContext context) {
    final theme = Theme.of(context);
    final colorTokens = Theme.of(context).extension<AppColorTokens>();
    switch (status) {
      case ProjectFilterStatus.all:
        return theme.colorScheme.tertiary;
      case ProjectFilterStatus.active:
        return theme.colorScheme.primary;
      case ProjectFilterStatus.completed:
        return colorTokens?.success ?? theme.colorScheme.primary;
      case ProjectFilterStatus.archived:
        return theme.colorScheme.onSurfaceVariant;
      case ProjectFilterStatus.trash:
        return theme.colorScheme.error;
    }
  }
}

