import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Android 前台服务任务处理器（顶层回调）
/// 
/// 必须是顶层函数，不能是类的成员
/// 负责在独立的 Isolate 中更新通知栏倒计时
@pragma('vm:entry-point')
void timerTaskStartCallback() {
  FlutterForegroundTask.setTaskHandler(TimerTaskHandler());
}

/// 计时器任务处理器
class TimerTaskHandler extends TaskHandler {
  int _endEpochMs = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      // 从存储中读取结束时间戳
      final allData = await FlutterForegroundTask.getAllData();
      _endEpochMs = allData['endEpochMs'] as int? ?? 
          DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      // JNI 调用可能失败，使用当前时间作为默认值
      // ignore: avoid_print
      print('Failed to get data in timer task handler onStart: $e');
      _endEpochMs = DateTime.now().millisecondsSinceEpoch;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      var remainMs = _endEpochMs - now;
      
      if (remainMs < 0) {
        remainMs = 0;
      }

      // 格式化倒计时显示
      final minutes = (remainMs ~/ 60000).toString().padLeft(2, '0');
      final seconds = ((remainMs % 60000) ~/ 1000).toString().padLeft(2, '0');
      final countdownText = '剩余 $minutes:$seconds';

      // 更新通知内容
      try {
        FlutterForegroundTask.updateService(
          notificationTitle: '专注中',
          notificationText: countdownText,
        );
      } catch (e) {
        // 更新失败可能表示服务已停止，记录错误但不抛出
        // ignore: avoid_print
        print('Failed to update service in timer task handler: $e');
        return;
      }

      // 如果到点，停止服务
      if (remainMs <= 0) {
        try {
          FlutterForegroundTask.updateService(
            notificationTitle: '专注完成',
            notificationText: '时间到了，休息一下吧',
          );
        } catch (e) {
          // 更新失败，直接尝试停止服务
          // ignore: avoid_print
          print('Failed to update completion notification: $e');
        }
        // 延迟一下再停止，让用户看到完成通知
        Future.delayed(const Duration(seconds: 2), () {
          try {
            FlutterForegroundTask.stopService();
          } catch (e) {
            // 停止服务失败，可能服务已经停止，记录错误但不抛出
            // ignore: avoid_print
            print('Failed to stop service in timer task handler: $e');
          }
        });
      }
    } catch (e) {
      // 捕获所有未预期的异常，避免崩溃
      // ignore: avoid_print
      print('Unexpected error in timer task handler onRepeatEvent: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // 清理资源
  }

  @override
  void onNotificationButtonPressed(String id) {
    // 处理通知按钮点击
    // 这里可以通过 SendPort 发送消息给主 Isolate
    // 暂时只停止服务
    if (id == 'pause' || id == 'stop') {
      try {
        FlutterForegroundTask.stopService();
      } catch (e) {
        // JNI 调用可能失败，记录错误但不抛出异常
        // ignore: avoid_print
        print('Failed to stop service from notification button: $e');
      }
    }
  }
}

