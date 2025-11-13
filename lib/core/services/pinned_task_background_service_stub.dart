import 'pinned_task_background_service.dart';

/// 占位实现（用于不支持前台服务的平台，如 Web）
class PinnedTaskBackgroundServiceStub implements PinnedTaskBackgroundService {
  @override
  Future<void> startNotification({
    required String taskId,
    required String taskTitle,
  }) async {
    // 占位实现，不执行任何操作
  }

  @override
  Future<void> updateNotification({
    required String taskId,
    required String taskTitle,
    required Duration elapsed,
  }) async {
    // 占位实现，不执行任何操作
  }

  @override
  Future<void> stopNotification() async {
    // 占位实现，不执行任何操作
  }

  @override
  Future<bool> isRunning() async {
    return false;
  }

  @override
  Future<void> dispose() async {
    // 占位实现，不执行任何操作
  }
}

