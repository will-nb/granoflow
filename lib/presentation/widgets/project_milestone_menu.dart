import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';

/// 项目/里程碑菜单组件
/// 显示所有项目，每个项目可以展开显示里程碑
class ProjectMilestoneMenu extends ConsumerStatefulWidget {
  const ProjectMilestoneMenu({
    super.key,
    required this.onSelected,
    this.currentParentId,
  });

  /// 选择回调：传入选中的任务ID（项目或里程碑）
  final ValueChanged<int?> onSelected;

  /// 当前任务的父任务ID（如果有）
  final int? currentParentId;

  @override
  ConsumerState<ProjectMilestoneMenu> createState() =>
      _ProjectMilestoneMenuState();
}

class _ProjectMilestoneMenuState extends ConsumerState<ProjectMilestoneMenu> {
  final Set<int> _expandedProjects = {};

  void _toggleProject(int projectId) {
    setState(() {
      if (_expandedProjects.contains(projectId)) {
        _expandedProjects.remove(projectId);
      } else {
        _expandedProjects.add(projectId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final projectsAsync = ref.watch(projectsProvider);

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                l10n.taskNoProjects,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 如果任务已关联，显示"移出"选项
            if (widget.currentParentId != null) ...[
              ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Icon(
                  Icons.remove_circle_outline,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  l10n.taskRemoveFromProject,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: () => widget.onSelected(null),
              ),
              const Divider(height: 1),
            ],
            // 项目列表
            ...projects.map((project) => _ProjectSection(
                  project: project,
                  isExpanded: _expandedProjects.contains(project.id),
                  onToggle: () => _toggleProject(project.id),
                  onSelected: widget.onSelected,
                  currentParentId: widget.currentParentId,
                )),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error: $error',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

class _ProjectSection extends ConsumerWidget {
  const _ProjectSection({
    required this.project,
    required this.isExpanded,
    required this.onToggle,
    required this.onSelected,
    this.currentParentId,
  });

  final Task project;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<int?> onSelected;
  final int? currentParentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final milestonesAsync = ref.watch(projectMilestonesProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 项目项
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(
            Icons.folder_outlined,
            size: 20,
            color: currentParentId == project.id
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(
            project.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: currentParentId == project.id
                  ? theme.colorScheme.primary
                  : null,
              fontWeight: currentParentId == project.id
                  ? FontWeight.w600
                  : null,
            ),
          ),
          trailing: milestonesAsync.when(
            data: (milestones) => milestones.isEmpty
                ? null
                : Icon(
                    isExpanded
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
            if (milestonesAsync.hasValue && milestonesAsync.value!.isEmpty) {
              // 没有里程碑，直接选择项目
              onSelected(project.id);
            } else {
              // 有里程碑，展开/收起
              onToggle();
            }
          },
        ),
        // 里程碑列表（展开时显示）
        if (isExpanded)
          milestonesAsync.when(
            data: (milestones) {
              if (milestones.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: milestones.map((milestone) {
                  final isSelected = currentParentId == milestone.id;
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
                          fontWeight:
                              isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                      onTap: () => onSelected(milestone.id),
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

