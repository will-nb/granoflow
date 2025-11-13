import 'package:go_router/go_router.dart';

/// 置顶任务通知处理器
/// 
/// 处理通知点击和按钮点击事件
class PinnedTaskNotificationHandler {
  /// 处理通知点击
  /// 
  /// 导航到任务列表页面并滚动到置顶任务
  static void handleNotificationTap(GoRouter router) {
    // 导航到任务列表页面，添加 scrollToPinned 参数
    router.go('/tasks?scrollToPinned=true');
  }

  /// 处理完成按钮点击
  /// 
  /// 完成任务并清除置顶
  /// 注意：这个功能需要在应用层实现，因为需要访问任务服务
  static void handleCompleteButtonTap() {
    // 这个功能需要在应用层实现
    // 可以通过 SendPort 发送消息到主 Isolate，或者通过其他方式
    // 暂时先记录，具体实现需要在应用层处理
  }
}

