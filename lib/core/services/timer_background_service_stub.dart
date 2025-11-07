import 'dart:async';

import 'timer_background_service.dart';

/// 占位实现（用于非移动平台，如桌面/Web）
/// 
/// 所有方法为空操作，不执行任何实际功能
class TimerBackgroundServiceStub implements TimerBackgroundService {
  @override
  Future<void> startTimer({
    required DateTime endTime,
    required Duration duration,
  }) async {
    // 空操作
  }

  @override
  Future<void> pauseTimer() async {
    // 空操作
  }

  @override
  Future<void> resumeTimer() async {
    // 空操作
  }

  @override
  Future<void> stopTimer() async {
    // 空操作
  }

  @override
  Future<bool> isRunning() async => false;

  @override
  Future<void> dispose() async {
    // 空操作
  }
}

