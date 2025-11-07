import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/timer_background_service_stub.dart';

void main() {
  group('TimerBackgroundServiceStub', () {
    late TimerBackgroundServiceStub service;

    setUp(() {
      service = TimerBackgroundServiceStub();
    });

    test('startTimer does nothing', () async {
      await service.startTimer(
        endTime: DateTime.now().add(const Duration(minutes: 25)),
        duration: const Duration(minutes: 25),
      );
      // 不应该抛出异常
    });

    test('pauseTimer does nothing', () async {
      await service.pauseTimer();
      // 不应该抛出异常
    });

    test('resumeTimer does nothing', () async {
      await service.resumeTimer();
      // 不应该抛出异常
    });

    test('stopTimer does nothing', () async {
      await service.stopTimer();
      // 不应该抛出异常
    });

    test('isRunning always returns false', () async {
      final isRunning = await service.isRunning();
      expect(isRunning, isFalse);
    });

    test('dispose does nothing', () async {
      await service.dispose();
      // 不应该抛出异常
    });
  });
}

