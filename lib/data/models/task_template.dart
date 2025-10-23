import 'package:flutter/foundation.dart';

@immutable
class TaskTemplate {
  const TaskTemplate({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.parentTaskId,
    this.defaultTags = const <String>[],
    this.lastUsedAt,
    this.seedSlug,
    this.suggestedEstimateMinutes,
  });

  final int id;
  final String title;
  final int? parentTaskId;
  final List<String> defaultTags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final String? seedSlug;
  final int? suggestedEstimateMinutes;

  TaskTemplate copyWith({
    int? id,
    String? title,
    int? parentTaskId,
    List<String>? defaultTags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    String? seedSlug,
    int? suggestedEstimateMinutes,
  }) {
    return TaskTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      defaultTags: defaultTags ?? this.defaultTags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      seedSlug: seedSlug ?? this.seedSlug,
      suggestedEstimateMinutes:
          suggestedEstimateMinutes ?? this.suggestedEstimateMinutes,
    );
  }
}

class TaskTemplateDraft {
  const TaskTemplateDraft({
    required this.title,
    this.parentTaskId,
    this.defaultTags = const <String>[],
    this.seedSlug,
    this.suggestedEstimateMinutes,
  });

  final String title;
  final int? parentTaskId;
  final List<String> defaultTags;
  final String? seedSlug;
  final int? suggestedEstimateMinutes;
}

class TaskTemplateUpdate {
  const TaskTemplateUpdate({
    this.title,
    this.parentTaskId,
    this.defaultTags,
    this.suggestedEstimateMinutes,
  });

  final String? title;
  final int? parentTaskId;
  final List<String>? defaultTags;
  final int? suggestedEstimateMinutes;
}

class TaskTemplateOverrides {
  const TaskTemplateOverrides({
    this.parentTaskId,
    this.tags,
    this.allowInstantComplete,
    this.dueAt,
  });

  final int? parentTaskId;
  final List<String>? tags;
  final bool? allowInstantComplete;
  final DateTime? dueAt;
}
