import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/milestone_service.dart';
import 'package:granoflow/data/models/milestone.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/milestone_repository.dart';

void main() {
  group('MilestoneService', () {
    late _InMemoryMilestoneRepository milestoneRepository;
    late MilestoneService service;

    setUp(() {
      milestoneRepository = _InMemoryMilestoneRepository();
      service = MilestoneService(
        milestoneRepository: milestoneRepository,
        clock: () => DateTime(2024, 2, 10, 9),
      );
    });

    test('createMilestone creates milestone with metadata', () async {
      final milestone = await service.createMilestone(
        projectId: 'prj-123',
        title: 'Test Milestone',
        dueAt: DateTime(2024, 3, 1),
        description: 'Test description',
        tags: const <String>['#urgent'],
      );

      expect(milestone.title, 'Test Milestone');
      expect(milestone.projectId, 'prj-123');
      expect(milestone.description, 'Test description');
      expect(milestone.status, TaskStatus.pending);
      expect(milestone.tags, contains('#urgent'));
      expect(milestone.dueAt, DateTime(2024, 3, 1, 23, 59, 59, 999));
      expect(milestone.logs.isNotEmpty, isTrue);
      expect(milestone.logs.first.action, 'deadline_set');
    });

    test('createMilestone creates milestone without optional fields', () async {
      final milestone = await service.createMilestone(
        projectId: 'prj-123',
        title: 'Simple Milestone',
      );

      expect(milestone.title, 'Simple Milestone');
      expect(milestone.description, isNull);
      expect(milestone.dueAt, isNull);
      expect(milestone.tags, isEmpty);
    });

    test('updateMilestone updates milestone fields', () async {
      final milestone = await service.createMilestone(
        projectId: 'prj-123',
        title: 'Original Title',
        dueAt: DateTime(2024, 3, 1),
        description: 'Original description',
      );

      final newDeadline = DateTime(2024, 4, 1);
      await service.updateMilestone(
        id: milestone.id,
        title: 'Updated Title',
        dueAt: newDeadline,
        description: 'Updated description',
      );

      final updated = await milestoneRepository.findByIsarId(milestone.id);
      expect(updated, isNotNull);
      expect(updated!.title, 'Updated Title');
      expect(updated.description, 'Updated description');
      expect(updated.dueAt, newDeadline);
    });

    test('updateMilestone records deadline change log', () async {
      final milestone = await service.createMilestone(
        projectId: 'prj-123',
        title: 'Test',
        dueAt: DateTime(2024, 3, 1),
      );

      await service.updateMilestone(
        id: milestone.id,
        dueAt: DateTime(2024, 4, 1),
      );

      final updated = await milestoneRepository.findByIsarId(milestone.id);
      expect(updated, isNotNull);
      final deadlineLogs = updated!.logs
          .where((log) => log.action == 'deadline_changed')
          .toList();
      expect(deadlineLogs, isNotEmpty);
    });

    test('updateMilestone records status change log', () async {
      final milestone = await service.createMilestone(
        projectId: 'prj-123',
        title: 'Test',
      );

      await service.updateMilestone(
        id: milestone.id,
        status: TaskStatus.completedActive,
      );

      final updated = await milestoneRepository.findByIsarId(milestone.id);
      expect(updated, isNotNull);
      final statusLogs = updated!.logs
          .where((log) => log.action == 'status_changed')
          .toList();
      expect(statusLogs, isNotEmpty);
      expect(statusLogs.first.previous, TaskStatus.pending.name);
      expect(statusLogs.first.next, TaskStatus.completedActive.name);
    });

    test('updateMilestone throws when milestone not found', () async {
      expect(
        () => service.updateMilestone(id: 999, title: 'Test'),
        throwsA(isA<StateError>()),
      );
    });

    test('delete removes milestone', () async {
      final milestone = await service.createMilestone(
        projectId: 'prj-123',
        title: 'To Delete',
      );

      await service.delete(milestone.id);

      final deleted = await milestoneRepository.findByIsarId(milestone.id);
      expect(deleted, isNull);
    });
  });
}

