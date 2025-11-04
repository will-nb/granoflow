import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/milestone.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'project_filter_tile.dart';

/// 项目筛选区域组件
/// 用于在标签筛选条中显示和选择项目/里程碑筛选
class ProjectFilterSection extends ConsumerWidget {
  const ProjectFilterSection({
    super.key,
    required this.filterProvider,
  });

  final StateNotifierProvider<TaskFilterNotifier, TaskFilterState>
      filterProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final projectsAsync = ref.watch(projectsDomainProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return projectsAsync.when(
      data: (projects) {
        // 确定显示文本和图标
        String displayText;
        IconData displayIcon;
        bool isSelected = false;

        if (filter.showNoProject) {
          // 已选"无项目"
          displayText = l10n.noProject;
          displayIcon = Icons.folder_off_outlined;
          isSelected = true;
        } else if (filter.projectId != null &&
            filter.projectId!.isNotEmpty &&
            projects.isNotEmpty) {
          // 已选项目或里程碑
          final project = projects.firstWhere(
            (p) => p.projectId == filter.projectId,
            orElse: () => projects.first,
          );

          if (filter.milestoneId != null && filter.milestoneId!.isNotEmpty) {
            // 已选里程碑，需要异步加载里程碑名称
            final milestonesAsync = ref.watch(
              projectMilestonesDomainProvider(filter.projectId!),
            );
            return milestonesAsync.when(
              data: (milestones) {
                Milestone? milestone;
                if (milestones.isNotEmpty) {
                  milestone = milestones.firstWhere(
                    (m) => m.milestoneId == filter.milestoneId,
                    orElse: () => milestones.first,
                  );
                }
                displayText = milestone?.title ?? project.title;
                displayIcon = Icons.flag_outlined;
                return _ProjectFilterButton(
                  filterProvider: filterProvider,
                  text: displayText,
                  icon: displayIcon,
                  theme: theme,
                  isSelected: true,
                );
              },
              loading: () => _ProjectFilterButton(
                filterProvider: filterProvider,
                text: project.title,
                icon: Icons.folder_outlined,
                theme: theme,
                isSelected: true,
              ),
              error: (_, __) => _ProjectFilterButton(
                filterProvider: filterProvider,
                text: project.title,
                icon: Icons.folder_outlined,
                theme: theme,
                isSelected: true,
              ),
            );
          } else {
            // 已选项目
            displayText = project.title;
            displayIcon = Icons.folder_outlined;
            isSelected = true;
          }
        } else {
          // 未选：显示"所在项目"
          displayText = l10n.projectFilterLabel;
          displayIcon = Icons.folder_outlined;
          isSelected = false;
        }

        return _ProjectFilterButton(
          filterProvider: filterProvider,
          text: displayText,
          icon: displayIcon,
          theme: theme,
          isSelected: isSelected,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

/// 项目筛选按钮组件
class _ProjectFilterButton extends ConsumerWidget {
  const _ProjectFilterButton({
    required this.filterProvider,
    required this.text,
    required this.icon,
    required this.theme,
    required this.isSelected,
  });

  final StateNotifierProvider<TaskFilterNotifier, TaskFilterState>
      filterProvider;
  final String text;
  final IconData icon;
  final ThemeData theme;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用主题颜色，与标签保持一致
    final color = isSelected
        ? theme.colorScheme.primary
        : (theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface);

    return InkWell(
      onTap: () => _showProjectFilterMenu(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示项目筛选菜单
  Future<void> _showProjectFilterMenu(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final filter = ref.read(filterProvider);
    final notifier = ref.read(filterProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsDomainProvider);

    Future<void> handleSelection({
      String? projectId,
      String? milestoneId,
      bool? showNoProject,
    }) async {
      Navigator.pop(context);
      if (showNoProject != null) {
        if (showNoProject != filter.showNoProject) {
          notifier.toggleShowNoProject();
        }
      } else if (projectId != null) {
        notifier.setProjectId(projectId);
        if (milestoneId != null) {
          notifier.setMilestoneId(milestoneId);
        } else {
          notifier.setMilestoneId(null);
        }
      }
    }

    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: projectsAsync.when(
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
                    // "无项目"选项（始终显示）
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Icon(
                        Icons.folder_off_outlined,
                        size: 20,
                        color: filter.showNoProject
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        l10n.noProject,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: filter.showNoProject
                              ? theme.colorScheme.primary
                              : null,
                          fontWeight:
                              filter.showNoProject ? FontWeight.w600 : null,
                        ),
                      ),
                      onTap: () => handleSelection(
                        showNoProject: !filter.showNoProject,
                      ),
                    ),
                    const Divider(height: 1),
                    // 项目列表
                    ...projects.map(
                      (project) => ProjectFilterTile(
                        project: project,
                        isSelected: filter.projectId == project.projectId,
                        currentMilestoneId: filter.milestoneId,
                        onSelected: (milestoneId) => handleSelection(
                          projectId: project.projectId,
                          milestoneId: milestoneId,
                        ),
                      ),
                    ),
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
            ),
          ),
        ),
      ),
    );
  }
}

