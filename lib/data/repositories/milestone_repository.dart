import 'dart:async';

import 'package:isar/isar.dart';

import '../../core/services/tag_service.dart';
import '../isar/milestone_entity.dart';
import '../models/milestone.dart';
import '../models/task.dart';

abstract class MilestoneRepository {
  Stream<List<Milestone>> watchByProjectId(String projectId);

  Future<List<Milestone>> listByProjectId(String projectId);

  Future<Milestone?> findByIsarId(int id);

  Future<Milestone?> findByMilestoneId(String milestoneId);

  Future<Milestone> create(MilestoneDraft draft);

  /// 使用指定的 milestoneId 创建里程碑（用于导入）
  /// 
  /// [draft] 里程碑草稿，其中的 milestoneId 将被忽略
  /// [milestoneId] 要使用的业务ID
  /// [createdAt] 创建时间（从导入数据中获取）
  /// [updatedAt] 更新时间（从导入数据中获取）
  Future<Milestone> createMilestoneWithId(
    MilestoneDraft draft,
    String milestoneId,
    DateTime createdAt,
    DateTime updatedAt,
  );

  Future<void> update(int isarId, MilestoneUpdate update);

  /// 设置里程碑的 projectIsarId（用于导入）
  /// 
  /// [milestoneId] 里程碑的 Isar ID
  /// [projectIsarId] 项目的 Isar ID
  Future<void> setMilestoneProjectIsarId(
    int milestoneId,
    int projectIsarId,
  );

  Future<void> delete(int isarId);

  /// 列出所有里程碑（用于导出）
  Future<List<Milestone>> listAll();
}

class IsarMilestoneRepository implements MilestoneRepository {
  IsarMilestoneRepository(this._isar, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Isar _isar;
  final DateTime Function() _clock;

  @override
  Stream<List<Milestone>> watchByProjectId(String projectId) {
    return _watchQuery(() async {
      final entities = await _isar.milestoneEntitys
          .filter()
          .projectIdEqualTo(projectId)
          .findAll();
      final visible = entities
          .where((entity) => _isVisibleMilestoneStatus(entity.status))
          .toList(growable: false);
      visible.sort(_compareByDueThenCreated);
      return visible.map(_toDomain).toList(growable: false);
    });
  }

  @override
  Future<List<Milestone>> listByProjectId(String projectId) async {
    final entities = await _isar.milestoneEntitys
        .filter()
        .projectIdEqualTo(projectId)
        .findAll();
    final visible = entities
        .where((entity) => _isVisibleMilestoneStatus(entity.status))
        .toList(growable: false);
    visible.sort(_compareByDueThenCreated);
    return visible.map(_toDomain).toList(growable: false);
  }

  @override
  Future<Milestone?> findByIsarId(int id) async {
    final entity = await _isar.milestoneEntitys.get(id);
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Future<Milestone?> findByMilestoneId(String milestoneId) async {
    final entity = await _isar.milestoneEntitys
        .filter()
        .milestoneIdEqualTo(milestoneId)
        .findFirst();
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Future<Milestone> create(MilestoneDraft draft) async {
    return _isar.writeTxn<Milestone>(() async {
      final now = _clock();
      return await _createMilestoneWithIdInternal(
        draft,
        draft.milestoneId,
        now,
        now,
      );
    });
  }

  @override
  Future<Milestone> createMilestoneWithId(
    MilestoneDraft draft,
    String milestoneId,
    DateTime createdAt,
    DateTime updatedAt,
  ) async {
    return _isar.writeTxn<Milestone>(() async {
      return await _createMilestoneWithIdInternal(
        draft,
        milestoneId,
        createdAt,
        updatedAt,
      );
    });
  }

  /// 内部方法：使用指定的 milestoneId 创建里程碑实体
  Future<Milestone> _createMilestoneWithIdInternal(
    MilestoneDraft draft,
    String milestoneId,
    DateTime createdAt,
    DateTime updatedAt,
  ) async {
    final entity = MilestoneEntity()
      ..milestoneId = milestoneId
      ..projectId = draft.projectId
      ..projectIsarId = null
      ..title = draft.title
      ..status = draft.status
      ..dueAt = draft.dueAt
      ..startedAt = draft.startedAt
      ..endedAt = draft.endedAt
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..sortIndex = draft.sortIndex
      ..tags = draft.tags.map((tag) => TagService.normalizeSlug(tag)).toList()
      ..templateLockCount = draft.templateLockCount
      ..seedSlug = draft.seedSlug
      ..allowInstantComplete = draft.allowInstantComplete
      ..description = draft.description
      ..logs = draft.logs.map(_logFromDomain).toList();
    final id = await _isar.milestoneEntitys.put(entity);
    entity.id = id;
    return _toDomain(entity);
  }

  @override
  Future<List<Milestone>> listAll() async {
    final entities = await _isar.milestoneEntitys.where().findAll();
    entities.sort(_compareByDueThenCreated);
    return entities.map(_toDomain).toList(growable: false);
  }

  @override
  Future<void> update(int isarId, MilestoneUpdate update) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.milestoneEntitys.get(isarId);
      if (entity == null) {
        return;
      }

      entity
        ..title = update.title ?? entity.title
        ..status = update.status ?? entity.status
        ..dueAt = update.dueAt ?? entity.dueAt
        ..startedAt = update.startedAt ?? entity.startedAt
        ..endedAt = update.endedAt ?? entity.endedAt
        ..sortIndex = update.sortIndex ?? entity.sortIndex
        ..tags = update.tags != null
            ? update.tags!.map((tag) => TagService.normalizeSlug(tag)).toList()
            : entity.tags
        ..templateLockCount =
            (entity.templateLockCount + update.templateLockDelta).clamp(
              0,
              1 << 31,
            )
        ..allowInstantComplete =
            update.allowInstantComplete ?? entity.allowInstantComplete
        ..description = update.description ?? entity.description
        ..logs = update.logs != null
            ? update.logs!.map(_logFromDomain).toList()
            : entity.logs
        ..updatedAt = _clock();

      await _isar.milestoneEntitys.put(entity);
    });
  }

