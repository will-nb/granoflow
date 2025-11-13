import 'dart:async';

import 'pinned_task_background_service.dart';
import 'notification_service.dart';
import '../../presentation/clock/utils/clock_timer_utils.dart';

/// iOS 本地通知服务封装
/// 
/// 使用 NotificationService 实现 iOS 本地通知显示
/// 注意：iOS 本地通知不支持按钮，只能显示信息
/// 每分钟更新通知内容
class IOSNotificationPinnedTaskService implements PinnedTaskBackgroundService {
  IOSNotificationPinnedTaskService({
    required NotificationService notificationService,
  }) : _notificationService = notificationService;

  final NotificationService _notificationService;
  bool _isRunning = false;
  Timer? _updateTimer;
  String? _currentTaskId;
  String? _currentTaskTitle;
  DateTime? _startTime;
  static const int _notificationId = 2001; // 固定 ID，用于置顶任务通知

  @override
  Future<void> startNotification({
    required String taskId,
    required String taskTitle,
  }) async {
    if (_isRunning && _currentTaskId == taskId) {
      return;
    }

    // 如果已有其他任务在运行，先停止
    if (_isRunning) {
      await stopNotification();
    }

    _currentTaskId = taskId;
    _currentTaskTitle = taskTitle;
    _startTime = DateTime.now();

    // 显示初始通知
    await _updateNotification();

    // 启动定时器，每分钟更新一次
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateNotification();
    });

    _isRunning = true;
  }

  @override
  Future<void> updateNotification({
    required String taskId,
    required String taskTitle,
    required Duration elapsed,
  }) async {
    if (!_isRunning || _currentTaskId != taskId) {
      return;
    }

    _currentTaskTitle = taskTitle;
    await _updateNotification();
  }

  /// 更新通知内容
  Future<void> _updateNotification() async {
    if (!_isRunning || _startTime == null) {
      return;
    }

    // 计算已用时间
    final elapsed = DateTime.now().difference(_startTime!);
    final timeText = ClockTimerUtils.formatElapsedTimeCompact(elapsed);

    // 显示通知（iOS 不支持持续通知，所以每次都是新通知）
    // 注意：iOS 本地通知不支持按钮
    await _notificationService.showNotification(
      id: _notificationId,
      title: _currentTaskTitle?.isEmpty ?? true ? '置顶任务' : _currentTaskTitle!,
      body: timeText,
      channelId: 'grano_pinned_task',
      channelName: 'GranoFlow Pinned Task',
    );
  }

  @override
  Future<void> stopNotification() async {
    if (!_isRunning) {
      return;
    }

    // 取消定时器
    _updateTimer?.cancel();
    _updateTimer = null;

    // 取消通知
    await _notificationService.cancelNotification(_notificationId);

    _isRunning = false;
    _currentTaskId = null;
    _currentTaskTitle = null;
    _startTime = null;
  }

  @override
  Future<bool> isRunning() async {
    return _isRunning;
  }

  @override
  Future<void> dispose() async {
    await stopNotification();
  }
}

