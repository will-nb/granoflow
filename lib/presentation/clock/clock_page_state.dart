import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_providers.dart';

/// 计时器页面状态管理
/// 
/// 管理页面的UI状态，包括倒计时时长调整器的展开/收起状态
class ClockPageStateNotifier extends StateNotifier<ClockPageState> {
  ClockPageStateNotifier({
    required ClockTimerNotifier timerNotifier,
  }) : _timerNotifier = timerNotifier,
       super(ClockPageState(
         isCountdownAdjusterExpanded: false,
       ));

  final ClockTimerNotifier _timerNotifier;

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

/// 计时器页面状态
class ClockPageState {
  const ClockPageState({
    required this.isCountdownAdjusterExpanded,
  });

  /// 倒计时时长调整器是否展开
  final bool isCountdownAdjusterExpanded;

  ClockPageState copyWith({
    bool? isCountdownAdjusterExpanded,
  }) {
    return ClockPageState(
      isCountdownAdjusterExpanded: isCountdownAdjusterExpanded ?? this.isCountdownAdjusterExpanded,
    );
  }
}

/// 页面状态 Provider
final clockPageStateProvider = StateNotifierProvider<ClockPageStateNotifier, ClockPageState>((ref) {
  return ClockPageStateNotifier(
    timerNotifier: ref.read(clockTimerProvider.notifier),
  );
});

