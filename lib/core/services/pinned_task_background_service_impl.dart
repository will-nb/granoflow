import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'pinned_task_background_service.dart';
import 'pinned_task_background_service_stub.dart';

// 条件导入平台特定实现
// 注意：由于需要依赖注入，这里使用运行时判断而不是条件导入
import 'android_foreground_pinned_task_service.dart';
import 'ios_notification_pinned_task_service.dart';
import 'notification_service.dart';

/// 创建平台特定的置顶任务后台服务实例
/// 
/// 根据运行平台返回对应的实现：
/// - Android: AndroidForegroundPinnedTaskService
/// - iOS: IOSNotificationPinnedTaskService（需要 NotificationService）
/// - 其他平台: PinnedTaskBackgroundServiceStub
/// 
/// [notificationService] iOS 平台需要提供 NotificationService 实例
PinnedTaskBackgroundService createPinnedTaskBackgroundService({
  NotificationService? notificationService,
}) {
  if (kIsWeb) {
    return PinnedTaskBackgroundServiceStub();
  }

  try {
    if (Platform.isAndroid) {
      return AndroidForegroundPinnedTaskService();
    } else if (Platform.isIOS) {
      if (notificationService == null) {
        // 如果没有提供 NotificationService，创建一个新的
        notificationService = NotificationService();
      }
      return IOSNotificationPinnedTaskService(notificationService: notificationService);
    } else {
      return PinnedTaskBackgroundServiceStub();
    }
  } catch (e) {
    // 如果平台检测失败，返回占位实现
    return PinnedTaskBackgroundServiceStub();
  }
}

