import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import '../services/pinned_task_background_service.dart';
import '../services/pinned_task_background_service_impl.dart';

/// 通知服务 Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// 置顶任务后台服务 Provider
final pinnedTaskBackgroundServiceProvider = Provider<PinnedTaskBackgroundService>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return createPinnedTaskBackgroundService(notificationService: notificationService);
});