  @override
  Future<void> setMilestoneProjectIsarId(
    int milestoneId,
    int projectIsarId,
  ) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.milestoneEntitys.get(milestoneId);
      if (entity == null) {
        return;
      }

      entity.projectIsarId = projectIsarId;

      await _isar.milestoneEntitys.put(entity);
    });
  }

  @override
  Future<void> delete(int isarId) {
    return _isar.writeTxn(() => _isar.milestoneEntitys.delete(isarId));
  }

  Milestone _toDomain(MilestoneEntity entity) {
    final normalizedTags = entity.tags
        .map((tag) => TagService.normalizeSlug(tag))
        .toList(growable: false);
    return Milestone(
      id: entity.id,
      milestoneId: entity.milestoneId,
      projectId: entity.projectId,
      title: entity.title,
      status: entity.status,
      dueAt: entity.dueAt,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      sortIndex: entity.sortIndex,
      tags: List.unmodifiable(normalizedTags),
      templateLockCount: entity.templateLockCount,
      seedSlug: entity.seedSlug,
      allowInstantComplete: entity.allowInstantComplete,
      description: entity.description,
      logs: List.unmodifiable(entity.logs.map(_logToDomain)),
    );
  }

  MilestoneLogEntry _logToDomain(MilestoneLogEntryEntity entity) {
    return MilestoneLogEntry(
      timestamp: entity.timestamp,
      action: entity.action,
      previous: entity.previous,
      next: entity.next,
      actor: entity.actor,
    );
  }

  MilestoneLogEntryEntity _logFromDomain(MilestoneLogEntry entry) {
    return MilestoneLogEntryEntity()
      ..timestamp = entry.timestamp
      ..action = entry.action
      ..previous = entry.previous
      ..next = entry.next
      ..actor = entry.actor;
  }

  int _compareByDueThenCreated(MilestoneEntity a, MilestoneEntity b) {
    final aDue = a.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000);
    final bDue = b.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000);
    final compareDue = aDue.compareTo(bDue);
    if (compareDue != 0) {
      return compareDue;
    }
    return a.createdAt.compareTo(b.createdAt);
  }

  Stream<T> _watchQuery<T>(Future<T> Function() query) {
    late StreamController<T> controller;
    StreamSubscription<void>? subscription;

    Future<void> emit() async {
      if (controller.isClosed) {
        return;
      }
      try {
        final value = await query();
        if (!controller.isClosed) {
          controller.add(value);
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<T>(
      onListen: () {
        emit();
        subscription = _isar.milestoneEntitys
            .watchLazy(fireImmediately: false)
            .listen((_) => emit());
      },
      onCancel: () async {
        await subscription?.cancel();
      },
    );

    return controller.stream;
  }

  bool _isVisibleMilestoneStatus(TaskStatus status) {
    return status != TaskStatus.archived &&
        status != TaskStatus.trashed &&
        status != TaskStatus.pseudoDeleted;
  }
}
