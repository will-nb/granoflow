import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/services.dart';

import 'package:granoflow/core/constants/font_scale_level.dart';
import 'package:granoflow/core/providers/pomodoro_audio_preference_provider.dart';
import 'package:granoflow/core/providers/pomodoro_providers.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/focus_flow_service.dart';
import 'package:granoflow/core/services/metric_orchestrator.dart';
import 'package:granoflow/core/services/pomodoro_audio_service.dart';
import 'package:granoflow/core/services/preference_service.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/focus_session.dart';
import 'package:granoflow/data/models/preference.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/models/metric_snapshot.dart';
import 'package:granoflow/data/repositories/focus_session_repository.dart';
import 'package:granoflow/data/repositories/task_repository.dart';
import 'package:granoflow/data/repositories/tag_repository.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/pomodoro/pomodoro_page.dart';
import 'package:granoflow/presentation/pomodoro/widgets/pomodoro_control_strip.dart';
import 'package:granoflow/presentation/pomodoro/widgets/pomodoro_subtask_section.dart';

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
  Future<void> updatePomodoroTickSoundEnabled(bool enabled) async {
    _preference = _preference.copyWith(
      pomodoroTickSoundEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    _controller.add(_preference);
  }
}

class _StubTaskService extends TaskService {
  _StubTaskService()
    : super(
        taskRepository: _EmptyTaskRepository(),
        tagRepository: _EmptyTagRepository(),
        metricOrchestrator: _DummyMetricOrchestrator(),
      );

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

  @override
  Future<Task> captureInboxTask({
    required String title,
    List<String> tags = const <String>[],
  }) async {
    return _buildTask(id: 999, title: title, parentId: null);
  }
}

class _EmptyTaskRepository extends Fake implements TaskRepository {}

class _EmptyTagRepository extends Fake implements TagRepository {}

class _DummyMetricOrchestrator extends Fake implements MetricOrchestrator {
  @override
  Future<MetricSnapshot> requestRecompute(MetricRecomputeReason reason) async {
    return MetricSnapshot(
      id: 0,
      totalCompletedTasks: 0,
      totalFocusMinutes: 0,
      pendingTasks: 0,
      pendingTodayTasks: 0,
      calculatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class _FakePomodoroAudioService implements PomodoroAudioService {
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
    return _buildTask(id: 1000, title: title, parentId: parentTaskId);
  }

  @override
  Stream<FocusSession?> watchActive(int taskId) => const Stream.empty();
}

class _FakeFocusSessionRepository extends Fake
    implements FocusSessionRepository {}

class _FakeTaskRepository extends Fake implements TaskRepository {
  _FakeTaskRepository(this._task, this._children);

  final Task _task;
  final List<Task> _children;

  @override
  Future<Task?> findById(int id) async {
    if (_task.id == id) {
      return _task;
    }
    return _children.firstWhere((task) => task.id == id, orElse: () => _task);
  }

  @override
  Future<List<Task>> listChildren(int parentId) async {
    if (parentId == _task.id) {
      return _children;
    }
    return const [];
  }

  @override
  Stream<Task?> watchTaskById(int id) {
    if (_task.id == id) {
      return Stream.value(_task);
    }
    return Stream.value(null);
  }
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
    tags: const [],
  );
}

PomodoroTimerState _timerState({required bool started, required bool paused}) {
  return PomodoroTimerState(
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

void main() {
  final binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final parentTask = _buildTask(id: 1, title: 'Top Level Task');
  final childTask = _buildTask(
    id: 2,
    title: 'Subtask A',
    parentId: parentTask.id,
  );
  final preference = Preference(
    id: 1,
    localeCode: 'en',
    themeMode: ThemeMode.light,
    fontScaleLevel: FontScaleLevel.medium,
    pomodoroTickSoundEnabled: true,
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    HardwareKeyboard.instance.addHandler(_suppressSyntheticCapsLock);
  });

  tearDownAll(() {
    HardwareKeyboard.instance.removeHandler(_suppressSyntheticCapsLock);
  });

  tearDown(() async {
    await binding.setSurfaceSize(null);
  });

  Future<void> pumpPage(WidgetTester tester, Size size) async {
    await binding.setSurfaceSize(size);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pomodoroTimerProvider.overrideWith((ref) {
            final notifier = PomodoroTimerNotifier(
              focusFlowService: _FakeFocusFlowService(),
              audioService: _FakePomodoroAudioService(),
              focusSessionRepository: _FakeFocusSessionRepository(),
            );
            notifier.state = _timerState(started: false, paused: false);
            return notifier;
          }),
          pomodoroTickSoundEnabledProvider.overrideWith(
            (ref) => Stream<bool>.value(true),
          ),
          preferenceServiceProvider.overrideWithValue(
            _FakePreferenceService(initial: preference),
          ),
          taskServiceProvider.overrideWithValue(_StubTaskService()),
          taskRepositoryProvider.overrideWithValue(
            _FakeTaskRepository(parentTask, [childTask]),
          ),
          pomodoroTaskProvider.overrideWithProvider(
            (taskId) => StreamProvider((ref) => Stream.value(parentTask)),
          ),
          pomodoroSubtaskListProvider.overrideWithProvider(
            (taskId) => StreamProvider((ref) => Stream.value([childTask])),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PomodoroPage(taskId: parentTask.id),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('竖屏默认可见添加子任务按钮', (tester) async {
    final phoneSize = await _loadWindowSize('phone');
    await pumpPage(tester, phoneSize);

    expect(find.byTooltip('Add Subtask'), findsOneWidget);
    expect(find.byType(PomodoroSubtaskSection), findsOneWidget);
  });

  testWidgets('横屏 800×600 使用左右分栏布局', (tester) async {
    final tabletSize = await _loadWindowSize('tablet');
    await pumpPage(tester, tabletSize);

    bool hasRowWithTwoFlex = false;
    for (final element in find.byType(Row).evaluate()) {
      final Row row = element.widget as Row;
      final flexChildren = row.children.whereType<Flexible>().toList();
      if (flexChildren.length >= 2) {
        hasRowWithTwoFlex = true;
        break;
      }
    }

    expect(hasRowWithTwoFlex, isTrue);
    expect(find.byType(PomodoroControlStrip), findsOneWidget);
  });
}

Future<Size> _loadWindowSize(String profile) async {
  final data = await rootBundle.loadString('assets/config/desktop_window.json');
  final Map<String, dynamic> json = jsonDecode(data) as Map<String, dynamic>;

  Map<String, dynamic>? _entryFor(String key) {
    if (json.containsKey(key)) {
      return json[key] as Map<String, dynamic>;
    }
    final macos = json['macos'] as Map<String, dynamic>?;
    if (macos != null && macos.containsKey(key)) {
      return macos[key] as Map<String, dynamic>;
    }
    return null;
  }

  final normalized = profile
      .replaceAll(RegExp(r'Portrait|Landscape'), '')
      .toLowerCase();
  final Map<String, dynamic> entry =
      _entryFor(profile) ??
      _entryFor(normalized) ??
      _entryFor('default') ??
      const {'width': 744, 'height': 1133};

  final double width = (entry['width'] as num).toDouble();
  final double height = (entry['height'] as num).toDouble();
  return Size(width, height);
}

bool _suppressSyntheticCapsLock(KeyEvent event) {
  if (!event.synthesized) {
    return false;
  }
  return event.physicalKey == PhysicalKeyboardKey.capsLock;
}
