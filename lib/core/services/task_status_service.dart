import 'package:flutter/foundation.dart';
import '../../core/config/app_constants.dart';
import '../../data/models/task.dart';
import '../../data/repositories/focus_session_repository.dart';
import '../../data/repositories/task_repository.dart';
import 'clock_audio_service.dart';
import 'metric_orchestrator.dart';
import 'preference_service.dart';

/// 任务状态管理服务
/// 负责任务状态相关的操作，如标记进行中、完成、归档、软删除等
class TaskStatusService {
  TaskStatusService({
    required TaskRepository taskRepository,
    required MetricOrchestrator metricOrchestrator,
    FocusSessionRepository? focusSessionRepository,
    ClockAudioService? clockAudioService,
    PreferenceService? preferenceService,
    DateTime Function()? clock,
  }) : _tasks = taskRepository,
       _metricOrchestrator = metricOrchestrator,
       _focusSessionRepository = focusSessionRepository,
       _clockAudioService = clockAudioService,
       _preferenceService = preferenceService,
       _clock = clock ?? DateTime.now;

  final TaskRepository _tasks;
  final MetricOrchestrator _metricOrchestrator;
  final FocusSessionRepository? _focusSessionRepository;
  final ClockAudioService? _clockAudioService;
  final PreferenceService? _preferenceService;
  final DateTime Function() _clock;

  /// 检查是否有doing状态的任务，并控制背景音
  Future<void> _updateBackgroundSound() async {
    if (_clockAudioService == null || _preferenceService == null) {
      return;
    }

    // 检查设置是否允许播放背景音
    // 使用watch().first获取当前preference值
    final preference = await _preferenceService.watch().first;
    if (!preference.clockTickSoundEnabled) {
      return;
    }

    // 查找所有doing状态的任务
    final doingTasks = await _tasks.searchByTitle(
      '',
      status: TaskStatus.doing,
      limit: 10000,
    );

    final clockAudioService = _clockAudioService;
    if (clockAudioService != null) {
      if (doingTasks.isNotEmpty) {
        // 有doing状态的任务，开始播放背景音
        clockAudioService.startTickSound();
      } else {
        // 没有doing状态的任务，停止播放背景音
        clockAudioService.stopTickSound();
      }
    }
  }

  /// 标记任务为进行中
  /// 同时自动将所有其他doing状态的任务切换为paused状态
  Future<void> markInProgress(String taskId) async {
    // 先查找所有doing状态的任务（排除当前任务）
    // 使用searchByTitle查询所有doing状态的任务（使用空字符串匹配所有任务）
    final doingTasks = await _tasks.searchByTitle(
      '',
      status: TaskStatus.doing,
      limit: 10000, // 设置一个足够大的限制
    );
    final otherDoingTasks = doingTasks
        .where((task) => task.id != taskId)
        .toList();
    
    // 批量将其他doing状态的任务切换为paused
    if (otherDoingTasks.isNotEmpty) {
      final updates = <String, TaskUpdate>{};
      for (final task in otherDoingTasks) {
        updates[task.id] = TaskUpdate(status: TaskStatus.paused);
      }
      await _tasks.batchUpdate(updates);
    }
    
    // 将当前任务标记为doing
    await _tasks.markStatus(taskId: taskId, status: TaskStatus.doing);
    
    // 更新背景音状态（当前任务变为doing，应该开始播放）
    await _updateBackgroundSound();
  }

  /// 标记任务为已暂停
  Future<void> markPaused(String taskId) async {
    // 先检查当前任务是否是doing状态
    final task = await _tasks.findById(taskId);
    final wasDoing = task?.status == TaskStatus.doing;
    
    await _tasks.markStatus(taskId: taskId, status: TaskStatus.paused);
    
    // 如果任务从doing变为paused，需要检查是否还有其他doing任务
    if (wasDoing) {
      await _updateBackgroundSound();
    }
  }

  /// 标记任务为恢复（从暂停状态恢复为进行中）
  /// 同时自动将所有其他doing状态的任务切换为paused状态
  Future<void> markResumed(String taskId) async {
    // 先查找所有doing状态的任务（排除当前任务）
    // 使用searchByTitle查询所有doing状态的任务（使用空字符串匹配所有任务）
    final doingTasks = await _tasks.searchByTitle(
      '',
      status: TaskStatus.doing,
      limit: 10000, // 设置一个足够大的限制
    );
    final otherDoingTasks = doingTasks
        .where((task) => task.id != taskId)
        .toList();
    
    // 批量将其他doing状态的任务切换为paused
    if (otherDoingTasks.isNotEmpty) {
      final updates = <String, TaskUpdate>{};
      for (final task in otherDoingTasks) {
        updates[task.id] = TaskUpdate(status: TaskStatus.paused);
      }
      await _tasks.batchUpdate(updates);
    }
    
    // 将当前任务标记为doing
    await _tasks.markStatus(taskId: taskId, status: TaskStatus.doing);
    
    // 更新背景音状态（当前任务变为doing，应该开始播放）
    await _updateBackgroundSound();
  }

  /// 标记任务为已完成
  ///
  /// [taskId] 任务 ID
  /// [autoCompleteParent] 如果所有子任务都完成，是否自动完成父任务
  Future<void> markCompleted({
    required String taskId,
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
        final totalMinutes =
            await _focusSessionRepository.totalMinutesForTask(taskId);
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
    
    // 检查任务是否是doing状态
    final wasDoing = task.status == TaskStatus.doing;
    
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
    
    // 如果任务从doing变为completed，需要检查是否还有其他doing任务
    if (wasDoing) {
      await _updateBackgroundSound();
    }
  }

  /// 归档任务
  Future<void> archive(String taskId) async {
    if (kDebugMode) {
      debugPrint('[ArchiveTask] TaskStatusService.archive: taskId=$taskId');
    }
    
    // 检查任务是否是doing状态
    final task = await _tasks.findById(taskId);
    final wasDoing = task?.status == TaskStatus.doing;
    
    await _tasks.archiveTask(taskId);
    if (kDebugMode) {
      debugPrint('[ArchiveTask] TaskStatusService.archive: taskId=$taskId completed');
    }
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    
    // 如果任务从doing变为archived，需要检查是否还有其他doing任务
    if (wasDoing) {
      await _updateBackgroundSound();
    }
  }

  /// 软删除任务（移到回收站）
  ///
  /// 如果任务被模板锁定，会抛出 StateError
  Future<void> softDelete(String taskId) async {
    final task = await _tasks.findById(taskId);
    if (task != null && task.templateLockCount > 0) {
      throw StateError('Task is locked by templates; remove template first.');
    }
    
    // 检查任务是否是doing状态
    final wasDoing = task?.status == TaskStatus.doing;
    
    await _tasks.softDelete(taskId);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    
    // 如果任务从doing变为trashed，需要检查是否还有其他doing任务
    if (wasDoing) {
      await _updateBackgroundSound();
    }
  }
}

