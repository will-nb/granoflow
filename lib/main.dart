import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'core/app.dart';
import 'core/services/notification_service.dart';
import 'core/providers/repository_providers.dart';
import 'core/config/database_config.dart';
import 'objectbox.g.dart';

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

  // 根据 DatabaseConfig 初始化数据库
  final databaseType = await DatabaseConfig.current;
  
  // 如果使用 ObjectBox，需要初始化 Store
  Store? store;
  if (databaseType == DatabaseType.objectbox) {
    store = await _openObjectBoxStore();
  }
  
  runApp(
    ProviderScope(
      overrides: [
        // 如果使用 ObjectBox，提供 Store
        if (store != null)
          objectBoxStoreProvider.overrideWithValue(store),
      ],
      child: const GranoFlowApp(),
    ),
  );
}

/// 初始化 ObjectBox Store
Future<Store> _openObjectBoxStore() async {
  // 对于 macOS，使用默认目录（openStore 会自动处理）
  // 如果指定目录，可能会遇到沙盒权限问题
  try {
    // 先尝试使用默认目录（openStore 会自动使用合适的目录）
    return await openStore();
  } catch (e) {
    // 如果默认目录失败，尝试使用应用支持目录
    debugPrint('Failed to open store with default directory: $e');
    try {
      final dir = await getApplicationSupportDirectory();
      // 确保目录存在
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return await openStore(directory: dir.path);
    } catch (e2) {
      debugPrint('Failed to open store at application support directory: $e2');
      rethrow;
    }
  }
}
