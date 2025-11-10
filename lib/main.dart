import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'core/app.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化前台服务（Android）
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'grano_timer',
      channelName: 'GranoFlow Timer',
      channelDescription: '计时进行中',
      channelImportance: NotificationChannelImportance.HIGH,
      priority: NotificationPriority.HIGH,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.VISIBILITY_PUBLIC,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(1000),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  // 初始化通知服务
  final notificationService = NotificationService();
  await notificationService.initialize();

  // 请求通知权限（Android 13+ 和 iOS）
  await notificationService.requestPermission();

  // TODO: Initialize ObjectBox Store properly
  // For now, create a placeholder - this will need proper Store initialization
  // final store = await _openObjectBoxStore();
  // final adapter = ObjectBoxAdapter(store);
  
  runApp(
    ProviderScope(
      // TODO: Add databaseAdapterProvider override once Store is properly initialized
      // overrides: [databaseAdapterProvider.overrideWithValue(adapter)],
      child: const GranoFlowApp(),
    ),
  );
}

// TODO: Implement proper ObjectBox Store initialization
// Future<Store> _openObjectBoxStore() async {
//   final dir = await getApplicationSupportDirectory();
//   // This will need the generated ObjectBox model code
//   // final model = getObjectBoxModel();
//   // return Store(getObjectBoxModel(), directory: dir.path);
//   throw UnimplementedError('ObjectBox Store initialization not yet implemented');
// }
