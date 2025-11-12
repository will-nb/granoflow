import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/service_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 任务状态切换工具类
/// 
/// 统一处理任务状态切换逻辑
class TaskStatusToggleHelper {
  /// 切换任务的完成/未完成状态
  /// 
  /// [context] BuildContext
  /// [ref] WidgetRef
  /// [task] 要切换状态的任务
  /// 
  /// 返回 true 表示切换成功，false 表示失败
  static Future<bool> toggleTaskStatus(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      final l10n = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.of(context);

      // 如果任务已完成，恢复为 pending 状态
      if (task.status == TaskStatus.completedActive) {
        await taskService.updateDetails(
          taskId: task.id,
          payload: TaskUpdate(status: TaskStatus.pending),
        );
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.taskListTaskUncompletedToast),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return true;
      }
      // 如果任务未完成，标记为已完成
      else if (task.status == TaskStatus.inbox ||
          task.status == TaskStatus.pending ||
          task.status == TaskStatus.doing ||
          task.status == TaskStatus.paused) {
        await taskService.markCompleted(taskId: task.id);
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.taskListTaskCompletedToast),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return true;
      }
      // 其他状态（archived、trashed）不支持切换
      return false;
    } catch (error, stackTrace) {
      debugPrint('Failed to toggle task status: $error\n$stackTrace');
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.taskListTaskCompletedError}: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return false;
    }
  }
}