class _InMemoryMilestoneRepository implements MilestoneRepository {
  _InMemoryMilestoneRepository()
    : _controller = StreamController<List<Milestone>>.broadcast();

  final Map<int, Milestone> _milestones = <int, Milestone>{};
  final StreamController<List<Milestone>> _controller;
  int _nextId = 1;

  @override
  Future<Milestone> create(MilestoneDraft draft) async {
    final milestone = Milestone(
      id: _nextId++,

      projectId: draft.projectId,
      title: draft.title,
      status: draft.status,
      dueAt: draft.dueAt,
      startedAt: draft.startedAt,
      endedAt: draft.endedAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sortIndex: draft.sortIndex,
      tags: List<String>.from(draft.tags),
      templateLockCount: draft.templateLockCount,
      seedSlug: draft.seedSlug,
      allowInstantComplete: draft.allowInstantComplete,
      description: draft.description,
      logs: List<MilestoneLogEntry>.from(draft.logs),
    );
    _milestones[milestone.id] = milestone;
    _emitForProject(milestone.projectId);
    return milestone;
  }

  @override
  Future<void> update(int isarId, MilestoneUpdate update) async {
    final current = _milestones[isarId];
    if (current == null) return;
    _milestones[isarId] = current.copyWith(
      title: update.title,
      status: update.status,
      dueAt: update.dueAt,
      startedAt: update.startedAt,
      endedAt: update.endedAt,
      sortIndex: update.sortIndex,
      tags: update.tags,
      templateLockCount: current.templateLockCount + update.templateLockDelta,
      allowInstantComplete: update.allowInstantComplete,
      description: update.description,
      logs: update.logs,
    );
    _emitForProject(current.projectId);
  }

  @override
  Future<void> delete(int isarId) async {
    final removed = _milestones.remove(isarId);
    if (removed != null) {
      _emitForProject(removed.projectId);
    }
  }

  @override
  Stream<List<Milestone>> watchByProjectId(String projectId) {
    return _controller.stream.map(
      (list) => list.where((m) => m.projectId == projectId).toList(),
    );
  }

  @override
  Future<List<Milestone>> listByProjectId(String projectId) async {
    return _milestones.values
        .where((milestone) => milestone.projectId == projectId)
        .toList(growable: false);
  }

  @override
  Future<Milestone?> findByIsarId(int id) async => _milestones[id];

  @override
  Future<Milestone?> findByMilestoneId(String milestoneId) async {
    for (final milestone in _milestones.values) {
      if (milestone.milestoneId == milestoneId) {
        return milestone;
      }
    }
    return null;
  }

  @override
  Future<Milestone> createMilestoneWithId(
    MilestoneDraft draft,
    String milestoneId,
    DateTime createdAt,
    DateTime updatedAt,
  ) async {
    final milestone = Milestone(
      id: _nextId++,

      projectId: draft.projectId,
      title: draft.title,
      status: draft.status,
      dueAt: draft.dueAt,
      startedAt: draft.startedAt,
      endedAt: draft.endedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sortIndex: draft.sortIndex,
      tags: List<String>.from(draft.tags),
      templateLockCount: draft.templateLockCount,
      seedSlug: draft.seedSlug,
      allowInstantComplete: draft.allowInstantComplete,
      description: draft.description,
      logs: List<MilestoneLogEntry>.from(draft.logs),
    );
    _milestones[milestone.id] = milestone;
    _emitForProject(milestone.projectId);
    return milestone;
  }

  @override
  Future<List<Milestone>> listAll() async {
    return _milestones.values.toList(growable: false);
  }

  @override
  Future<void> setMilestoneProjectIsarId(
    int milestoneId,
    int projectIsarId,
  ) async {
    // 测试中不需要实现，因为内存实现不维护 Isar ID 关系
  }

  void _emitForProject(String projectId) {
    final snapshot = _milestones.values.toList(growable: false);
    if (_controller.hasListener) {
      _controller.add(snapshot);
    }
  }
}
