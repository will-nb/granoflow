import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/project.dart';

/// 项目筛选菜单中的项目项组件
class ProjectFilterTile extends ConsumerStatefulWidget {
  const ProjectFilterTile({
    super.key,
    required this.project,
    required this.isSelected,
    this.currentMilestoneId,
    required this.onSelected,
  });

  final Project project;
  final bool isSelected;
  final String? currentMilestoneId;
  final ValueChanged<String?> onSelected; // milestoneId or null for project

  @override
  ConsumerState<ProjectFilterTile> createState() =>
      _ProjectFilterTileState();
}

class _ProjectFilterTileState extends ConsumerState<ProjectFilterTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final milestonesAsync = ref.watch(
      projectMilestonesDomainProvider(widget.project.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 项目项
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Icon(
            Icons.folder_outlined,
            size: 20,
            color: widget.isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(
            widget.project.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: widget.isSelected ? theme.colorScheme.primary : null,
              fontWeight: widget.isSelected ? FontWeight.w600 : null,
            ),
          ),
          trailing: milestonesAsync.when(
            data: (milestones) => milestones.isEmpty
                ? null
                : Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 20,
                  ),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => null,
          ),
          onTap: () {
            milestonesAsync.whenData((milestones) {
              if (milestones.isEmpty) {
                // 没有里程碑，直接选择项目
                widget.onSelected(null);
              } else {
                // 有里程碑，展开/收起
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              }
            });
          },
        ),
        // 里程碑列表（展开时显示）
        if (_isExpanded)
          milestonesAsync.when(
            data: (milestones) {
              if (milestones.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: milestones.map((milestone) {
                  final isSelected =
                      widget.currentMilestoneId == milestone.id;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Icon(
                        Icons.flag_outlined,
                        size: 20,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        milestone.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : null,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                      onTap: () => widget.onSelected(milestone.id),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }
}

