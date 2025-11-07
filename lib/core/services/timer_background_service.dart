import 'dart:async';

/// 计时器后台服务统一抽象接口
/// 
/// 提供跨平台的后台计时服务，Android 使用前台服务，iOS 使用本地通知
abstract class TimerBackgroundService {
  /// 启动计时器后台服务
  /// 
  /// [endTime] 计时结束时间
  /// [duration] 计时时长
  Future<void> startTimer({
    required DateTime endTime,
    required Duration duration,
  });

  /// 暂停计时器后台服务
  Future<void> pauseTimer();

  /// 恢复计时器后台服务
  Future<void> resumeTimer();

  /// 停止计时器后台服务
  Future<void> stopTimer();

  /// 检查服务是否正在运行
  Future<bool> isRunning();

  /// 销毁服务（清理资源）
  Future<void> dispose();
}

