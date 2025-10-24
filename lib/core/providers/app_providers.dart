import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/focus_session.dart';
import '../../data/models/tag.dart';
import '../../data/models/task.dart';
import '../../data/models/task_template.dart';
import '../services/focus_flow_service.dart';
import '../services/metric_orchestrator.dart';
import '../services/preference_service.dart';
import '../services/task_hierarchy_service.dart';
import '../services/task_service.dart';
import '../services/task_template_service.dart';
import '../monetization/monetization_service.dart';
import '../monetization/monetization_state.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

final appLocaleProvider = StreamProvider<Locale>((ref) {
  return ref
      .watch(preferenceServiceProvider)
      .watch()
      .map((pref) {
        final parts = pref.localeCode.split('_');
        if (parts.length == 2) {
          return Locale(parts[0], parts[1]);
        } else {
          return Locale(pref.localeCode);
        }
      });
});

final themeProvider = StreamProvider<ThemeMode>((ref) {
  return ref
      .watch(preferenceServiceProvider)
      .watch()
      .map((pref) => pref.themeMode);
});

final fontScaleProvider = StreamProvider<double>((ref) {
  return ref
      .watch(preferenceServiceProvider)
      .watch()
      .map((pref) => pref.fontScale);
});

final seedInitializerProvider = FutureProvider<void>((ref) async {
  ref.keepAlive();
  final service = ref.watch(seedImportServiceProvider);
  final locale = ref
      .watch(appLocaleProvider)
      .maybeWhen(data: (value) => value.languageCode, orElse: () => 'en');
  await service.importIfNeeded(locale);
});

final navigationIndexProvider = StateProvider<int>((ref) => 0);

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

final taskSectionsProvider = StreamProvider.family<List<Task>, TaskSection>((
  ref,
  section,
) {
  return ref.watch(taskRepositoryProvider).watchSection(section);
});

@immutable
class InboxFilterState {
  const InboxFilterState({this.contextTag, this.priorityTag});

  final String? contextTag;
  final String? priorityTag;

  bool get hasFilters =>
      (contextTag != null && contextTag!.isNotEmpty) ||
      (priorityTag != null && priorityTag!.isNotEmpty);

  InboxFilterState copyWith({
    String? contextTag,
    String? priorityTag,
  }) {
    return InboxFilterState(
      contextTag: contextTag ?? this.contextTag,
      priorityTag: priorityTag ?? this.priorityTag,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InboxFilterState &&
        other.contextTag == contextTag &&
        other.priorityTag == priorityTag;
  }

  @override
  int get hashCode => Object.hash(contextTag, priorityTag);
}

class InboxFilterNotifier extends StateNotifier<InboxFilterState> {
  InboxFilterNotifier() : super(const InboxFilterState());

  void setContextTag(String? tag) {
    final normalized = (tag != null && tag.isEmpty) ? null : tag;
    if (state.contextTag == normalized) {
      return;
    }
    state = InboxFilterState(
      contextTag: normalized,
      priorityTag: state.priorityTag,
    );
  }

  void setPriorityTag(String? tag) {
    final normalized = (tag != null && tag.isEmpty) ? null : tag;
    if (state.priorityTag == normalized) {
      return;
    }
    state = InboxFilterState(
      contextTag: state.contextTag,
      priorityTag: normalized,
    );
  }

