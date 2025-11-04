import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../monetization/monetization_service.dart';
import '../monetization/monetization_state.dart';
import 'service_providers.dart';

final monetizationStateProvider = StreamProvider<MonetizationState>((ref) {
  return ref.watch(monetizationServiceProvider).watch();
});

class MonetizationActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  MonetizationService get _service => ref.read(monetizationServiceProvider);

  Future<void> startTrial({Duration duration = const Duration(days: 7)}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _service.startTrial(duration: duration);
    });
  }

  Future<void> activateSubscription() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _service.activateSubscription();
    });
  }

  Future<void> cancelSubscription() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _service.cancelSubscription();
    });
  }

  void registerPremiumHit() {
    _service.registerPremiumHit();
  }
}

final monetizationActionsNotifierProvider =
    AsyncNotifierProvider<MonetizationActionsNotifier, void>(() {
      return MonetizationActionsNotifier();
    });

