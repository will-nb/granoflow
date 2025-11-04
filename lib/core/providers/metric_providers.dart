import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/metric_orchestrator.dart';
import 'service_providers.dart';

final metricSnapshotProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(metricOrchestratorProvider).latest();
});

class MetricRefreshNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  MetricOrchestrator get _orchestrator => ref.read(metricOrchestratorProvider);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _orchestrator.requestRecompute(MetricRecomputeReason.task),
    );
  }
}

final metricRefreshNotifierProvider =
    AsyncNotifierProvider<MetricRefreshNotifier, void>(() {
      return MetricRefreshNotifier();
    });

