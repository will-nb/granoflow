import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'timer_background_service.dart';
import 'timer_background_service_stub.dart';

// 条件导入平台特定实现
// 注意：由于需要依赖注入，这里使用运行时判断而不是条件导入
import 'android_foreground_timer_service.dart';
import 'ios_notification_timer_service.dart';
import 'notification_service.dart';

/// 创建平台特定的计时器后台服务实例
/// 
/// 根据运行平台返回对应的实现：
/// - Android: AndroidForegroundTimerService
/// - iOS: IOSNotificationTimerService（需要 NotificationService）
/// - 其他平台: TimerBackgroundServiceStub
/// 
/// [notificationService] iOS 平台需要提供 NotificationService 实例
TimerBackgroundService createTimerBackgroundService({
  NotificationService? notificationService,
}) {
  if (kIsWeb) {
    return TimerBackgroundServiceStub();
  }

  try {
    if (Platform.isAndroid) {
      return AndroidForegroundTimerService();
    } else if (Platform.isIOS) {
      if (notificationService == null) {
        // 如果没有提供 NotificationService，创建一个新的
        notificationService = NotificationService();
      }
      return IOSNotificationTimerService(notificationService: notificationService);
    } else {
      return TimerBackgroundServiceStub();
    }
  } catch (e) {
    // 如果平台检测失败，返回占位实现
    return TimerBackgroundServiceStub();
  }
}

