import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Android 前台服务任务处理器（顶层回调）
/// 
/// 必须是顶层函数，不能是类的成员
/// 负责在独立的 Isolate 中更新通知栏内容
@pragma('vm:entry-point')
void pinnedTaskStartCallback() {
  FlutterForegroundTask.setTaskHandler(PinnedTaskHandler());
}

/// 置顶任务处理器
class PinnedTaskHandler extends TaskHandler {
  String _taskTitle = '';
  int _startEpochMs = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 从存储中读取任务信息
    final allData = await FlutterForegroundTask.getAllData();
    _taskTitle = allData['taskTitle'] as String? ?? '';
    _startEpochMs = allData['startEpochMs'] as int? ?? 
        DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // 注意：onRepeatEvent 的调用频率由 FlutterForegroundTask.init 中的 eventAction 配置决定
    // 由于我们使用相同的 FlutterForegroundTask.init（每秒调用一次），
    // 我们需要在这里检查是否到了更新间隔（每分钟）
    // 但为了简化，我们每次都更新（每秒更新一次时间也是合理的）
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = now - _startEpochMs;
    final elapsed = Duration(milliseconds: elapsedMs);
    
    // 格式化时间（使用紧凑格式）
    final timeText = _formatElapsedTimeCompact(elapsed);
    
    // 更新通知内容
    FlutterForegroundTask.updateService(
      notificationTitle: _taskTitle.isEmpty ? '置顶任务' : _taskTitle,
      notificationText: timeText,
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // 清理资源
  }

  @override
  void onNotificationButtonPressed(String id) {
    // 处理通知按钮点击
    if (id == 'complete') {
      // 保存完成标记到存储，然后停止服务
      // 主 Isolate 会在服务停止时检查这个标记并完成任务
      FlutterForegroundTask.saveData(
        key: 'shouldComplete',
        value: true,
      );
      FlutterForegroundTask.stopService();
    }
  }

  /// 格式化已用时间为紧凑格式（MM:SS 或 HH:MM:SS）
  String _formatElapsedTimeCompact(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      // 超过1小时：显示 HH:MM:SS 格式
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    } else {
      // 小于1小时：显示 MM:SS 格式
      return '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
  }
}

