import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../core/utils/delta_json_utils.dart';
import '../../core/providers/node_providers.dart';
import '../../core/providers/task_expansion_providers.dart';
import 'simplified_task_row.dart';
import 'task_expandable_content.dart';

/// 可展开的任务行组件
/// 
/// 包装 SimplifiedTaskRow，添加展开/收缩功能
/// 如果任务有 description 或 nodes，显示展开按钮
class ExpandableTaskRow extends ConsumerWidget {
  const ExpandableTaskRow({
    super.key,
    required this.task,
    this.onTap,
    this.section,
    this.showCheckbox = false,
    this.verticalPadding = 12.0,
  });

  final Task task;
  final VoidCallback? onTap;
  final TaskSection? section;
  final bool showCheckbox;
  final double verticalPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // 检查是否有 description
    final hasDescription = task.description != null &&
        task.description!.isNotEmpty &&
        DeltaJsonUtils.isValidDeltaJson(task.description);

    // 检查是否有 nodes
    final nodesAsync = ref.watch(taskNodesProvider(task.id));
    final hasNodes = nodesAsync.maybeWhen(
      data: (nodes) => nodes.isNotEmpty,
      orElse: () => false,
    );

    // 如果既没有 description 也没有 nodes，直接显示 SimplifiedTaskRow
    if (!hasDescription && !hasNodes) {
      return SimplifiedTaskRow(
        task: task,
        onTap: onTap,
        section: section,
        showCheckbox: showCheckbox,
        verticalPadding: verticalPadding,
      );
    }

    // 获取展开状态
    final expandedTaskIds = ref.watch(taskExpansionProvider);
    final isExpanded = expandedTaskIds.contains(task.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 任务行（带展开按钮）
        Row(
          children: [
            Expanded(
              child: SimplifiedTaskRow(
                task: task,
                onTap: onTap,
                section: section,
                showCheckbox: showCheckbox,
                verticalPadding: verticalPadding,
              ),
            ),
            // 展开/收缩按钮
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final currentExpanded = ref.read(taskExpansionProvider);
                  final newExpanded = Set<String>.from(currentExpanded);
                  if (isExpanded) {
                    newExpanded.remove(task.id);
                  } else {
                    newExpanded.add(task.id);
                  }
                  ref.read(taskExpansionProvider.notifier).state = newExpanded;
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
        // 展开内容
        if (isExpanded)
          TaskExpandableContent(task: task),
      ],
    );
  }
}

