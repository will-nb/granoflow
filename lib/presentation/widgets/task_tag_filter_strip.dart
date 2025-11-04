import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
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
  });

  /// 筛选Provider（StateNotifierProvider<TaskFilterNotifier, TaskFilterState>）
  final StateNotifierProvider<TaskFilterNotifier, TaskFilterState>
      filterProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsDomainProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 项目筛选（移到最前面）
        projectsAsync.when(
          data: (_) => ProjectFilterSection(filterProvider: filterProvider),
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

