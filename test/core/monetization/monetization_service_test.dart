import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/monetization/monetization_service.dart';
import 'package:granoflow/core/monetization/monetization_state.dart';

void main() {
  group('MonetizationService', () {
    test('starts trial with duration and resets sessions', () {
      final now = DateTime(2025, 10, 23, 10);
      var clock = now;
      final service = MonetizationService(clock: () => clock);

      service.startTrial(duration: const Duration(days: 3));

      final state = service.current;
      expect(state.isTrialActive, isTrue);
      expect(state.trialEndsAt, now.add(const Duration(days: 3)));
      expect(state.sessionsRemaining, MonetizationState.defaultSessions);
    });

    test('paywall triggers after trial expiry and session usage', () {
      final start = DateTime(2025, 10, 1);
      var clock = start;
      final service = MonetizationService(clock: () => clock);

      service.startTrial(duration: const Duration(days: 1));

      clock = clock.add(const Duration(days: 2));
      expect(service.shouldShowPaywall(), isFalse);

      service.registerPremiumHit();
      service.registerPremiumHit();
      service.registerPremiumHit();

      expect(service.current.sessionsRemaining, 0);
      expect(service.shouldShowPaywall(), isTrue);
    });

    test('subscription overrides paywall checks', () {
      final service = MonetizationService();

      service.startTrial(duration: const Duration(days: 1));
      service.activateSubscription();

      for (var i = 0; i < 10; i++) {
        service.registerPremiumHit();
      }

      expect(service.shouldShowPaywall(), isFalse);

      service.cancelSubscription();
      expect(service.shouldShowPaywall(), isFalse);

      service.registerPremiumHit();
      service.registerPremiumHit();
      service.registerPremiumHit();
      expect(service.shouldShowPaywall(), isTrue);
    });
  });
}
