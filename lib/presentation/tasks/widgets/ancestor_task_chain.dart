import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';
import '../../../core/providers/repository_providers.dart';
import '../../tasks/utils/hierarchy_utils.dart';
import 'parent_task_header.dart';

/// 祖先任务链组件
/// 
/// 递归向上查找祖先任务（最多3级，排除项目和里程碑），
/// 显示完整的层级链（祖任务→父任务）
class AncestorTaskChain extends ConsumerWidget {
  const AncestorTaskChain({
    super.key,
    required this.taskId,
    required this.currentSection,
  });

  final int taskId;
  final TaskSection currentSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ancestorsAsync = ref.watch(ancestorChainProvider(taskId));

    return ancestorsAsync.when(
      data: (ancestors) {
        if (ancestors.isEmpty) {
          return const SizedBox.shrink();
        }

        // 从最远的祖先到最近的父任务显示（已经是 reversed 的顺序）
        return Column(
          children: ancestors.asMap().entries.map((entry) {
            final index = entry.key;
            final ancestor = entry.value;
            return ParentTaskHeader(
              parentTask: ancestor,
              currentSection: currentSection,
              depth: index,
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Provider: 获取任务的祖先任务链
final ancestorChainProvider = FutureProvider.family<List<Task>, int>((ref, taskId) async {
  final taskRepository = ref.read(taskRepositoryProvider);
  return buildAncestorChain(taskId, taskRepository);
});

