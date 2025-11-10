import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task_template.dart';
import '../services/task_template_service.dart';
import 'service_providers.dart';

// 导出 TaskTemplateDraft 以便外部使用
export '../../data/models/task_template.dart' show TaskTemplateDraft;

class TemplateSuggestionQuery {
  const TemplateSuggestionQuery({this.text, this.limit = 5});

  final String? text;
  final int limit;
}

final templateSuggestionsProvider =
    FutureProvider.family<List<TaskTemplate>, TemplateSuggestionQuery>((
      ref,
      query,
    ) async {
      try {
        final service = ref.watch(taskTemplateServiceProvider);
        if (query.text?.isNotEmpty == true) {
          return await service.search(query.text!, limit: query.limit);
        }
        return await service.listRecent(query.limit);
      } catch (error) {
        debugPrint('TemplateSuggestionsProvider error: $error');
        return <TaskTemplate>[]; // 返回空列表而不是抛出错误
      }
    });

class TemplateActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<TaskTemplateService> get _service async => await ref.read(taskTemplateServiceProvider.future);

  Future<void> create(TaskTemplateDraft draft) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await _service;
      return service.createTemplate(draft);
    });
  }

  Future<void> delete(String templateId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await _service;
      return service.deleteTemplate(templateId);
    });
  }
}

final templateActionsNotifierProvider =
    AsyncNotifierProvider<TemplateActionsNotifier, void>(() {
      return TemplateActionsNotifier();
    });

