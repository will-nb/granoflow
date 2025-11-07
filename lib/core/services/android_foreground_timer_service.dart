import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'foreground_timer_task_handler.dart';
import 'timer_background_service.dart';

/// Android 前台服务封装
/// 
/// 使用 flutter_foreground_task 实现 Android 前台服务和通知栏显示
class AndroidForegroundTimerService implements TimerBackgroundService {
  AndroidForegroundTimerService();

  bool _isRunning = false;

  @override
  Future<void> startTimer({
    required DateTime endTime,
    required Duration duration,
  }) async {
    if (_isRunning) {
      return;
    }

    // 保存结束时间戳到前台服务存储
    await FlutterForegroundTask.saveData(
      key: 'endEpochMs',
      value: endTime.millisecondsSinceEpoch,
    );

    // 格式化倒计时显示
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final countdownText = '剩余 ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // 启动前台服务
    // 注意：通知图标必须通过 NotificationIcon 指定，metaDataName 对应 AndroidManifest 中的 meta-data
    final result = await FlutterForegroundTask.startService(
      notificationTitle: '专注中',
      notificationText: countdownText,
      notificationIcon: const NotificationIcon(metaDataName: 'com.pravera.flutter_foreground_task.notification_icon'),
      notificationButtons: [
        const NotificationButton(id: 'pause', text: '暂停'),
        const NotificationButton(id: 'stop', text: '结束'),
      ],
      callback: timerTaskStartCallback,
    );

    if (result is ServiceRequestSuccess) {
      _isRunning = true;
    }
  }

  @override
  Future<void> pauseTimer() async {
    await stopTimer();
  }

  @override
  Future<void> resumeTimer() async {
    // 恢复时需要重新计算剩余时间
    // 这里需要从持久化存储读取状态
    // 暂时先停止，由调用方重新调用 startTimer
    await stopTimer();
  }

  @override
  Future<void> stopTimer() async {
    if (!_isRunning) {
      return;
    }

    await FlutterForegroundTask.stopService();
    _isRunning = false;
  }

  @override
  Future<bool> isRunning() async {
    // 检查服务是否真的在运行
    final isRunningService = await FlutterForegroundTask.isRunningService;
    _isRunning = isRunningService;
    return _isRunning;
  }

  @override
  Future<void> dispose() async {
    await stopTimer();
  }
}

