import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// 统一通知服务（跨平台）
/// 
/// 封装 Android/iOS 通知功能，提供初始化、调度、取消等接口
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 初始化通知服务
  /// 
  /// 必须在应用启动时调用一次
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // 初始化时区数据
    tz.initializeTimeZones();

    // Android 通知渠道配置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 通知配置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 初始化设置
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 初始化通知插件
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 创建 Android 通知渠道
    await _createAndroidNotificationChannel();

    _initialized = true;
  }

  /// 创建 Android 通知渠道
  Future<void> _createAndroidNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'grano_timer', // 渠道 ID
      'GranoFlow Timer', // 渠道名称
      description: '计时进行中',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// 请求通知权限
  /// 
  /// Android 13+ 和 iOS 需要用户授权
  Future<bool> requestPermission() async {
    // Android 13+ 权限请求
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      if (granted == true) {
        return true;
      }
    }

    // iOS 权限请求（在初始化时已请求，这里检查状态）
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      final settings = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings ?? false;
    }

    return false;
  }

  /// 调度本地通知（iOS 到点提醒）
  /// 
  /// [id] 通知 ID
  /// [title] 通知标题
  /// [body] 通知内容
  /// [scheduledDate] 调度时间
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'grano_timer',
          'GranoFlow Timer',
          channelDescription: '计时进行中',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  /// 取消通知
  /// 
  /// [id] 通知 ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// 通知点击回调
  void _onNotificationTapped(NotificationResponse response) {
    // 通知点击后的处理逻辑
    // 可以通过路由跳转到计时页面
    // 这里暂时只记录，具体跳转逻辑在应用层处理
  }
}

