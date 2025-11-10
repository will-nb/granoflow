import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:path_provider/path_provider.dart';
// ignore: unused_import

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'core/app.dart';
import 'core/providers/repository_providers.dart';
import 'core/services/notification_service.dart';
import 'package:granoflow/data/objectbox/focus_session_entity.dart';

Isar? _isarInstance;

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

  final isar = await _openIsar();
  runApp(
    ProviderScope(
      overrides: [isarProvider.overrideWithValue(isar)],
      child: const GranoFlowApp(),
    ),
  );
}

Future<Isar> _openIsar() async {
  // 如果实例已经打开，直接返回（用于集成测试场景）
  if (_isarInstance != null && _isarInstance!.isOpen) {
    return _isarInstance!;
  }

  try {
    final dir = await getApplicationSupportDirectory();
    final isar = await Isar.open(
      [
        TaskEntitySchema,
        TaskTemplateEntitySchema,
        FocusSessionEntitySchema,
        TagEntitySchema,
        PreferenceEntitySchema,
        SeedImportLogEntitySchema,
        ProjectEntitySchema,
        MilestoneEntitySchema,
      ],
      directory: dir.path,
      inspector: false,
    );
    _isarInstance = isar;
    return isar;
  } catch (e) {
    // 如果 Isar 已经打开，尝试获取已打开的实例
    // Isar.open() 在同一个目录下如果已经打开会抛出异常
    // 这种情况下，我们返回缓存的实例（如果存在）
    if (_isarInstance != null && _isarInstance!.isOpen) {
      return _isarInstance!;
    }
    rethrow;
  }
}
