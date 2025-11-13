import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';
import '../../../core/providers/repository_providers.dart';

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

    final String taskId;
  final TaskSection currentSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ancestorsAsync = ref.watch(ancestorChainProvider(taskId));

    return ancestorsAsync.when(
      data: (ancestors) {
        if (ancestors.isEmpty) {
          return const SizedBox.shrink();
        }

        // 不再显示祖先任务链
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Provider: 获取任务的祖先任务链（层级功能已移除，返回空列表）
final ancestorChainProvider = FutureProvider.family<List<Task>, String>((ref, taskId) async {
  // 层级功能已移除，不再有祖先任务链
  return <Task>[];
});

