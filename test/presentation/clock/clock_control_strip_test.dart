import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/constants/font_scale_level.dart';
import 'package:granoflow/core/providers/clock_audio_preference_provider.dart';
import 'package:granoflow/core/providers/clock_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/focus_flow_service.dart';
import 'package:granoflow/core/services/clock_audio_service.dart';
import 'package:granoflow/core/services/preference_service.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/focus_session.dart';
import 'package:granoflow/data/models/preference.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/focus_session_repository.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/clock/widgets/clock_control_strip.dart';

class _FakePreferenceService extends Fake implements PreferenceService {
  _FakePreferenceService({required Preference initial})
    : _preference = initial {
    _controller.add(_preference);
  }

  Preference _preference;
  final _controller = StreamController<Preference>.broadcast();

  @override
  Stream<Preference> watch() => _controller.stream;

  @override
  Future<void> updateClockTickSoundEnabled(bool enabled) async {
    _preference = _preference.copyWith(
      clockTickSoundEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    _controller.add(_preference);
  }
}

class _FakeTaskService extends Fake implements TaskService {
  @override
  Future<void> markCompleted({
    required int taskId,
    bool autoCompleteParent = true,
  }) async {}

  @override
  Future<void> updateDetails({
    required int taskId,
    required TaskUpdate payload,
  }) async {}
}

class _FakeFocusFlowService implements FocusFlowService {
  @override
  Future<FocusSession> startFocus({
    required int taskId,
    int? estimateMinutes,
    bool alarmEnabled = false,
  }) async {
    return FocusSession(id: 1, taskId: taskId, startedAt: DateTime.now());
  }

  @override
  Future<void> pauseFocus(int sessionId) async {}

  @override
  Future<void> endFocus({
    required int sessionId,
    required FocusOutcome outcome,
    int? transferToTaskId,
    String? reflectionNote,
  }) async {}

  @override
  Future<Task> quickSubtask({
    required int parentTaskId,
    required String title,
  }) async {
    return _buildTask(id: 999, title: title, parentId: parentTaskId);
  }

  @override
  Stream<FocusSession?> watchActive(int taskId) => const Stream.empty();
}

class _FakeClockAudioService implements ClockAudioService {
  @override
  void startTickSound() {}

  @override
  void stopTickSound() {}

  @override
  Future<void> play10MinuteWarning() async {}

  @override
  Future<void> play5MinuteWarning() async {}

  @override
  Future<void> playCompletionSound() async {}

  @override
  void resetAlertFlags() {}

  @override
  Future<void> dispose() async {}
}

class _FakeFocusSessionRepository extends Fake
    implements FocusSessionRepository {}

Preference _buildPreference({required bool sound}) {
  return Preference(
    id: 1,
    localeCode: 'en',
    themeMode: ThemeMode.light,
    fontScaleLevel: FontScaleLevel.medium,
    clockTickSoundEnabled: sound,
    updatedAt: DateTime.now(),
  );
}

Task _buildTask({required int id, required String title, int? parentId}) {
  return Task(
    id: id,
    taskId: 'task-$id',
    title: title,
    status: TaskStatus.pending,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    parentId: parentId,
  );
}

ClockTimerState _buildTimerState({
  required bool started,
  required bool paused,
}) {
  return ClockTimerState(
    isStarted: started,
    isPaused: paused,
    forwardElapsed: Duration.zero,
    countdownRemaining: const Duration(minutes: 25),
    startTime: started
        ? DateTime.now().subtract(const Duration(minutes: 3))
        : null,
    pausePeriods: const [],
    countdownDuration: 25 * 60,
    originalCountdownDuration: 25 * 60,
  );
}

Future<void> _pumpControlStrip(
  WidgetTester tester,
  ClockTimerState state,
) async {
  final preference = _buildPreference(sound: true);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockTimerProvider.overrideWith((ref) {
          final notifier = ClockTimerNotifier(
            focusFlowService: _FakeFocusFlowService(),
            audioService: _FakeClockAudioService(),
            focusSessionRepository: _FakeFocusSessionRepository(),
          );
          notifier.state = state;
          return notifier;
        }),
        clockTickSoundEnabledProvider.overrideWith(
          (ref) => Stream<bool>.value(preference.clockTickSoundEnabled),
        ),
        preferenceServiceProvider.overrideWithValue(
          _FakePreferenceService(initial: preference),
        ),
        taskServiceProvider.overrideWithValue(_FakeTaskService()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: ClockControlStrip(taskId: 1, onComplete: () {}),
          ),
        ),
      ),
    ),
  );

  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('未开始时显示 Start 按钮', (tester) async {
    await _pumpControlStrip(
      tester,
      _buildTimerState(started: false, paused: false),
    );

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Resume'), findsNothing);
  });

  testWidgets('暂停后显示 Resume 按钮', (tester) async {
    await _pumpControlStrip(
      tester,
      _buildTimerState(started: true, paused: true),
    );

    expect(find.text('Resume'), findsOneWidget);
  });
}
