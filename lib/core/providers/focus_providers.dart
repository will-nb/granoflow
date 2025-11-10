import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/focus_session.dart';
import '../services/focus_flow_service.dart';
import 'service_providers.dart';

// FocusOutcome 定义在 focus_flow_service.dart 中
export '../services/focus_flow_service.dart' show FocusOutcome;

class FocusActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<FocusFlowService> get _focusFlowService async => await ref.read(focusFlowServiceProvider.future);

  Future<void> start(String taskId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await _focusFlowService;
      await service.startFocus(taskId: taskId);
    });
  }

  Future<void> end({
    required String sessionId,
    required FocusOutcome outcome,
    String? reflection,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await _focusFlowService;
      await service.endFocus(
        sessionId: sessionId,
        outcome: outcome,
        reflectionNote: reflection,
      );
    });
  }
}

final focusActionsNotifierProvider =
    AsyncNotifierProvider<FocusActionsNotifier, void>(() {
      return FocusActionsNotifier();
    });

final focusSessionProvider = StreamProvider.family<FocusSession?, String>((
  ref,
  taskId,
) async* {
  final service = await ref.read(focusFlowServiceProvider.future);
  yield* service.watchActive(taskId);
});

