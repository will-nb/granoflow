import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../data/models/tag.dart';
import '../../data/models/project.dart';
import '../../data/models/milestone.dart';
import '../../generated/l10n/app_localizations.dart';
import 'error_banner.dart';
import 'modern_tag.dart';
import 'tag_data.dart';

/// 通用任务标签筛选条组件
/// 
/// 支持场景标签、紧急度标签和重要度标签的筛选
/// 接受一个filterProvider参数，可以在任何页面使用
class TaskTagFilterStrip extends ConsumerWidget {
  const TaskTagFilterStrip({
    super.key,
    required this.filterProvider,
  });

  /// 筛选Provider（StateNotifierProvider<TaskFilterNotifier, TaskFilterState>）
  final StateNotifierProvider<TaskFilterNotifier, TaskFilterState>
      filterProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final contextTagsAsync = ref.watch(contextTagOptionsProvider);
    final urgencyTagsAsync = ref.watch(urgencyTagOptionsProvider);
    final importanceTagsAsync = ref.watch(importanceTagOptionsProvider);
    final projectsAsync = ref.watch(projectsDomainProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 项目筛选（移到最前面）
        projectsAsync.when(
          data: (projects) => _buildProjectFilter(context, ref, filter, projects),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => ErrorBanner(message: '$error'),
        ),
        const SizedBox(height: 8),
        // 场景标签筛选
        contextTagsAsync.when(
          data: (tags) => _buildContextTags(context, ref, filter, tags),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => ErrorBanner(message: '$error'),
        ),
        const SizedBox(height: 8),
        // 紧急度和重要度标签筛选
        urgencyTagsAsync.when(
          data: (urgencyTags) => importanceTagsAsync.when(
            data: (importanceTags) => _buildPriorityTags(
              context,
              ref,
              filter,
              urgencyTags,
              importanceTags,
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => ErrorBanner(message: '$error'),
          ),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => ErrorBanner(message: '$error'),
        ),
      ],
    );
  }

  Widget _buildContextTags(
    BuildContext context,
    WidgetRef ref,
    TaskFilterState filter,
    List<Tag> tags,
  ) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    final tagDataList = tags
        .map((tag) => TagData.fromTagWithLocalization(tag, context))
        .toList(growable: false);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tagDataList.map((tagData) {
          final isSelected = filter.contextTag == tagData.slug;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ModernTag(
              label: tagData.label,
              color: tagData.color,
              icon: tagData.icon,
              prefix: tagData.prefix,
              selected: isSelected,
              variant: TagVariant.dot,
              size: TagSize.medium,
              showCheckmark: false,
              onTap: () {
                ref.read(filterProvider.notifier).setContextTag(
                      isSelected ? null : tagData.slug,
                    );
              },
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildPriorityTags(
    BuildContext context,
    WidgetRef ref,
    TaskFilterState filter,
    List<Tag> urgencyTags,
    List<Tag> importanceTags,
  ) {
    final l10n = AppLocalizations.of(context);
    final widgets = <Widget>[];

    widgets.addAll(
      urgencyTags.map((tag) {
        final tagData = TagData.fromTagWithLocalization(tag, context);
        final isSelected = filter.urgencyTag == tagData.slug;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ModernTag(
            label: tagData.label,
            color: tagData.color,
            icon: tagData.icon,
            prefix: tagData.prefix,
            selected: isSelected,
            variant: TagVariant.dot,
            size: TagSize.medium,
            showCheckmark: false,
            onTap: () {
              ref.read(filterProvider.notifier).setUrgencyTag(
                    isSelected ? null : tagData.slug,
                  );
            },
          ),
        );
      }),
    );

    widgets.addAll(
      importanceTags.map((tag) {
        final tagData = TagData.fromTagWithLocalization(tag, context);
        final isSelected = filter.importanceTag == tagData.slug;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ModernTag(
            label: tagData.label,
            color: tagData.color,
            icon: tagData.icon,
            prefix: tagData.prefix,
            selected: isSelected,
            variant: TagVariant.dot,
            size: TagSize.medium,
            showCheckmark: false,
            onTap: () {
              ref.read(filterProvider.notifier).setImportanceTag(
                    isSelected ? null : tagData.slug,
                  );
            },
          ),
        );
      }),
    );

    if (filter.hasFilters) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(l10n.inboxFilterReset),
            avatar: Icon(
              Icons.clear_all,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            onPressed: () => ref.read(filterProvider.notifier).reset(),
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: widgets),
    );
  }

  Widget _buildProjectFilter(
    BuildContext context,
    WidgetRef ref,
    TaskFilterState filter,
    List<Project> projects,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

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
            return _buildProjectFilterButton(
              context,
              ref,
              displayText,
              displayIcon,
              theme,
              isSelected: true,
            );
          },
          loading: () => _buildProjectFilterButton(
            context,
            ref,
            project.title,
            Icons.folder_outlined,
            theme,
            isSelected: true,
          ),
          error: (_, __) => _buildProjectFilterButton(
            context,
            ref,
            project.title,
            Icons.folder_outlined,
            theme,
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

    return _buildProjectFilterButton(
      context,
      ref,
      displayText,
      displayIcon,
      theme,
      isSelected: isSelected,
    );
  }

  /// 构建项目筛选按钮（Minimal风格）
  Widget _buildProjectFilterButton(
    BuildContext context,
    WidgetRef ref,
    String text,
    IconData icon,
    ThemeData theme, {
    required bool isSelected,
  }) {
    // 使用主题颜色，与标签保持一致
    // 未选中：使用bodyMedium颜色（浅色模式黑色，深色模式白色）
    // 选中：使用primary颜色（与ModernTag的dot变体选中时一致）
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
        // 移除了"移出项目"选项，用户应通过"重设"按钮清空筛选
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
                      (project) => _ProjectFilterTile(
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

/// 项目筛选菜单中的项目项组件
class _ProjectFilterTile extends ConsumerStatefulWidget {
  const _ProjectFilterTile({
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
  ConsumerState<_ProjectFilterTile> createState() =>
      _ProjectFilterTileState();
}

class _ProjectFilterTileState extends ConsumerState<_ProjectFilterTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final milestonesAsync = ref.watch(
      projectMilestonesDomainProvider(widget.project.projectId),
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
              color:
                  widget.isSelected ? theme.colorScheme.primary : null,
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
                      widget.currentMilestoneId == milestone.milestoneId;
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
                      onTap: () => widget.onSelected(milestone.milestoneId),
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

