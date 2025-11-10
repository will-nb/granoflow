import '../../data/models/milestone.dart';
import '../../data/models/task.dart';
import '../../data/repositories/milestone_repository.dart';
import '../constants/task_constants.dart';

class MilestoneService {
  MilestoneService({
    required MilestoneRepository milestoneRepository,
    DateTime Function()? clock,
  })  : _milestones = milestoneRepository,
        _clock = clock ?? DateTime.now;

  final MilestoneRepository _milestones;
  final DateTime Function() _clock;

  Stream<List<Milestone>> watchByProjectId(String projectId) {
    return _milestones.watchByProjectId(projectId);
  }

  Future<List<Milestone>> listByProjectId(String projectId) {
    return _milestones.listByProjectId(projectId);
  }

  Future<Milestone?> findById(String id) {
    return _milestones.findById(id);
  }

  Future<Milestone> createMilestone({
    required String projectId,
    required String title,
    DateTime? dueAt,
    String? description,
    List<String> tags = const <String>[],
  }) async {
    final now = _clock();
    final logs = <MilestoneLogEntry>[];

    // 标准化截止日期到当天23:59:59
    DateTime? normalizedDueAt;
    if (dueAt != null) {
      normalizedDueAt = DateTime(
        dueAt.year,
        dueAt.month,
        dueAt.day,
        23,
        59,
        59,
        999,
      );
      logs.add(
        MilestoneLogEntry(
          timestamp: now,
          action: 'deadline_set',
          next: normalizedDueAt.toIso8601String(),
        ),
      );
    }

    final draft = MilestoneDraft(
      projectId: projectId,
      title: title,
      status: TaskStatus.pending,
      dueAt: normalizedDueAt,
      description: description,
      tags: tags,
      sortIndex: TaskConstants.DEFAULT_SORT_INDEX,
      logs: logs,
    );

    return _milestones.create(draft);
  }

  Future<void> updateMilestone({
    required String id,
    String? title,
    DateTime? dueAt,
    String? description,
    List<String>? tags,
    TaskStatus? status,
  }) async {
    final milestone = await _milestones.findById(id);
    if (milestone == null) {
      throw StateError('Milestone not found: $id');
    }

    final logs = milestone.logs.toList(growable: true);
    final now = _clock();

    // 记录截止日期变更
    if (dueAt != null && dueAt != milestone.dueAt) {
      logs.add(
        MilestoneLogEntry(
          timestamp: now,
          action: 'deadline_changed',
          previous: milestone.dueAt?.toIso8601String(),
          next: dueAt.toIso8601String(),
        ),
      );
    }

    // 记录状态变更
    if (status != null && status != milestone.status) {
      logs.add(
        MilestoneLogEntry(
          timestamp: now,
          action: 'status_changed',
          previous: milestone.status.name,
          next: status.name,
        ),
      );
    }

    final update = MilestoneUpdate(
      title: title,
      dueAt: dueAt,
      description: description,
      tags: tags,
      status: status,
      logs: logs,
    );

    await _milestones.update(id, update);
  }

  Future<void> delete(String id) {
    return _milestones.delete(id);
  }
}
