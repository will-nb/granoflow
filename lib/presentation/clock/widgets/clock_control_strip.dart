import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_audio_preference_provider.dart';
import '../../../core/providers/clock_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/focus_flow_service.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 海浪主题操作按钮条
class ClockControlStrip extends ConsumerWidget {
  const ClockControlStrip({
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
    final audioEnabledAsync = ref.watch(clockTickSoundEnabledProvider);
    final audioEnabled = audioEnabledAsync.value ?? true;

    final buttons = <Widget>[];

    if (!timerState.isStarted) {
      buttons.add(
        _ControlButton(
          icon: Icons.play_arrow_rounded,
          label: l10n.clockStart,
          tooltip: l10n.clockStart,
          onPressed: () => timerNotifier.start(taskId),
          emphasis: ControlButtonEmphasis.primary,
        ),
      );
    } else {
      buttons.addAll([
        _ControlButton(
          icon: Icons.check_circle_rounded,
          label: l10n.clockComplete,
          tooltip: l10n.clockComplete,
          onPressed: () => _handleComplete(context, ref),
          emphasis: ControlButtonEmphasis.success,
        ),
        _ControlButton(
          icon: timerState.isPaused
              ? Icons.play_arrow_rounded
              : Icons.pause_rounded,
          label: timerState.isPaused ? l10n.clockResume : l10n.clockPause,
          tooltip: timerState.isPaused
              ? l10n.clockResume
              : l10n.clockPause,
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
            ? l10n.clockTurnOffSound
            : l10n.clockTurnOnSound,
        tooltip: audioEnabled
            ? l10n.clockTurnOffSound
            : l10n.clockTurnOnSound,
        onPressed: () => updateClockTickSoundEnabled(ref, !audioEnabled),
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
    final timerState = ref.read(clockTimerProvider);

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

class _ControlButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Widget button = switch (emphasis) {
      ControlButtonEmphasis.primary => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 10),
              Text(label),
            ],
          ),
        ),
      ControlButtonEmphasis.success => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.tertiary,
            foregroundColor: colorScheme.onTertiary,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 10),
              Text(label),
            ],
          ),
        ),
      ControlButtonEmphasis.secondary => OutlinedButton(
          onPressed: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 10),
              Text(label),
            ],
          ),
        ),
      ControlButtonEmphasis.ghost => TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: isToggleActive
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 10),
              Text(label),
            ],
          ),
        ),
    };

    return Tooltip(
      message: tooltip,
      child: button,
    );
  }
}
