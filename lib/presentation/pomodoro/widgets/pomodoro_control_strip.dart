import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/pomodoro_audio_preference_provider.dart';
import '../../../core/providers/pomodoro_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/focus_flow_service.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 海浪主题操作按钮条
class PomodoroControlStrip extends ConsumerWidget {
  const PomodoroControlStrip({
    super.key,
    required this.taskId,
    required this.onComplete,
  });

  final int taskId;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final timerState = ref.watch(pomodoroTimerProvider);
    final timerNotifier = ref.read(pomodoroTimerProvider.notifier);
    final audioEnabledAsync = ref.watch(pomodoroTickSoundEnabledProvider);
    final audioEnabled = audioEnabledAsync.value ?? true;

    final buttons = <Widget>[];

    if (!timerState.isStarted) {
      buttons.add(
        _ControlButton(
          icon: Icons.play_arrow_rounded,
          label: l10n.pomodoroStart,
          tooltip: l10n.pomodoroStart,
          onPressed: () => timerNotifier.start(taskId),
          emphasis: ControlButtonEmphasis.primary,
        ),
      );
    } else {
      buttons.addAll([
        _ControlButton(
          icon: Icons.check_circle_rounded,
          label: l10n.pomodoroComplete,
          tooltip: l10n.pomodoroComplete,
          onPressed: () => _handleComplete(context, ref),
          emphasis: ControlButtonEmphasis.success,
        ),
        _ControlButton(
          icon: timerState.isPaused
              ? Icons.play_arrow_rounded
              : Icons.pause_rounded,
          label: timerState.isPaused ? l10n.pomodoroResume : l10n.pomodoroPause,
          tooltip: timerState.isPaused
              ? l10n.pomodoroResume
              : l10n.pomodoroPause,
          onPressed: timerState.isPaused
              ? () => timerNotifier.resume()
              : () => timerNotifier.pause(),
          emphasis: ControlButtonEmphasis.secondary,
        ),
      ]);
    }

    buttons.add(
      _ControlButton(
        icon: audioEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        label: audioEnabled
            ? l10n.pomodoroTurnOffSound
            : l10n.pomodoroTurnOnSound,
        tooltip: audioEnabled
            ? l10n.pomodoroTurnOffSound
            : l10n.pomodoroTurnOnSound,
        onPressed: () => updatePomodoroTickSoundEnabled(ref, !audioEnabled),
        emphasis: ControlButtonEmphasis.ghost,
        isToggleActive: audioEnabled,
      ),
    );

    final double width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 600;
    final double spacing = isTablet ? 18 : 14;
    final double runSpacing = isTablet ? 16 : 12;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing,
      runSpacing: runSpacing,
      children: buttons,
    );
  }

  Future<void> _handleComplete(BuildContext context, WidgetRef ref) async {
    final timerState = ref.read(pomodoroTimerProvider);

    if (timerState.focusSessionId != null) {
      final focusFlowService = ref.read(focusFlowServiceProvider);
      try {
        await focusFlowService.endFocus(
          sessionId: timerState.focusSessionId!,
          outcome: FocusOutcome.complete,
          transferToTaskId: null,
          reflectionNote: null,
        );
      } catch (error) {
        debugPrint('Failed to end focus session: $error');
      }
    }

    final taskService = ref.read(taskServiceProvider);
    try {
      await taskService.markCompleted(taskId: taskId);
    } catch (error) {
      debugPrint('Failed to mark task as completed: $error');
    }

    onComplete();
  }
}

enum ControlButtonEmphasis { primary, success, secondary, ghost }

class _ControlButton extends StatefulWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    required this.emphasis,
    this.isToggleActive = false,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final ControlButtonEmphasis emphasis;
  final bool isToggleActive;

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _hovering = false;
  bool _pressed = false;

  void _handleHover(bool hovering) {
    setState(() => _hovering = hovering);
  }

  void _handlePressed(bool pressed) {
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Color base = switch (widget.emphasis) {
      ControlButtonEmphasis.primary => colors.secondary,
      ControlButtonEmphasis.success => colors.tertiary,
      ControlButtonEmphasis.secondary => Colors.white.withValues(alpha: 0.12),
      ControlButtonEmphasis.ghost => Colors.white.withValues(alpha: 0.08),
    };

    final Color hoverOverlay = Colors.white.withValues(alpha: 0.18);
    final Color activeOverlay = Colors.white.withValues(alpha: 0.28);

    Color background = base;
    if (_pressed) {
      background = Color.alphaBlend(activeOverlay, base);
    } else if (_hovering) {
      background = Color.alphaBlend(hoverOverlay, base);
    } else if (widget.isToggleActive &&
        widget.emphasis == ControlButtonEmphasis.ghost) {
      background = Color.alphaBlend(hoverOverlay, base);
    }

    final BoxShadow shadow = BoxShadow(
      color: Colors.white.withValues(alpha: _hovering ? 0.25 : 0.12),
      blurRadius: _hovering ? 16 : 8,
      spreadRadius: _hovering ? 2 : 0,
    );

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTapDown: (_) => _handlePressed(true),
        onTapUp: (_) => _handlePressed(false),
        onTapCancel: () => _handlePressed(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed
              ? 0.96
              : _hovering
              ? 1.04
              : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [shadow],
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: widget.emphasis == ControlButtonEmphasis.secondary
                      ? 0.18
                      : 0.28,
                ),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Tooltip(
              message: widget.tooltip,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
