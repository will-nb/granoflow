import 'dart:async';

import 'monetization_state.dart';

class MonetizationService {
  MonetizationService({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      _state = const MonetizationState.initial();

  final DateTime Function() _clock;
  MonetizationState _state;
  final StreamController<MonetizationState> _controller =
      StreamController<MonetizationState>.broadcast();

  MonetizationState get current => _state;

  Stream<MonetizationState> watch() async* {
    yield _state;
    yield* _controller.stream;
  }

  void startTrial({Duration duration = const Duration(days: 7)}) {
    final endsAt = _clock().add(duration);
    _updateState(
      _state.copyWith(
        isTrialActive: true,
        trialEndsAt: endsAt,
        sessionsRemaining: MonetizationState.defaultSessions,
      ),
    );
  }

  void activateSubscription() {
    _updateState(
      _state.copyWith(
        isSubscribed: true,
        isTrialActive: false,
        trialEndsAt: null,
      ),
    );
  }

  void cancelSubscription() {
    _updateState(
      _state.copyWith(isSubscribed: false),
    );
  }

  void registerPremiumHit() {
    final now = _clock();
    final trialActive =
        _state.isTrialActive && _state.trialEndsAt?.isAfter(now) == true;

    if (_state.isSubscribed || trialActive) {
      return;
    }

    final remaining = (_state.sessionsRemaining - 1).clamp(0, 99);
    _updateState(_state.copyWith(sessionsRemaining: remaining));
  }

  bool shouldShowPaywall() {
    final now = _clock();
    final trialActive =
        _state.isTrialActive && _state.trialEndsAt?.isAfter(now) == true;
    if (_state.isSubscribed || trialActive) {
      return false;
    }
    return _state.sessionsRemaining <= 0;
  }

  void dispose() {
    _controller.close();
  }

  void _updateState(MonetizationState next) {
    _state = next;
    if (!_controller.isClosed) {
      _controller.add(_state);
    }
  }
}
