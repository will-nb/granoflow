import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/clock_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/focus_session_repository.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../tasks/utils/hierarchy_utils.dart';
import '../../tasks/views/task_tree_tile/task_tree_tile_actions.dart';
import 'clock_subtask_item.dart';

/// Provider: 获取任务的子任务列表（实时监听）
final clockSubtaskListProvider = StreamProvider.family<List<Task>, String>((
  ref,
  parentId,
) async* {
  final taskRepository = ref.watch(taskRepositoryProvider);
  final taskStream = taskRepository.watchTaskById(parentId);

  await for (final task in taskStream) {
    if (task == null) {
      yield [];
      continue;
    }

    final children = await taskRepository.listChildren(parentId);
    yield children;
  }
});

/// 计时器子任务管理组件
///
/// 显示子任务列表、添加子任务功能、特殊子任务逻辑、第三级限制
class ClockSubtaskSection extends ConsumerStatefulWidget {
  const ClockSubtaskSection({
    super.key,
    required this.task,
    required this.timerState,
  });

  final Task task;
  final ClockTimerState timerState;

  @override
  ConsumerState<ClockSubtaskSection> createState() =>
      _ClockSubtaskSectionState();
}

class _ClockSubtaskSectionState
    extends ConsumerState<ClockSubtaskSection> {
  int? _taskLevel;

  @override
  void initState() {
    super.initState();
    _loadTaskLevel();
  }

  Future<void> _loadTaskLevel() async {
    final repository = ref.read(taskRepositoryProvider);
    final level = await getTaskLevel(widget.task, repository);
    if (mounted) {
      setState(() {
        _taskLevel = level;
      });
    }
  }

    Future<void> _handleAddSubtask() async {
    // 打开对话框时暂停计时器
    final timerState = ref.read(clockTimerProvider);
    if (timerState.isStarted && !timerState.isPaused) {
      ref.read(clockTimerProvider.notifier).pause();
    }

    // 检查是否是第一个子任务
    final childrenAsync = ref.read(clockSubtaskListProvider(widget.task.id));
      final children = await childrenAsync.requireValue;
    final isFirstSubtask = children.isEmpty;

    // 显示添加子任务对话框
      await showAddSubtaskDialog(context, ref, widget.task.id);

    // 如果是第一个子任务，创建特殊子任务
    if (isFirstSubtask && mounted) {
      await _createOvertimeSubtask();
    }
  }

    Future<void> _createOvertimeSubtask() async {
    try {
      final taskService = ref.read(taskServiceProvider);
      final FocusSessionRepository focusSessionRepository = ref.read(
        focusSessionRepositoryProvider,
      );

      // 创建特殊子任务："任务过于复杂，需要重新分析拆分。"
      final l10n = AppLocalizations.of(context);
      final overtimeSubtask = await taskService.captureInboxTask(
        title: l10n.clockOvertimeSubtaskTitle,
      );

      // 移动到父任务下
      final hierarchyService = ref.read(taskHierarchyServiceProvider);
      await hierarchyService.moveToParent(
        taskId: overtimeSubtask.id,
        parentId: widget.task.id,
        sortIndex: -1, // 放在最前面
      );

      // 设置为已完成状态
      await taskService.updateDetails(
        taskId: overtimeSubtask.id,
        payload: TaskUpdate(
          status: TaskStatus.completedActive,
          dueAt: widget.task.dueAt, // 使用父任务的截止时间
        ),
      );

      // 计算本次开始到暂停的时间
      final actualMinutes = _calculatePauseTime();

      if (actualMinutes > 0) {
        // 创建已完成的 FocusSession 记录时间
        final session = await focusSessionRepository.startSession(
          taskId: overtimeSubtask.id,
          estimateMinutes: null,
          alarmEnabled: false,
        );

        // 立即结束会话，记录 actualMinutes
        await focusSessionRepository.endSession(
          sessionId: session.id,
          actualMinutes: actualMinutes,
          transferToTaskId: null,
          reflectionNote: null,
        );

        // 递归更新父任务时间
        await _updateParentTaskTime(widget.task.id);
      }
    } catch (e) {
      debugPrint('Failed to create overtime subtask: $e');
    }
  }

    int _calculatePauseTime() {
    // 计算从开始到暂停的时间（分钟）
    if (widget.timerState.startTime == null) {
      return 0;
    }

    final pauseTime = widget.timerState.pausePeriods.isNotEmpty
        ? widget.timerState.pausePeriods.last.start
        : DateTime.now();

    final duration = pauseTime.difference(widget.timerState.startTime!);
    return duration.inMinutes.clamp(0, 24 * 60);
  }

    Future<void> _updateParentTaskTime(String taskId) async {
    // 递归更新父任务时间
    // 确保每个父任务的时间都是其所有子任务时间的总和

    try {
      final taskRepository = ref.read(taskRepositoryProvider);
      final FocusSessionRepository focusSessionRepository = ref.read(
        focusSessionRepositoryProvider,
      );
      final task = await taskRepository.findById(taskId);

      if (task == null || task.parentId == null) {
        // 没有父任务，递归结束
        return;
      }

      final parentId = task.parentId!;

      // 获取父任务的所有子任务
      final children = await taskRepository.listChildren(parentId);

      // 计算所有子任务的时间总和
      int totalMinutes = 0;
      for (final child in children) {
        final childMinutes = await focusSessionRepository.totalMinutesForTask(
          child.id,
        );
        totalMinutes += childMinutes;
      }

      // 为父任务创建或更新 FocusSession，记录总和
      // 查找父任务是否已有 FocusSession
      final existingSessions = await focusSessionRepository.listRecentSessions(
        taskId: parentId,
        limit: 1,
      );

      if (existingSessions.isNotEmpty &&
          existingSessions.first.endedAt == null) {
        // 如果存在未结束的会话，更新它
        await focusSessionRepository.endSession(
          sessionId: existingSessions.first.id,
          actualMinutes: totalMinutes,
          transferToTaskId: null,
          reflectionNote: null,
        );
      } else {
        // 创建新的会话并立即结束，记录总和
        final session = await focusSessionRepository.startSession(
          taskId: parentId,
          estimateMinutes: null,
          alarmEnabled: false,
        );
        await focusSessionRepository.endSession(
          sessionId: session.id,
          actualMinutes: totalMinutes,
          transferToTaskId: null,
          reflectionNote: null,
        );
      }

      // 递归向上更新父任务的父任务
    await _updateParentTaskTime(parentId);
    } catch (e) {
      debugPrint('Failed to update parent task time: $e');
    }
  }

  void _handleSubtaskStartTimer(Task subtask) {
    // 导航到计时器页面
  context.push('/clock/${subtask.id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final bool isTablet = MediaQuery.of(context).size.width >= 600;
    final double maxListHeight = isTablet ? 420 : 320;
    final childrenAsync = ref.watch(
      clockSubtaskListProvider(widget.task.id),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和添加按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.clockSubtasks,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // 第三级任务不显示添加按钮
                if (_taskLevel != null && _taskLevel! < 3)
                  IconButton(
                    icon: Icon(Icons.add, color: colorScheme.onSurface),
                    onPressed: _handleAddSubtask,
                    tooltip: l10n.actionAddSubtask,
                  ),
              ],
            ),
            // 第三级任务显示警告信息
            if (_taskLevel != null && _taskLevel! >= 3) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.clockLevel3Warning,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // 子任务列表
            const SizedBox(height: 12),
            childrenAsync.when(
              data: (children) {
                if (children.isEmpty) {
                  return const SizedBox.shrink();
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListHeight),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      final subtask = children[index];
                      return ClockSubtaskItem(
                        subtask: subtask,
                        onStartTimer: () => _handleSubtaskStartTimer(subtask),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                  ),
                );
              },
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 子任务项组件
