import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../core/utils/delta_json_utils.dart';
import '../../core/providers/node_providers.dart';
import '../../generated/l10n/app_localizations.dart';
import 'description_viewer_dialog.dart';
import '../../core/providers/service_providers.dart';
import 'task_nodes_list_readonly.dart';

/// 任务展开内容组件
/// 
/// 显示任务的 description 和 nodes
class TaskExpandableContent extends ConsumerWidget {
  const TaskExpandableContent({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

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

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Description（如果有）
            if (hasDescription) ...[
              _buildDescription(context, ref, theme, colorScheme, l10n),
              if (hasNodes)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outline.withValues(alpha: 0.08),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
            // Nodes（如果有）
            if (hasNodes)
              TaskNodesListReadonly(task: task),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final document = DeltaJsonUtils.jsonToDocument(task.description);
    final plainText = document.toPlainText();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
        await Navigator.of(context).push<void>(
          PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) =>
                DescriptionViewerDialog(
              description: task.description,
              onSave: (savedDescription) async {
                // 保存到数据库
                try {
                  final taskService = await ref.read(taskServiceProvider.future);
                  await taskService.updateDetails(
                    taskId: task.id,
                    payload: TaskUpdate(description: savedDescription),
                  );
                  // 任务数据会自动刷新（通过 StreamProvider）
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${l10n.taskUpdateError}: $error'),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOut;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            fullscreenDialog: true,
            opaque: true,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.description_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                plainText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

