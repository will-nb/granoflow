import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:granoflow/data/models/focus_session.dart';
import 'package:granoflow/data/models/preference.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/models/task_template.dart';
import 'package:granoflow/data/repositories/focus_session_repository.dart';
import 'package:granoflow/data/repositories/preference_repository.dart';
import 'package:granoflow/data/repositories/seed_repository.dart';
import 'package:granoflow/data/repositories/tag_repository.dart';
import 'package:granoflow/data/repositories/task_repository.dart';
import 'package:granoflow/data/repositories/task_template_repository.dart';

class StubTaskRepository implements TaskRepository {
  final Map<int, Task> _tasks = <int, Task>{};
  int _nextId = 1;
  final Random _random = Random();

  @override
  Stream<List<Task>> watchSection(TaskSection section) =>
      Stream<List<Task>>.value(_filterSection(section));

  @override
  Stream<TaskTreeNode> watchTaskTree(int rootTaskId) =>
      Stream.value(_buildTree(rootTaskId));

  @override
  Stream<List<Task>> watchInbox() => Stream.value(
    _tasks.values
        .where((task) => task.status == TaskStatus.inbox)
        .toList(growable: false),
  );

  @override
  Stream<List<Task>> watchInboxFiltered({
    String? contextTag,
    String? priorityTag,
  }) {
    final filtered = _tasks.values.where((task) {
      if (task.status != TaskStatus.inbox) {
        return false;
      }
      if (contextTag != null && contextTag.isNotEmpty) {
        if (!task.tags.contains(contextTag)) {
          return false;
        }
      }
      if (priorityTag != null && priorityTag.isNotEmpty) {
        if (!task.tags.contains(priorityTag)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
    return Stream.value(filtered);
  }

  @override
  Future<Task> createTask(TaskDraft draft) async {
    final now = DateTime.now();
    final task = Task(
      id: _nextId++,
      taskId: _generateTaskId(now),
      title: draft.title,
      status: draft.status,
      dueAt: draft.dueAt,
      startedAt: null,
      endedAt: null,
      createdAt: now,
      updatedAt: now,
      parentId: draft.parentId,
      sortIndex: draft.sortIndex,
      tags: List.unmodifiable(draft.tags),
      templateLockCount: 0,
      seedSlug: draft.seedSlug,
      allowInstantComplete: draft.allowInstantComplete,
    );
    _tasks[task.id] = task;
    return task;
  }

  @override
  Future<void> updateTask(int taskId, TaskUpdate payload) async {
    final existing = _tasks[taskId];
    if (existing == null) return;
    final updated = existing.copyWith(
      title: payload.title,
      status: payload.status,
      dueAt: payload.dueAt,
      startedAt: payload.startedAt,
      endedAt: payload.endedAt,
      parentId: payload.parentId ?? existing.parentId,
      sortIndex: payload.sortIndex ?? existing.sortIndex,
      tags: payload.tags ?? existing.tags,
      templateLockCount: existing.templateLockCount + payload.templateLockDelta,
      allowInstantComplete:
          payload.allowInstantComplete ?? existing.allowInstantComplete,
      updatedAt: DateTime.now(),
    );
    _tasks[taskId] = updated;
  }

  @override
  Future<void> moveTask({
    required int taskId,
    required int? targetParentId,
    required TaskSection targetSection,
    required double sortIndex,
    DateTime? dueAt,
  }) async {
    final status = _sectionToStatus(targetSection);
    await updateTask(
      taskId,
      TaskUpdate(
        parentId: targetParentId,
        status: status,
        sortIndex: sortIndex,
        dueAt: dueAt,
      ),
    );
  }

  @override
  Future<void> markStatus({
    required int taskId,
    required TaskStatus status,
  }) async {
    await updateTask(taskId, TaskUpdate(status: status));
  }

  @override
  Future<void> archiveTask(int taskId) =>
      markStatus(taskId: taskId, status: TaskStatus.archived);

  @override
  Future<void> softDelete(int taskId) async {
    final task = _tasks[taskId];
    if (task == null || task.templateLockCount > 0) return;
    await updateTask(taskId, const TaskUpdate(status: TaskStatus.trashed));
  }

  @override
  Future<int> purgeObsolete(DateTime olderThan) async {
    final idsToRemove = _tasks.values
        .where(
          (task) =>
              task.status == TaskStatus.pseudoDeleted &&
              task.updatedAt.isBefore(olderThan),
        )
        .map((task) => task.id)
        .toList();
    for (final id in idsToRemove) {
      _tasks.remove(id);
    }
    return idsToRemove.length;
  }

  @override
  Future<void> adjustTemplateLock({
    required int taskId,
    required int delta,
  }) async {
    final task = _tasks[taskId];
    if (task == null) return;
    await updateTask(taskId, TaskUpdate(templateLockDelta: delta));
  }

  @override
  Future<Task?> findById(int id) async => _tasks[id];

  @override
  Future<Task?> findBySlug(String slug) async =>
      _tasks.values.firstWhereOrNull((task) => task.seedSlug == slug);

  @override
  Future<List<Task>> listRoots() async => _tasks.values
      .where((task) => task.parentId == null)
      .sortedBy((task) => task.sortIndex)
      .toList(growable: false);

  @override
  Future<List<Task>> listChildren(int parentId) async => _tasks.values
      .where((task) => task.parentId == parentId)
      .sortedBy((task) => task.sortIndex)
      .toList(growable: false);

  @override
  Future<void> upsertTasks(List<Task> tasks) async {
    for (final task in tasks) {
      _tasks[task.id] = task;
    }
  }

  @override
  Future<List<Task>> listAll() async => _tasks.values.toList(growable: false);

  @override
  Future<List<Task>> searchByTitle(
    String query, {
    TaskStatus? status,
    int limit = 20,
  }) async {
    final lower = query.toLowerCase();
    final results = _tasks.values.where((task) {
      if (status != null && task.status != status) {
        return false;
      }
      return task.title.toLowerCase().contains(lower);
    }).take(limit).toList(growable: false);
    return results;
  }

  List<Task> _filterSection(TaskSection section) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final laterStart = todayStart.add(const Duration(days: 2));

    return _tasks.values
        .where((task) {
          switch (section) {
            case TaskSection.today:
              return task.status == TaskStatus.pending &&
                  task.dueAt != null &&
                  !task.dueAt!.isAfter(tomorrowStart) &&
                  !task.dueAt!.isBefore(todayStart);
            case TaskSection.tomorrow:
              final dayAfter = tomorrowStart.add(const Duration(days: 1));
              return task.status == TaskStatus.pending &&
                  task.dueAt != null &&
                  !task.dueAt!.isBefore(tomorrowStart) &&
                  task.dueAt!.isBefore(dayAfter);
            case TaskSection.later:
              return task.status == TaskStatus.pending &&
                  task.dueAt != null &&
                  task.dueAt!.isAfter(laterStart);
            case TaskSection.completed:
              return task.status == TaskStatus.completedActive;
            case TaskSection.archived:
              return task.status == TaskStatus.archived;
            case TaskSection.trash:
              return task.status == TaskStatus.trashed;
          }
        })
        .sortedBy((task) => task.sortIndex)
        .toList(growable: false);
  }

  TaskTreeNode _buildTree(int rootTaskId) {
    final task = _tasks[rootTaskId];
    if (task == null) {
      return TaskTreeNode(
        task: Task(
          id: rootTaskId,
          taskId: '',
          title: '',
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
    final children = _tasks.values
        .where((candidate) => candidate.parentId == task.id)
        .sortedBy((child) => child.sortIndex)
        .map((child) => _buildTree(child.id))
        .toList(growable: false);
    return TaskTreeNode(task: task, children: children);
  }

  TaskStatus _sectionToStatus(TaskSection section) {
    switch (section) {
      case TaskSection.today:
      case TaskSection.tomorrow:
      case TaskSection.later:
        return TaskStatus.pending;
      case TaskSection.completed:
        return TaskStatus.completedActive;
      case TaskSection.archived:
        return TaskStatus.archived;
      case TaskSection.trash:
        return TaskStatus.trashed;
    }
  }

  String _generateTaskId(DateTime now) {
    final base =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix = _random.nextInt(9000) + 1000;
    return '$base-$suffix';
  }
}

class StubFocusSessionRepository implements FocusSessionRepository {
  final Map<int, FocusSession> _sessions = <int, FocusSession>{};
  int _nextId = 1;

  @override
  Future<FocusSession> startSession({
    required int taskId,
    int? estimateMinutes,
    bool alarmEnabled = false,
  }) async {
    final session = FocusSession(
      id: _nextId++,
      taskId: taskId,
      startedAt: DateTime.now(),
      estimateMinutes: estimateMinutes,
      alarmEnabled: alarmEnabled,
    );
    _sessions[session.id] = session;
    return session;
  }

  @override
  Future<void> endSession({
    required int sessionId,
    required int actualMinutes,
    int? transferToTaskId,
    String? reflectionNote,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) return;
    _sessions[sessionId] = session.copyWith(
      endedAt: DateTime.now(),
      actualMinutes: actualMinutes,
      reflectionNote: reflectionNote,
    );
  }

  @override
  Stream<FocusSession?> watchActiveSession(int taskId) =>
      Stream<FocusSession?>.value(null);

  @override
  Future<List<FocusSession>> listRecentSessions({
    required int taskId,
    int limit = 10,
  }) async {
    return _sessions.values
        .where((session) => session.taskId == taskId)
        .sortedBy((session) => session.startedAt)
        .reversed
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<int> totalMinutesForTask(int taskId) async => _sessions.values
      .where((session) => session.taskId == taskId)
      .fold<int>(0, (sum, session) => sum + session.actualMinutes);

  @override
  Future<int> totalMinutesOverall() async => _sessions.values.fold<int>(
    0,
    (sum, session) => sum + session.actualMinutes,
  );

  @override
  Future<FocusSession?> findById(int sessionId) async => _sessions[sessionId];
}

class StubTagRepository implements TagRepository {
  final Map<String, Tag> _tags = <String, Tag>{};

  @override
  Future<void> ensureSeeded(List<Tag> tags) async {
    for (final tag in tags) {
      _tags[tag.slug] = tag;
    }
  }

  @override
  Future<List<Tag>> listByKind(TagKind kind) async =>
      _tags.values.where((tag) => tag.kind == kind).toList(growable: false);

  @override
  Future<Tag?> findBySlug(String slug) async => _tags[slug];
}

class StubPreferenceRepository implements PreferenceRepository {
  final _controller = StreamController<Preference>.broadcast();
  Preference _preference = Preference(
    id: 1,
    localeCode: 'en',
    themeMode: ThemeMode.system,
    fontScale: 1.0,
    updatedAt: DateTime.now(),
  );

  @override
  Stream<Preference> watch() => _controller.stream.startWith(_preference);

  @override
  Future<Preference> load() async => _preference;

  @override
  Future<void> update(PreferenceUpdate payload) async {
    _preference = _preference.copyWith(
      localeCode: payload.localeCode,
      themeMode: payload.themeMode,
      fontScale: payload.fontScale,
      updatedAt: DateTime.now(),
    );
    _controller.add(_preference);
  }
}

class StubTaskTemplateRepository implements TaskTemplateRepository {
  final Map<int, TaskTemplate> _templates = <int, TaskTemplate>{};
  int _nextId = 1;

  @override
  Future<TaskTemplate> createTemplate(TaskTemplateDraft draft) async {
    return _insertTemplate(draft, draft.parentTaskId);
  }

  @override
  Future<TaskTemplate> createTemplateWithSeed({
    required TaskTemplateDraft draft,
    required int? parentId,
  }) async {
    return _insertTemplate(draft, parentId);
  }

  @override
  Future<void> deleteTemplate(int templateId) async {
    _templates.remove(templateId);
  }

  @override
  Future<TaskTemplate?> findById(int id) async => _templates[id];

  @override
  Future<TaskTemplate?> findBySlug(String slug) async => _templates.values
      .firstWhereOrNull((template) => template.seedSlug == slug);

  @override
  Future<void> markUsed(int templateId, DateTime usedAt) async {
    final template = _templates[templateId];
    if (template == null) return;
    _templates[templateId] = template.copyWith(
      lastUsedAt: usedAt,
      updatedAt: usedAt,
    );
  }

  @override
  Future<List<TaskTemplate>> listRecent({int limit = 6}) async => _templates
      .values
      .sortedBy((template) => template.lastUsedAt ?? template.updatedAt)
      .reversed
      .take(limit)
      .toList(growable: false);

  @override
  Future<List<TaskTemplate>> search({
    required String query,
    int limit = 10,
  }) async {
    final lower = query.toLowerCase();
    return _templates.values
        .where((template) => template.title.toLowerCase().contains(lower))
        .sortedBy((template) => template.lastUsedAt ?? template.updatedAt)
        .reversed
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<void> updateTemplate({
    required int templateId,
    required TaskTemplateUpdate payload,
  }) async {
    final template = _templates[templateId];
    if (template == null) return;
    _templates[templateId] = template.copyWith(
      title: payload.title ?? template.title,
      parentTaskId: payload.parentTaskId ?? template.parentTaskId,
      defaultTags: payload.defaultTags ?? template.defaultTags,
      suggestedEstimateMinutes:
          payload.suggestedEstimateMinutes ?? template.suggestedEstimateMinutes,
      updatedAt: DateTime.now(),
    );
  }

  TaskTemplate _insertTemplate(TaskTemplateDraft draft, int? parentId) {
    final now = DateTime.now();
    final template = TaskTemplate(
      id: _nextId++,
      title: draft.title,
      parentTaskId: parentId,
      defaultTags: List.unmodifiable(draft.defaultTags),
      createdAt: now,
      updatedAt: now,
      lastUsedAt: null,
      seedSlug: draft.seedSlug,
      suggestedEstimateMinutes: draft.suggestedEstimateMinutes,
    );
    _templates[template.id] = template;
    return template;
  }
}

class StubSeedRepository implements SeedRepository {
  String? _version;

  @override
  Future<bool> wasImported(String version) async => _version == version;

  @override
  Future<void> importSeeds(SeedPayload payload) async {
    // no-op for stubs
  }

  @override
  Future<String?> latestVersion() async => _version;

  @override
  Future<void> recordVersion(String version) async {
    _version = version;
  }
}

extension<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
