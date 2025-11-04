import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../data/models/project.dart';
import 'error_banner.dart';
import 'task_tag_filter_strip/project_filter_section.dart';
import 'task_tag_filter_strip/tag_filter_section.dart';

/// 通用任务标签筛选条组件
/// 
/// 支持场景标签、紧急度标签和重要度标签的筛选
/// 接受一个filterProvider参数，可以在任何页面使用
class TaskTagFilterStrip extends ConsumerWidget {
  const TaskTagFilterStrip({
    super.key,
    required this.filterProvider,
    this.projectsProvider,
  });

  /// 筛选Provider（StateNotifierProvider<TaskFilterNotifier, TaskFilterState>）
  final StateNotifierProvider<TaskFilterNotifier, TaskFilterState>
      filterProvider;

  /// 可选的 projectsProvider，用于自定义项目列表来源
  /// 如果不提供，则使用默认的 projectsDomainProvider（只显示活跃项目）
  final StreamProvider<List<Project>>? projectsProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(
      projectsProvider ?? projectsDomainProvider,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 项目筛选（移到最前面）
        projectsAsync.when(
          data: (_) => ProjectFilterSection(
            filterProvider: filterProvider,
            projectsProvider: projectsProvider,
          ),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => ErrorBanner(message: '$error'),
        ),
        const SizedBox(height: 8),
        // 标签筛选（场景标签和优先级标签）
        TagFilterSection(filterProvider: filterProvider),
      ],
    );
  }

// _buildContextTags, _buildPriorityTags, _buildProjectFilter 等方法已移至独立组件文件
}

