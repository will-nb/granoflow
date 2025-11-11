import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/focus_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../data/models/focus_session.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';

/// 任务计时控件
/// 只在pending、doing和paused状态显示
/// 支持开始、暂停、继续计时
class TaskTimerWidget extends ConsumerStatefulWidget {
  const TaskTimerWidget({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  ConsumerState<TaskTimerWidget> createState() => _TaskTimerWidgetState();
}

class _TaskTimerWidgetState extends ConsumerState<TaskTimerWidget> {
  Timer? _timer;
  DateTime? _pauseStartTime;
  Duration _pausedDuration = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 格式化时间为 hh:mm:ss
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// 计算已过时间
  Duration _computeElapsed(FocusSession session) {
    final now = DateTime.now();
    final totalDuration = now.difference(session.startedAt);
    
    // 如果有暂停，减去暂停时间
    if (_pauseStartTime != null) {
      final pauseDuration = now.difference(_pauseStartTime!);
      return totalDuration - _pausedDuration - pauseDuration;
    }
    
    return totalDuration - _pausedDuration;
  }

  /// 开始计时
  Future<void> _handleStart() async {
    // 将任务状态改为doing（会自动控制背景音）
    final taskService = await ref.read(taskServiceProvider.future);
    await taskService.markInProgress(widget.task.id);
    
    // 创建focus session
    final focusNotifier = ref.read(focusActionsNotifierProvider.notifier);
    await focusNotifier.start(widget.task.id);
    
    // 启动定时器更新UI
    _startTimer();
  }

  /// 暂停计时
  Future<void> _handlePause() async {
    final sessionAsync = ref.read(focusSessionProvider(widget.task.id));
    await sessionAsync.whenData((session) async {
      if (session != null) {
        // 计算已用时间（排除暂停时间）
        final now = DateTime.now();
        final totalDuration = now.difference(session.startedAt);
        final finalPausedDuration = _pauseStartTime != null
            ? _pausedDuration + now.difference(_pauseStartTime!)
            : _pausedDuration;
        final actualDuration = totalDuration - finalPausedDuration;
        final actualMinutes = actualDuration.inMinutes.clamp(0, 24 * 60);
        
        // 保存已用时间到数据库
        final focusNotifier = ref.read(focusActionsNotifierProvider.notifier);
        await focusNotifier.updateActualMinutes(
          sessionId: session.id,
          actualMinutes: actualMinutes,
        );
        
        // 记录暂停开始时间
        _pauseStartTime = now;
        _pausedDuration = finalPausedDuration;
        
        // 将任务状态改为paused（会自动控制背景音）
        final taskService = await ref.read(taskServiceProvider.future);
        await taskService.markPaused(widget.task.id);
        
        // 停止定时器更新
        _timer?.cancel();
      }
    });
  }

  /// 继续计时
  Future<void> _handleResume() async {
    if (_pauseStartTime != null) {
      final pauseDuration = DateTime.now().difference(_pauseStartTime!);
      _pausedDuration += pauseDuration;
      _pauseStartTime = null;
    }
    
    // 将任务状态改回doing（会自动控制背景音）
    final taskService = await ref.read(taskServiceProvider.future);
    await taskService.markResumed(widget.task.id);
    
    // 重新启动定时器
    _startTimer();
  }

  /// 启动定时器
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final sessionAsync = ref.watch(focusSessionProvider(widget.task.id));
    final taskStatus = widget.task.status;
    
    return sessionAsync.when(
      data: (session) {
        // 如果没有活跃的session，显示开始按钮
        if (session == null || !session.isActive) {
          // 清理定时器
          _timer?.cancel();
          _pauseStartTime = null;
          _pausedDuration = Duration.zero;
          
          return InkWell(
            onTap: _handleStart,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 14,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.clockStart,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // 有活跃session，根据任务状态显示不同的UI
        final isPaused = taskStatus == TaskStatus.paused;
        Duration elapsed;
        
        if (isPaused) {
          // 暂停状态：使用保存的时间（从session.actualMinutes计算）
          elapsed = Duration(minutes: session.actualMinutes);
          // 确保定时器已停止
          _timer?.cancel();
        } else {
          // doing状态：实时计算时间
          elapsed = _computeElapsed(session);
          // 确保定时器在运行
          if (_timer == null || !_timer!.isActive) {
            _startTimer();
          }
        }
        
        final timeText = _formatDuration(elapsed);
        
        return InkWell(
          onTap: isPaused ? _handleResume : _handlePause,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 14,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  timeText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) {
        debugPrint('Failed to load focus session: $error');
        return const SizedBox.shrink();
      },
    );
  }
}
