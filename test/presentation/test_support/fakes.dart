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
import 'package:granoflow/core/constants/font_scale_level.dart';

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
  @Deprecated('使用 ProjectRepository 和 ProjectService 替代')
  Stream<List<Task>> watchProjects() =>
      throw UnimplementedError('watchProjects 已废弃');

  @override
  Stream<List<Task>> watchQuickTasks() => Stream.value(
    _tasks.values
        .where(
          (task) =>
              task.projectId == null &&
              task.milestoneId == null &&
              task.parentId == null &&
              _isActiveProjectStatus(task.status),
        )
        .sorted((a, b) => _compareDueDates(a.dueAt, b.dueAt))
        .toList(growable: false),
  );

  @override
  @Deprecated('使用 MilestoneRepository 和 MilestoneService 替代')
  Stream<List<Task>> watchMilestones(int projectId) =>
      throw UnimplementedError('watchMilestones 已废弃');

  @override
  Stream<List<Task>> watchTasksByProjectId(String projectId) => Stream.value(
    _tasks.values
        .where((task) => task.projectId == projectId)
        .sorted((a, b) => _compareDueDates(a.dueAt, b.dueAt))
        .toList(growable: false),
  );

  @override
  Stream<List<Task>> watchTasksByMilestoneId(String milestoneId) =>
      Stream.value(
        _tasks.values
            .where((task) => task.milestoneId == milestoneId)
            .sorted((a, b) => _compareDueDates(a.dueAt, b.dueAt))
            .toList(growable: false),
      );

  @override
  Future<List<Task>> listTasksByMilestoneId(String milestoneId) async {
    return _tasks.values
        .where((task) => task.milestoneId == milestoneId)
        .sorted((a, b) => _compareDueDates(a.dueAt, b.dueAt))
        .toList(growable: false);
  }

  @override
  Stream<List<Task>> watchInboxFiltered({
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) {
    final filtered = _tasks.values
        .where((task) {
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
          if (urgencyTag != null && urgencyTag.isNotEmpty) {
            if (!task.tags.contains(urgencyTag)) {
              return false;
            }
          }
          if (importanceTag != null && importanceTag.isNotEmpty) {
            if (!task.tags.contains(importanceTag)) {
              return false;
            }
          }
          
          // TODO: 项目筛选（暂时忽略筛选参数）
          
          return true;
        })
        .toList(growable: false);
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
      parentTaskId: draft.parentTaskId,
      projectId: draft.projectId,
      milestoneId: draft.milestoneId,
      sortIndex: draft.sortIndex,
      tags: List.unmodifiable(draft.tags),
      templateLockCount: 0,
      seedSlug: draft.seedSlug,
      allowInstantComplete: draft.allowInstantComplete,
      description: draft.description,
      logs: List.unmodifiable(draft.logs),
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
      parentId: payload.clearParent == true
          ? null
          : payload.parentId ?? existing.parentId,
      parentTaskId: payload.clearParent == true
          ? null
          : payload.parentTaskId ?? existing.parentTaskId,
      projectId: payload.clearProject == true
          ? null
          : payload.projectId ?? existing.projectId,
      milestoneId: payload.clearMilestone == true
          ? null
          : payload.milestoneId ?? existing.milestoneId,
      sortIndex: payload.sortIndex ?? existing.sortIndex,
      tags: payload.tags ?? existing.tags,
      templateLockCount: existing.templateLockCount + payload.templateLockDelta,
      allowInstantComplete:
          payload.allowInstantComplete ?? existing.allowInstantComplete,
      description: payload.description ?? existing.description,
      logs: payload.logs ?? existing.logs,
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
  Stream<Task?> watchTaskById(int id) => Stream.value(_tasks[id]);

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
    final results = _tasks.values
        .where((task) {
          if (status != null && task.status != status) {
            return false;
          }
          return task.title.toLowerCase().contains(lower);
        })
        .take(limit)
        .toList(growable: false);
    return results;
  }

  @override
  Future<void> batchUpdate(Map<int, TaskUpdate> updates) async {
    for (final entry in updates.entries) {
      await updateTask(entry.key, entry.value);
    }
  }

  @override
  Future<List<Task>> listSectionTasks(TaskSection section) async {
    return _filterSection(section);
  }

  @override
  Future<List<Task>> listCompletedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) async {
    var completed = _tasks.values
        .where((task) => task.status == TaskStatus.completedActive)
        .toList(growable: false);
    
    // TODO: 实现标签和项目筛选（暂时忽略筛选参数）
    
    completed.sort((a, b) {
      if (a.endedAt == null && b.endedAt == null) return 0;
      if (a.endedAt == null) return 1;
      if (b.endedAt == null) return -1;
      return b.endedAt!.compareTo(a.endedAt!);
    });
    final endIndex = (offset + limit).clamp(0, completed.length);
    return completed.sublist(offset.clamp(0, completed.length), endIndex);
  }

  @override
  Future<List<Task>> listArchivedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) async {
    var archived = _tasks.values
        .where((task) => task.status == TaskStatus.archived)
        .toList(growable: false);
    
    // TODO: 实现标签和项目筛选（暂时忽略筛选参数）
    
    archived.sort((a, b) {
      if (a.archivedAt == null && b.archivedAt == null) return 0;
      if (a.archivedAt == null) return 1;
      if (b.archivedAt == null) return -1;
      return b.archivedAt!.compareTo(a.archivedAt!);
    });
    final endIndex = (offset + limit).clamp(0, archived.length);
    return archived.sublist(offset.clamp(0, archived.length), endIndex);
  }

  @override
  Future<int> countCompletedTasks() async {
    return _tasks.values
        .where((task) => task.status == TaskStatus.completedActive)
        .length;
  }

  @override
  Future<int> countArchivedTasks() async {
    return _tasks.values
        .where((task) => task.status == TaskStatus.archived)
        .length;
  }

  @override
  Future<List<Task>> listTrashedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) async {
    var trashed = _tasks.values
        .where((task) => task.status == TaskStatus.trashed)
        .toList(growable: false);
    
    // TODO: 实现标签和项目筛选（暂时忽略筛选参数）
    
    trashed.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final endIndex = (offset + limit).clamp(0, trashed.length);
    return trashed.sublist(offset.clamp(0, trashed.length), endIndex);
  }

  @override
  Future<int> countTrashedTasks() async {
    return _tasks.values
        .where((task) => task.status == TaskStatus.trashed)
        .length;
  }

  List<Task> _filterSection(TaskSection section) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final laterStart = todayStart.add(const Duration(days: 2));

    return _tasks.values
        .where((task) {
          switch (section) {
            case TaskSection.overdue:
              return task.status == TaskStatus.pending &&
                  task.dueAt != null &&
                  task.dueAt!.isBefore(todayStart);
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
            case TaskSection.thisWeek:
              final dayAfterTomorrow = tomorrowStart.add(
                const Duration(days: 2),
              );
              return task.status == TaskStatus.pending &&
                  task.dueAt != null &&
                  !task.dueAt!.isBefore(dayAfterTomorrow);
            case TaskSection.thisMonth:
              return task.status == TaskStatus.pending &&
                  task.dueAt != null &&
                  task.dueAt!.isAfter(laterStart);
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

  bool _isActiveProjectStatus(TaskStatus status) {
    return status != TaskStatus.archived &&
        status != TaskStatus.trashed &&
        status != TaskStatus.pseudoDeleted &&
        status != TaskStatus.completedActive;
  }


  int _compareDueDates(DateTime? a, DateTime? b) {
    final aSafe = a ?? DateTime(2100, 1, 1);
    final bSafe = b ?? DateTime(2100, 1, 1);
    final compare = aSafe.compareTo(bSafe);
    if (compare != 0) {
      return compare;
    }
    return 0;
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
      case TaskSection.overdue:
      case TaskSection.today:
      case TaskSection.tomorrow:
      case TaskSection.thisWeek:
      case TaskSection.thisMonth:
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
  Future<void> initializeTags() async {
    // 测试实现：初始化一些测试标签
    final testTags = [
      Tag(
        id: 1,
        slug: '@home',
        kind: TagKind.context,
        localizedLabels: {'en': 'Home'},
      ),
      Tag(
        id: 2,
        slug: '#urgent',
        kind: TagKind.priority,
        localizedLabels: {'en': 'Urgent'},
      ),
    ];
    for (final tag in testTags) {
      _tags[tag.slug] = tag;
    }
  }

  @override
  Future<List<Tag>> listByKind(TagKind kind) async =>
      _tags.values.where((tag) => tag.kind == kind).toList(growable: false);

  @override
  Future<Tag?> findBySlug(String slug) async => _tags[slug];

  @override
  Future<void> clearAll() async {
    _tags.clear();
  }
}

class StubPreferenceRepository implements PreferenceRepository {
  final _controller = StreamController<Preference>.broadcast();
  Preference _preference = Preference(
    id: 1,
    localeCode: 'en',
    themeMode: ThemeMode.system,
    fontScaleLevel: FontScaleLevel.medium,
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
      fontScaleLevel: payload.fontScaleLevel,
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
