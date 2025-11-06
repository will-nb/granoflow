import 'package:flutter/foundation.dart';
import '../../core/config/app_constants.dart';
import '../../data/models/task.dart';
import '../../data/repositories/focus_session_repository.dart';
import '../../data/repositories/task_repository.dart';
import 'metric_orchestrator.dart';

/// 任务状态管理服务
/// 负责任务状态相关的操作，如标记进行中、完成、归档、软删除等
class TaskStatusService {
  TaskStatusService({
    required TaskRepository taskRepository,
    required MetricOrchestrator metricOrchestrator,
    FocusSessionRepository? focusSessionRepository,
    DateTime Function()? clock,
  }) : _tasks = taskRepository,
       _metricOrchestrator = metricOrchestrator,
       _focusSessionRepository = focusSessionRepository,
       _clock = clock ?? DateTime.now;

  final TaskRepository _tasks;
  final MetricOrchestrator _metricOrchestrator;
  final FocusSessionRepository? _focusSessionRepository;
  final DateTime Function() _clock;

  /// 标记任务为进行中
  Future<void> markInProgress(int taskId) async {
    await _tasks.markStatus(taskId: taskId, status: TaskStatus.doing);
  }

  /// 标记任务为已完成
  ///
  /// [taskId] 任务 ID
  /// [autoCompleteParent] 如果所有子任务都完成，是否自动完成父任务
  Future<void> markCompleted({
    required int taskId,
    bool autoCompleteParent = true,
  }) async {
    final task = await _tasks.findById(taskId);
    if (task == null) {
      return;
    }
    if (!task.canEditStructure && !task.allowInstantComplete) {
      throw StateError('Task is locked and cannot be completed directly.');
    }
    
    // 如果任务没有运行时间记录，创建一个默认的 FocusSession 记录默认时间
    if (_focusSessionRepository != null) {
      final totalMinutes = await _focusSessionRepository.totalMinutesForTask(taskId);
      if (totalMinutes == 0) {
        // 创建并立即结束一个 FocusSession，记录默认时间
        final session = await _focusSessionRepository.startSession(
          taskId: taskId,
          estimateMinutes: AppConstants.defaultTaskCompletionMinutes,
          alarmEnabled: false,
        );
        await _focusSessionRepository.endSession(
          sessionId: session.id,
          actualMinutes: AppConstants.defaultTaskCompletionMinutes,
          transferToTaskId: null,
          reflectionNote: null,
        );
      }
    }
    
    await _tasks.updateTask(
      taskId,
      TaskUpdate(status: TaskStatus.completedActive, endedAt: _clock()),
    );
    if (autoCompleteParent && task.parentId != null) {
      final siblings = await _tasks.listChildren(task.parentId!);
      final allCompleted = siblings.every(
        (sibling) => sibling.status == TaskStatus.completedActive,
      );
      if (allCompleted) {
        await _tasks.updateTask(
          task.parentId!,
          TaskUpdate(status: TaskStatus.completedActive, endedAt: _clock()),
        );
      }
    }
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 归档任务
  Future<void> archive(int taskId) async {
    if (kDebugMode) {
      debugPrint('[ArchiveTask] TaskStatusService.archive: taskId=$taskId');
    }
    await _tasks.archiveTask(taskId);
    if (kDebugMode) {
      debugPrint('[ArchiveTask] TaskStatusService.archive: taskId=$taskId completed');
    }
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 软删除任务（移到回收站）
  ///
  /// 如果任务被模板锁定，会抛出 StateError
  Future<void> softDelete(int taskId) async {
    final task = await _tasks.findById(taskId);
    if (task != null && task.templateLockCount > 0) {
      throw StateError('Task is locked by templates; remove template first.');
    }
    await _tasks.softDelete(taskId);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }
}

