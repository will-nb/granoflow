import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/pomodoro_providers.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../pomodoro_page_state.dart';

/// 倒计时时长调整器
///
/// 在开始计时前，允许用户调整倒计时时长（1-60分钟）
class CountdownDurationAdjuster extends ConsumerWidget {
  const CountdownDurationAdjuster({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final timerState = ref.watch(pomodoroTimerProvider);
    final pageState = ref.watch(pomodoroPageStateProvider);
    final pageNotifier = ref.read(pomodoroPageStateProvider.notifier);
    final timerNotifier = ref.read(pomodoroTimerProvider.notifier);

    // 如果已经开始计时，不显示调整器
    if (timerState.isStarted) {
      return const SizedBox.shrink();
    }

    final currentMinutes = timerState.countdownDuration ~/ 60;

    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和展开/收起按钮
            InkWell(
              onTap: () => pageNotifier.toggleCountdownAdjuster(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.pomodoroCountdownDuration(currentMinutes),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Icon(
                      pageState.isCountdownAdjusterExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),

            // 展开时显示调整器
            if (pageState.isCountdownAdjusterExpanded) ...[
              const SizedBox(height: 16),
              // 分钟选择器
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: currentMinutes > 15
                        ? () {
                            timerNotifier.setCountdownDuration(
                              (currentMinutes - 5) * 60,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.white,
                    iconSize: 32,
                  ),
                  const SizedBox(width: 24),
                  Text(
                    l10n.pomodoroMinutes(currentMinutes),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: currentMinutes < 60
                        ? () {
                            timerNotifier.setCountdownDuration(
                              (currentMinutes + 5) * 60,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.white,
                    iconSize: 32,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}


