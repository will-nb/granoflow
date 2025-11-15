import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// 统一通知服务（跨平台）
///
/// 封装 Android/iOS/macOS/Linux/Windows 通知功能，提供初始化、调度、取消等接口
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

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

    // macOS 通知配置（与 iOS 相同）
    const macosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Linux 通知配置
    const linuxSettings = LinuxInitializationSettings(defaultActionName: '打开通知');

    // Windows 通知配置
    const windowsSettings = WindowsInitializationSettings(
      appName: 'GranoFlow',
      appUserModelId: 'com.granoflow.lite',
      guid: 'FD65DAF3-13E5-4642-ADF3-EDB03A5CF7CF',
    );

    // 初始化设置
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macosSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    // 初始化通知插件
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 创建 Android 通知渠道
    await _createAndroidNotificationChannel();
    await _createPinnedTaskNotificationChannel();

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
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// 创建置顶任务通知渠道
  Future<void> _createPinnedTaskNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'grano_pinned_task', // 渠道 ID
      'GranoFlow Pinned Task', // 渠道名称
      description: '置顶任务进行中',
      importance: Importance.high,
      playSound: false, // 置顶任务通知不播放声音
      enableVibration: false, // 置顶任务通知不震动
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// 请求通知权限
  ///
  /// Android 13+ 和 iOS 需要用户授权
  /// Linux 使用系统通知服务器（D-Bus），通常不需要额外权限请求
  /// Windows 10+ 通常不需要额外权限请求
  /// 如果权限请求正在进行中，会捕获异常并返回 false
  Future<bool> requestPermission() async {
    try {
      // Android 13+ 权限请求
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        if (granted == true) {
          return true;
        }
      }

      // iOS 权限请求（在初始化时已请求，这里检查状态）
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final settings = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return settings ?? false;
      }

      // Linux 使用系统通知服务器（D-Bus），通常不需要额外权限请求
      // 如果系统通知服务器可用，则认为权限已授予
      final linuxImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<LinuxFlutterLocalNotificationsPlugin>();
      if (linuxImplementation != null) {
        // Linux 通知通常不需要权限请求，直接返回 true
        return true;
      }

      // Windows 10+ 通常不需要额外权限请求
      // 如果系统通知服务器可用，则认为权限已授予
      final windowsImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<FlutterLocalNotificationsWindows>();
      if (windowsImplementation != null) {
        // Windows 通知通常不需要权限请求，直接返回 true
        return true;
      }
    } catch (e) {
      // 如果权限请求正在进行中或其他错误，记录并返回 false
      // 这在集成测试中很常见，因为多个测试可能同时请求权限
      print('Notification permission request failed (may be in progress): $e');
      return false;
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
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        linux: const LinuxNotificationDetails(),
        windows: const WindowsNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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

  /// 立即显示通知
  ///
  /// [id] 通知 ID
  /// [title] 通知标题
  /// [body] 通知内容
  /// [channelId] 通知渠道 ID（Android）
  /// [channelName] 通知渠道名称（Android）
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? channelName,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // 如果指定了渠道，确保渠道已创建
    // 注意：渠道在初始化时已经创建，这里直接创建即可（如果已存在会被忽略）
    if (channelId != null && channelName != null) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        // 直接创建渠道（如果已存在会被忽略）
        const androidChannel = AndroidNotificationChannel(
          'grano_pinned_task',
          'GranoFlow Pinned Task',
          description: '置顶任务进行中',
          importance: Importance.high,
          playSound: false,
          enableVibration: false,
        );
        await androidImplementation.createNotificationChannel(androidChannel);
      }
    }

    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId ?? 'grano_timer',
          channelName ?? 'GranoFlow Timer',
          channelDescription: '通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          ongoing: channelId == 'grano_pinned_task', // 置顶任务通知设置为持续通知
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false, // 置顶任务通知不播放声音
        ),
        linux: const LinuxNotificationDetails(),
        windows: const WindowsNotificationDetails(),
      ),
    );
  }

  /// 通知点击回调
  void _onNotificationTapped(NotificationResponse response) {
    // 通知点击后的处理逻辑
    // 如果是置顶任务通知（ID 为 2001），导航到任务列表
    if (response.id == 2001) {
      // 通过全局路由导航到任务列表并滚动到置顶任务
      _handlePinnedTaskNotificationTap();
    }
  }

  /// 处理置顶任务通知点击
  void _handlePinnedTaskNotificationTap() {
    // 通过全局路由导航到任务列表并滚动到置顶任务
    // 注意：这里需要延迟导入以避免循环依赖
    // 使用动态导入或者通过回调函数传递路由
    // 暂时先注释，等待应用层处理
    // AppRouter.router.go('/tasks?scrollToPinned=true');
  }
}
