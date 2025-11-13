import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'foreground_pinned_task_handler.dart';
import 'pinned_task_background_service.dart';
import '../../presentation/clock/utils/clock_timer_utils.dart';

/// Android 前台服务封装
/// 
/// 使用 flutter_foreground_task 实现 Android 前台服务和通知栏显示
class AndroidForegroundPinnedTaskService implements PinnedTaskBackgroundService {
  AndroidForegroundPinnedTaskService();

  bool _isRunning = false;
  String? _currentTaskId;
  DateTime? _startTime;

  @override
  Future<void> startNotification({
    required String taskId,
    required String taskTitle,
  }) async {
    if (_isRunning && _currentTaskId == taskId) {
      return;
    }

    // 如果已有其他任务在运行，先停止
    if (_isRunning) {
      await stopNotification();
    }

    try {
      _currentTaskId = taskId;
      _startTime = DateTime.now();

      // 保存任务信息到前台服务存储
      await FlutterForegroundTask.saveData(
        key: 'taskId',
        value: taskId,
      );
      await FlutterForegroundTask.saveData(
        key: 'taskTitle',
        value: taskTitle,
      );
      await FlutterForegroundTask.saveData(
        key: 'startEpochMs',
        value: _startTime!.millisecondsSinceEpoch,
      );

      // 格式化初始时间显示
      final timeText = ClockTimerUtils.formatElapsedTimeCompact(Duration.zero);

      // 启动前台服务
      // 注意：通知图标必须通过 NotificationIcon 指定，metaDataName 对应 AndroidManifest 中的 meta-data
      // 注意：ForegroundTaskOptions 应该在 FlutterForegroundTask.init 中配置，这里不传递
      final result = await FlutterForegroundTask.startService(
        notificationTitle: taskTitle.isEmpty ? '置顶任务' : taskTitle,
        notificationText: timeText,
        notificationIcon: const NotificationIcon(metaDataName: 'com.pravera.flutter_foreground_task.notification_icon'),
        notificationButtons: [
          const NotificationButton(id: 'complete', text: '完成'),
        ],
        callback: pinnedTaskStartCallback,
      );

      if (result is ServiceRequestSuccess) {
        _isRunning = true;
      }
    } catch (e) {
      // JNI 调用可能失败，记录错误但不抛出异常
      // ignore: avoid_print
      print('Failed to start foreground pinned task service: $e');
      _isRunning = false;
      _currentTaskId = null;
      _startTime = null;
    }
  }

  @override
  Future<void> updateNotification({
    required String taskId,
    required String taskTitle,
    required Duration elapsed,
  }) async {
    if (!_isRunning || _currentTaskId != taskId) {
      return;
    }

    try {
      // 格式化时间显示
      final timeText = ClockTimerUtils.formatElapsedTimeCompact(elapsed);

      // 更新通知内容
      FlutterForegroundTask.updateService(
        notificationTitle: taskTitle.isEmpty ? '置顶任务' : taskTitle,
        notificationText: timeText,
      );
    } catch (e) {
      // JNI 调用可能失败（例如服务已停止或 Activity 已销毁），记录错误但不抛出异常
      // ignore: avoid_print
      print('Failed to update foreground pinned task service: $e');
      // 如果更新失败，可能服务已停止，更新状态
      _isRunning = false;
    }
  }

  @override
  Future<void> stopNotification() async {
    if (!_isRunning) {
      return;
    }

    try {
      // 检查是否有完成标记（从通知按钮触发）
      final allData = await FlutterForegroundTask.getAllData();
      final shouldComplete = allData['shouldComplete'] as bool? ?? false;
      
      // 如果是从完成按钮触发的，保存任务ID以便后续处理
      if (shouldComplete && _currentTaskId != null) {
        await FlutterForegroundTask.saveData(
          key: 'completedTaskId',
          value: _currentTaskId!,
        );
        // 清除完成标记
        await FlutterForegroundTask.saveData(
          key: 'shouldComplete',
          value: false,
        );
      }

      await FlutterForegroundTask.stopService();
    } catch (e) {
      // JNI 调用可能失败（例如服务已停止或 Activity 已销毁），记录错误但不抛出异常
      // ignore: avoid_print
      print('Failed to stop foreground pinned task service: $e');
    } finally {
      _isRunning = false;
      _currentTaskId = null;
      _startTime = null;
    }
  }

  @override
  Future<bool> isRunning() async {
    try {
      // 检查服务是否真的在运行
      final isRunningService = await FlutterForegroundTask.isRunningService;
      _isRunning = isRunningService;
      if (!_isRunning) {
        _currentTaskId = null;
        _startTime = null;
      }
      return _isRunning;
    } catch (e) {
      // JNI 调用可能失败，返回 false
      // ignore: avoid_print
      print('Failed to check foreground pinned task service status: $e');
      _isRunning = false;
      _currentTaskId = null;
      _startTime = null;
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    await stopNotification();
  }
}

