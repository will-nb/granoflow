import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import '../services/timer_background_service.dart';
import '../services/timer_background_service_impl.dart';

/// 通知服务 Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// 计时器后台服务 Provider
/// 
/// 根据平台返回对应的实现
final timerBackgroundServiceProvider = Provider<TimerBackgroundService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return createTimerBackgroundService(notificationService: notificationService);
});

