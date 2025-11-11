import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_audio_preference_provider.dart';
import '../../../core/providers/clock_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/focus_flow_service.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 计时器操作按钮组件
/// 
/// 包含开始、完成、暂停/继续、声音开关按钮
class ClockActionButtons extends ConsumerWidget {
  const ClockActionButtons({
    super.key,
    required this.taskId,
    required this.onComplete,
  });

  final String taskId;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final timerState = ref.watch(clockTimerProvider);
    final timerNotifier = ref.read(clockTimerProvider.notifier);
    
    // 音频设置
    final audioEnabledAsync = ref.watch(clockTickSoundEnabledProvider);
    final audioEnabled = audioEnabledAsync.value ?? true;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 开始前：显示开始按钮
        if (!timerState.isStarted)
          _buildCircularIconButton(
            icon: Icons.play_arrow_rounded,
            onPressed: () => timerNotifier.start(taskId),
            tooltip: l10n.clockStart,
          ),
        
        // 开始后：显示完成和暂停/继续按钮
        if (timerState.isStarted) ...[
          // 完成按钮
          _buildCircularIconButton(
            icon: Icons.check_circle_rounded,
            onPressed: () => _handleComplete(context, ref),
            tooltip: l10n.clockComplete,
          ),
          
          const SizedBox(width: 16),
          
          // 暂停/继续按钮
          _buildCircularIconButton(
            icon: timerState.isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            onPressed: timerState.isPaused
                ? () => timerNotifier.resume()
                : () => timerNotifier.pause(),
            tooltip: timerState.isPaused ? l10n.clockResume : l10n.clockPause,
          ),
        ],
        
        const SizedBox(width: 16),
        
        // 声音开关按钮（始终显示，保持现有样式）
        IconButton(
          onPressed: () {
            updateClockTickSoundEnabled(ref, !audioEnabled);
          },
          icon: Icon(
            audioEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: Colors.white,
            size: 28,
          ),
          tooltip: audioEnabled ? l10n.clockTurnOffSound : l10n.clockTurnOnSound,
        ),
      ],
    );
  }

  /// 构建圆形图标按钮
  /// 
  /// 64dp × 64dp 圆形按钮，白色半透明背景，白色边框
  Widget _buildCircularIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.white.withValues(alpha: 0.2),
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 2),
        ),
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 64,
            height: 64,
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleComplete(BuildContext context, WidgetRef ref) async {
    final timerState = ref.read(clockTimerProvider);
    
    // 如果计时器正在运行，先结束当前会话
    if (timerState.focusSessionId != null) {
      final focusFlowService = await ref.read(focusFlowServiceProvider.future);
      
      try {
        await focusFlowService.endFocus(
          sessionId: timerState.focusSessionId!,
          outcome: FocusOutcome.complete,
          transferToTaskId: null,
          reflectionNote: null,
        );
      } catch (e) {
        debugPrint('Failed to end focus session: $e');
      }
    }
    
    // 标记任务为已完成（通过 TaskService）
    final taskService = await ref.read(taskServiceProvider.future);
    try {
      await taskService.markCompleted(taskId: taskId);
    } catch (e) {
      debugPrint('Failed to mark task as completed: $e');
    }
    
    // 调用完成回调
    onComplete();
  }
}

