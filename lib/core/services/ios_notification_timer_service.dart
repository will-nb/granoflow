import 'dart:async';

import 'timer_background_service.dart';
import 'notification_service.dart';

/// iOS 本地通知服务封装
/// 
/// 使用 flutter_local_notifications 实现 iOS 本地通知调度
class IOSNotificationTimerService implements TimerBackgroundService {
  IOSNotificationTimerService({
    required NotificationService notificationService,
  }) : _notificationService = notificationService;

  final NotificationService _notificationService;
  bool _isRunning = false;
  int? _scheduledNotificationId;

  @override
  Future<void> startTimer({
    required DateTime endTime,
    required Duration duration,
  }) async {
    if (_isRunning) {
      return;
    }

    // 取消之前的通知（如果有）
    if (_scheduledNotificationId != null) {
      await _notificationService.cancelNotification(_scheduledNotificationId!);
    }

    // 调度到点通知
    _scheduledNotificationId = 1001; // 固定 ID
    await _notificationService.scheduleNotification(
      id: _scheduledNotificationId!,
      title: '专注完成',
      body: '时间到了，休息一下吧',
      scheduledDate: endTime,
    );

    _isRunning = true;
  }

  @override
  Future<void> pauseTimer() async {
    // 取消到点通知
    if (_scheduledNotificationId != null) {
      await _notificationService.cancelNotification(_scheduledNotificationId!);
      _scheduledNotificationId = null;
    }
    _isRunning = false;
  }

  @override
  Future<void> resumeTimer() async {
    // 恢复时需要重新计算结束时间并重新调度通知
    // 这里需要从持久化存储读取状态
    // 暂时先停止，由调用方重新调用 startTimer
    await pauseTimer();
  }

  @override
  Future<void> stopTimer() async {
    if (!_isRunning && _scheduledNotificationId == null) {
      return;
    }

    // 取消通知
    if (_scheduledNotificationId != null) {
      await _notificationService.cancelNotification(_scheduledNotificationId!);
      _scheduledNotificationId = null;
    }

    _isRunning = false;
  }

  @override
  Future<bool> isRunning() async {
    return _isRunning;
  }

  @override
  Future<void> dispose() async {
    await stopTimer();
  }
}

