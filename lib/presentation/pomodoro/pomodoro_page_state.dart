import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/pomodoro_providers.dart';

/// 番茄时钟页面状态管理
/// 
/// 管理页面的UI状态，包括倒计时时长调整器的展开/收起状态
class PomodoroPageStateNotifier extends StateNotifier<PomodoroPageState> {
  PomodoroPageStateNotifier({
    required PomodoroTimerNotifier timerNotifier,
  }) : _timerNotifier = timerNotifier,
       super(PomodoroPageState(
         isCountdownAdjusterExpanded: false,
       ));

  final PomodoroTimerNotifier _timerNotifier;

  /// 切换倒计时时长调整器的展开/收起状态
  void toggleCountdownAdjuster() {
    state = state.copyWith(
      isCountdownAdjusterExpanded: !state.isCountdownAdjusterExpanded,
    );
  }

  /// 设置倒计时时长
  void setCountdownDuration(int seconds) {
    _timerNotifier.setCountdownDuration(seconds);
  }
}

/// 番茄时钟页面状态
class PomodoroPageState {
  const PomodoroPageState({
    required this.isCountdownAdjusterExpanded,
  });

  /// 倒计时时长调整器是否展开
  final bool isCountdownAdjusterExpanded;

  PomodoroPageState copyWith({
    bool? isCountdownAdjusterExpanded,
  }) {
    return PomodoroPageState(
      isCountdownAdjusterExpanded: isCountdownAdjusterExpanded ?? this.isCountdownAdjusterExpanded,
    );
  }
}

/// 页面状态 Provider
final pomodoroPageStateProvider = StateNotifierProvider<PomodoroPageStateNotifier, PomodoroPageState>((ref) {
  return PomodoroPageStateNotifier(
    timerNotifier: ref.read(pomodoroTimerProvider.notifier),
  );
});

