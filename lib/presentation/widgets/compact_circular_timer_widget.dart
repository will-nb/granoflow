import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/focus_providers.dart';
import '../../data/models/focus_session.dart';
import '../../data/models/task.dart';
import '../clock/utils/clock_timer_utils.dart';
import '../clock/widgets/circular_progress_painter.dart';

/// 小型环形进度条计时器组件
/// 
/// 用于置顶栏显示时间，固定40px × 40px尺寸
/// 显示环形进度条（每60分钟一圈）和中心时间文本
/// 字体大小根据时间格式动态调整：MM:SS 使用 12sp，HH:MM:SS 使用 10sp
class CompactCircularTimerWidget extends ConsumerStatefulWidget {
  const CompactCircularTimerWidget({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  ConsumerState<CompactCircularTimerWidget> createState() =>
      _CompactCircularTimerWidgetState();
}

class _CompactCircularTimerWidgetState
    extends ConsumerState<CompactCircularTimerWidget> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 计算已用时间
  Duration _computeElapsed(FocusSession session) {
    final taskStatus = widget.task.status;
    
    if (taskStatus == TaskStatus.paused) {
      // 暂停状态：使用已保存的时间
      return Duration(minutes: session.actualMinutes);
    } else {
      // doing状态：实时计算（now - session.startedAt）
      final now = DateTime.now();
      return now.difference(session.startedAt);
    }
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
    final sessionAsync = ref.watch(focusSessionProvider(widget.task.id));

    return sessionAsync.when(
      data: (session) {
        // 如果没有活跃session，不显示
        if (session == null || !session.isActive) {
          _timer?.cancel();
          return const SizedBox.shrink();
        }

        // 计算已用时间
        final elapsed = _computeElapsed(session);
        final elapsedMinutes = elapsed.inMinutes;
        final hasHours = elapsed.inHours > 0; // 判断是否超过1小时

        // 如果任务状态为doing，启动定时器
        if (widget.task.status == TaskStatus.doing) {
          if (_timer == null || !_timer!.isActive) {
            _startTimer();
          }
        } else {
          // 暂停状态，停止定时器
          _timer?.cancel();
        }

        // 计算进度（每60分钟一圈）
        final progress = (elapsedMinutes % 60) / 60.0;

        // 格式化时间
        final timeText = ClockTimerUtils.formatElapsedTimeCompact(elapsed);

        // 根据是否超过1小时动态调整字体大小
        // 小于1小时（MM:SS，5个字符）：12sp
        // 超过1小时（HH:MM:SS，8个字符）：10sp
        final fontSize = hasHours ? 10.0 : 12.0;

        // 获取反色主题颜色
        final inverseSurface = theme.colorScheme.inverseSurface;
        final onInverseSurface = theme.colorScheme.onInverseSurface;

        return RepaintBoundary(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: progress,
                isOvertime: false,
                isWarning: false,
                strokeWidth: 2.5,
                errorColor: theme.colorScheme.error,
                customColor: onInverseSurface.withValues(alpha: 0.8),
              ),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: inverseSurface.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text(
                      timeText,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        color: onInverseSurface,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

