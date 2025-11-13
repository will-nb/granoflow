import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/focus_session.dart';
import '../../data/models/task.dart';
import '../services/pinned_task_background_service.dart';
import '../services/pinned_task_persistence_service.dart';
import 'app_providers.dart';
import 'pinned_task_background_service_provider.dart';
import 'pinned_task_persistence_service_provider.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

/// 置顶任务ID状态管理 Notifier
class PinnedTaskIdNotifier extends StateNotifier<String?> {
  /// 私有构造函数，用于从 Provider 创建（异步初始化依赖）
  PinnedTaskIdNotifier._(this._ref)
      : _backgroundService = null,
        _persistenceService = null,
        super(null) {
    _initAsync();
  }

  final Ref _ref;
  PinnedTaskBackgroundService? _backgroundService;
  PinnedTaskPersistenceService? _persistenceService;
  Timer? _updateTimer;
  String? _currentTaskId;

  /// 异步初始化依赖
  Future<void> _initAsync() async {
    _backgroundService = _ref.read(pinnedTaskBackgroundServiceProvider);
    _persistenceService = _ref.read(pinnedTaskPersistenceServiceProvider);

    // 尝试从持久化存储恢复状态
    await _loadState();
  }

  /// 获取 PinnedTaskBackgroundService（延迟初始化）
  PinnedTaskBackgroundService get _backgroundServiceOrThrow {
    if (_backgroundService == null) {
      throw StateError('PinnedTaskIdNotifier not initialized. Call _initAsync() first.');
    }
    return _backgroundService!;
  }

  /// 获取 PinnedTaskPersistenceService（延迟初始化）
  PinnedTaskPersistenceService get _persistenceServiceOrThrow {
    if (_persistenceService == null) {
      throw StateError('PinnedTaskIdNotifier not initialized. Call _initAsync() first.');
    }
    return _persistenceService!;
  }

  /// 设置置顶任务ID
  Future<void> setPinnedTaskId(String? taskId) async {
    // 如果任务ID相同，不执行任何操作
    if (state == taskId) {
      return;
    }

    // 停止之前的通知和定时器
    if (state != null) {
      await _stopNotification();
    }

    // 更新状态
    state = taskId;

    // 保存到持久化存储
    if (_persistenceService != null) {
      try {
        await _persistenceServiceOrThrow.savePinnedTaskId(taskId);
      } catch (e) {
        // 持久化失败不应该影响功能，只记录错误
        // ignore: avoid_print
        print('Failed to save pinned task ID: $e');
      }
    }

    // 如果设置了新任务，启动通知
    if (taskId != null) {
      await _startNotification(taskId);
    }
  }

  /// 启动通知
  Future<void> _startNotification(String taskId) async {
    if (_backgroundService == null) {
      return;
    }

    try {
      // 获取任务信息
      final taskAsync = await _ref.read(taskByIdProvider(taskId).future);
      final task = taskAsync;
      
      if (task == null) {
        // 任务不存在，清除置顶
        await setPinnedTaskId(null);
        return;
      }

      // 启动前台通知
      await _backgroundServiceOrThrow.startNotification(
        taskId: taskId,
        taskTitle: task.title.isEmpty ? '置顶任务' : task.title,
      );

      _currentTaskId = taskId;

      // 启动定时器，每分钟更新一次通知
      _updateTimer?.cancel();
      _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
        await _updateNotification();
      });

