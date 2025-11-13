import 'dart:async';

/// 置顶任务后台服务统一抽象接口
/// 
/// 提供跨平台的后台通知服务，Android 使用前台服务，iOS 使用本地通知
abstract class PinnedTaskBackgroundService {
  /// 启动置顶任务通知
  /// 
  /// [taskId] 任务ID
  /// [taskTitle] 任务标题
  Future<void> startNotification({
    required String taskId,
    required String taskTitle,
  });

  /// 更新通知内容
  /// 
  /// [taskId] 任务ID
  /// [taskTitle] 任务标题
  /// [elapsed] 已用时间
  Future<void> updateNotification({
    required String taskId,
    required String taskTitle,
    required Duration elapsed,
  });

  /// 停止通知
  Future<void> stopNotification();

  /// 检查服务是否正在运行
  Future<bool> isRunning();

  /// 销毁服务（清理资源）
  Future<void> dispose();
}