  void reset() {
    state = const InboxFilterState();
  }
}

final inboxFilterProvider =
    StateNotifierProvider<InboxFilterNotifier, InboxFilterState>((ref) {
      return InboxFilterNotifier();
    });

final inboxTasksProvider = StreamProvider<List<Task>>((ref) {
  final filter = ref.watch(inboxFilterProvider);
  return ref.watch(taskRepositoryProvider).watchInboxFiltered(
        contextTag: filter.contextTag,
        priorityTag: filter.priorityTag,
      );
});

final rootTasksProvider = FutureProvider<List<Task>>((ref) async {
  return ref.watch(taskRepositoryProvider).listRoots();
});

final taskTreeProvider = StreamProvider.family<TaskTreeNode, int>((
  ref,
  rootId,
) {
  return ref.watch(taskRepositoryProvider).watchTaskTree(rootId);
});

final expandedRootTaskIdProvider = StateProvider<int?>((ref) => null);
final inboxExpandedTaskIdProvider = StateProvider<int?>((ref) => null);

class TaskEditActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  TaskService get _taskService => ref.read(taskServiceProvider);
  TaskHierarchyService get _hierarchyService =>
      ref.read(taskHierarchyServiceProvider);

  Future<void> addSubtask({
    required int parentId,
    required String title,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final subtask = await _taskService.captureInboxTask(title: title);
      await _hierarchyService.moveToParent(
        taskId: subtask.id,
        parentId: parentId,
        sortIndex: DateTime.now().millisecondsSinceEpoch.toDouble(),
      );
      await _taskService.updateDetails(
        taskId: subtask.id,
        payload: const TaskUpdate(status: TaskStatus.pending),
      );
    });
  }

  Future<void> editTitle({required int taskId, required String title}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _taskService.updateDetails(
        taskId: taskId,
        payload: TaskUpdate(title: title),
      );
    });
  }

  Future<void> archive(int taskId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _taskService.archive(taskId));
  }
}

final taskEditActionsNotifierProvider =
    AsyncNotifierProvider<TaskEditActionsNotifier, void>(() {
      return TaskEditActionsNotifier();
    });

class FocusActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  FocusFlowService get _focusFlowService => ref.read(focusFlowServiceProvider);

  Future<void> start(int taskId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _focusFlowService.startFocus(taskId: taskId);
    });
  }

  Future<void> end({
    required int sessionId,
    required FocusOutcome outcome,
    String? reflection,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _focusFlowService.endFocus(
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

final focusSessionProvider = StreamProvider.family<FocusSession?, int>((
  ref,
  taskId,
) {
  return ref.watch(focusFlowServiceProvider).watchActive(taskId);
});

final templateSuggestionsProvider =
    FutureProvider.family<List<TaskTemplate>, TemplateSuggestionQuery>((
      ref,
      query,
    ) {
      final service = ref.watch(taskTemplateServiceProvider);
      if (query.text?.isNotEmpty == true) {
        return service.search(query.text!, limit: query.limit);
      }
      return service.listRecent(query.limit);
    });

final contextTagOptionsProvider = FutureProvider<List<Tag>>((ref) {
  return ref.watch(taskServiceProvider).listTagsByKind(TagKind.context);
});

final priorityTagOptionsProvider = FutureProvider<List<Tag>>((ref) {
  return ref.watch(taskServiceProvider).listTagsByKind(TagKind.priority);
});

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

class TemplateSuggestionQuery {
  const TemplateSuggestionQuery({this.text, this.limit = 5});

  final String? text;
  final int limit;
}

class TemplateActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  TaskTemplateService get _service => ref.read(taskTemplateServiceProvider);

  Future<void> create(TaskTemplateDraft draft) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.createTemplate(draft));
  }

  Future<void> delete(int templateId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.deleteTemplate(templateId));
  }
}

final templateActionsNotifierProvider =
    AsyncNotifierProvider<TemplateActionsNotifier, void>(() {
      return TemplateActionsNotifier();
    });

class PreferenceActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  PreferenceService get _service => ref.read(preferenceServiceProvider);

  Future<void> updateLocale(String localeCode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.updateLocale(localeCode));
  }

  Future<void> updateTheme(ThemeMode mode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.updateTheme(mode));
  }

  Future<void> updateFontScale(double scale) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.updateFontScale(scale));
  }
}

final preferenceActionsNotifierProvider =
    AsyncNotifierProvider<PreferenceActionsNotifier, void>(() {
      return PreferenceActionsNotifier();
    });