      // 立即更新一次
      await _updateNotification();
    } catch (e) {
      // 启动通知失败不应该影响功能，只记录错误
      // ignore: avoid_print
      print('Failed to start pinned task notification: $e');
    }
  }

  /// 更新通知内容
  Future<void> _updateNotification() async {
    if (_backgroundService == null || _currentTaskId == null) {
      return;
    }

    try {
      // 获取任务信息
      final taskAsync = await _ref.read(taskByIdProvider(_currentTaskId!).future);
      final task = taskAsync;

      if (task == null) {
        // 任务不存在，清除置顶
        await setPinnedTaskId(null);
        return;
      }

      // 获取 FocusSession 计算已用时间
      // 注意：focusSessionProvider 是 StreamProvider，使用 .future 获取第一个值
      final sessionAsyncValue = await _ref.read(focusSessionProvider(_currentTaskId!).future) as AsyncValue<FocusSession?>;
      final session = sessionAsyncValue.maybeWhen(
        data: (value) => value,
        orElse: () => null,
      );

      Duration elapsed = Duration.zero;
      if (session != null && session.isActive) {
        elapsed = DateTime.now().difference(session.startedAt);
      }

      // 更新通知
      await _backgroundServiceOrThrow.updateNotification(
        taskId: _currentTaskId!,
        taskTitle: task.title.isEmpty ? '置顶任务' : task.title,
        elapsed: elapsed,
      );
    } catch (e) {
      // 更新通知失败不应该影响功能，只记录错误
      // ignore: avoid_print
      print('Failed to update pinned task notification: $e');
    }
  }

  /// 停止通知
  Future<void> _stopNotification() async {
    _updateTimer?.cancel();
    _updateTimer = null;
    
    final taskIdToComplete = _currentTaskId;
    _currentTaskId = null;

    if (_backgroundService != null) {
      try {
        await _backgroundServiceOrThrow.stopNotification();
        
        // 检查是否有需要完成的任务（从通知按钮触发）
        // AndroidForegroundPinnedTaskService 会在 stopNotification 中检查完成标记
        // 并将任务ID保存到 completedTaskId，我们需要在这里检查并完成任务
        try {
          final allData = await FlutterForegroundTask.getAllData();
          final completedTaskId = allData['completedTaskId'] as String?;
          
          // 如果是从完成按钮触发的，完成任务
          if (completedTaskId != null && completedTaskId == taskIdToComplete) {
            final taskService = await _ref.read(taskServiceProvider.future);
            final taskAsync = await _ref.read(taskByIdProvider(completedTaskId).future);
            final task = taskAsync;
            
            if (task != null && 
                task.status != TaskStatus.completedActive &&
                task.status != TaskStatus.trashed &&
                task.status != TaskStatus.archived) {
              // 完成任务
              await taskService.markCompleted(taskId: completedTaskId);
            }
            
            // 清除完成标记（通过删除键）
            // 注意：FlutterForegroundTask.saveData 可能不支持 null 值，所以我们需要删除键
            // 但 FlutterForegroundTask 没有提供删除方法，所以暂时保留值
            // 下次启动服务时会覆盖
          }
        } catch (e) {
          // 完成任务失败不应该影响功能，只记录错误
          // ignore: avoid_print
          print('Failed to complete task from notification: $e');
        }
      } catch (e) {
        // 停止通知失败不应该影响功能，只记录错误
        // ignore: avoid_print
        print('Failed to stop pinned task notification: $e');
      }
    }
  }

  /// 从持久化存储恢复状态
  Future<void> _loadState() async {
    if (_persistenceService == null) {
      return;
    }

    try {
      final savedTaskId = await _persistenceServiceOrThrow.loadPinnedTaskId();
      if (savedTaskId != null) {
        // 验证任务是否仍然存在且状态有效
        final taskAsync = await _ref.read(taskByIdProvider(savedTaskId).future);
        final task = taskAsync;

        if (task != null &&
            task.status != TaskStatus.completedActive &&
            task.status != TaskStatus.trashed &&
            task.status != TaskStatus.archived) {
          // 任务有效，恢复状态（但不触发持久化保存，因为已经存在）
          state = savedTaskId;
          await _startNotification(savedTaskId);
        } else {
          // 任务无效，清除持久化状态
          await _persistenceServiceOrThrow.clearPinnedTaskId();
        }
      }
    } catch (e) {
      // 恢复失败不应该影响应用启动，只记录错误
      // ignore: avoid_print
      print('Failed to load pinned task state: $e');
    }
  }

  /// 检查并恢复 doing 状态的任务为置顶
  ///
  /// 如果当前没有置顶任务，且存在 doing 状态的任务，则自动置顶第一个 doing 任务。
  /// 这个方法主要用于应用被强制退出后重新进入时，自动恢复 doing 任务的置顶状态。
  Future<void> checkAndRestoreDoingTask() async {
    // 如果已经有置顶任务，不需要检查
    if (state != null) {
      return;
    }

    try {
      // 获取 TaskRepository
      final taskRepository = await _ref.read(taskRepositoryProvider.future);
      
      // 查询第一个 doing 状态的任务
      final doingTasks = await taskRepository.searchByTitle(
        '',
        status: TaskStatus.doing,
        limit: 1,
      );

      if (doingTasks.isNotEmpty) {
        final doingTask = doingTasks.first;
        
        // 验证任务有效性
        if (doingTask.status != TaskStatus.completedActive &&
            doingTask.status != TaskStatus.trashed &&
            doingTask.status != TaskStatus.archived) {
          // 任务有效，设置为置顶
          await setPinnedTaskId(doingTask.id);
        }
      }
    } catch (e) {
      // 检查失败不应该影响功能，只记录错误
      // ignore: avoid_print
      print('Failed to check and restore doing task: $e');
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _backgroundService?.dispose();
    super.dispose();
  }
}

/// 置顶任务ID Provider
/// 
/// 当任务被置顶时，该任务的 ID 会被设置为当前值。
/// 当置顶任务完成、删除或归档时，该值会被重置为 `null`。
final pinnedTaskIdProvider = StateNotifierProvider<PinnedTaskIdNotifier, String?>((ref) {
  return PinnedTaskIdNotifier._(ref);
});
