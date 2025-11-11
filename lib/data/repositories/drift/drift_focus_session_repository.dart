import 'dart:async';

import 'package:drift/drift.dart';

import '../../database/database_adapter.dart';
import '../../drift/database.dart' hide FocusSession;
import '../../drift/database.dart' as drift show FocusSession;
import '../../drift/converters.dart';
import '../../models/focus_session.dart';
import '../focus_session_repository.dart';

/// Drift 版本的 FocusSessionRepository 实现
class DriftFocusSessionRepository implements FocusSessionRepository {
  DriftFocusSessionRepository(this._adapter);

  final DatabaseAdapter _adapter;

  /// 获取 AppDatabase 实例
  AppDatabase get _db => AppDatabase.instance;

  @override
  Future<FocusSession> startSession({
    required String taskId,
    int? estimateMinutes,
    bool alarmEnabled = false,
  }) async {
    return await _adapter.writeTransaction(() async {
      final sessionId = generateUuid();
      final now = DateTime.now();

      final entity = drift.FocusSession(
        id: sessionId,
        taskId: taskId,
        startedAt: now,
        endedAt: null,
        actualMinutes: 0,
        estimateMinutes: estimateMinutes,
        alarmEnabled: alarmEnabled,
        transferredToTaskId: null,
        reflectionNote: null,
      );

      await _db.into(_db.focusSessions).insert(entity);
      return _toFocusSession(entity);
    });
  }

  @override
  Future<void> endSession({
    required String sessionId,
    required int actualMinutes,
    String? transferToTaskId,
    String? reflectionNote,
  }) async {
    await _adapter.writeTransaction(() async {
      await (_db.update(_db.focusSessions)..where((f) => f.id.equals(sessionId))).write(
        FocusSessionsCompanion(
          endedAt: Value(DateTime.now()),
          actualMinutes: Value(actualMinutes),
          transferredToTaskId: transferToTaskId != null ? Value(transferToTaskId) : const Value.absent(),
          reflectionNote: reflectionNote != null ? Value(reflectionNote) : const Value.absent(),
        ),
      );
    });
  }

  @override
  Future<void> updateSessionActualMinutes({
    required String sessionId,
    required int actualMinutes,
  }) async {
    await _adapter.writeTransaction(() async {
      await (_db.update(_db.focusSessions)..where((f) => f.id.equals(sessionId))).write(
        FocusSessionsCompanion(
          actualMinutes: Value(actualMinutes),
        ),
      );
    });
  }

  @override
  Stream<FocusSession?> watchActiveSession(String taskId) {
    final query = _db.select(_db.focusSessions)
      ..where((f) => f.taskId.equals(taskId) & f.endedAt.isNull());
    return query.watchSingleOrNull().asyncMap((entity) async {
      if (entity == null) return null;
      return _toFocusSession(entity);
    });
  }

  @override
  Future<List<FocusSession>> listRecentSessions({
    required String taskId,
    int limit = 10,
  }) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.focusSessions)
        ..where((f) => f.taskId.equals(taskId))
        ..orderBy([(f) => OrderingTerm(expression: f.startedAt, mode: OrderingMode.desc)])
        ..limit(limit);
      final entities = await query.get();
      return entities.map(_toFocusSession).toList();
    });
  }

  @override
  Future<int> totalMinutesForTask(String taskId) async {
    return await _adapter.readTransaction(() async {
      final query = _db.selectOnly(_db.focusSessions)
        ..addColumns([_db.focusSessions.actualMinutes.sum()])
        ..where(_db.focusSessions.taskId.equals(taskId));
      final result = await query.getSingle();
      return result.read(_db.focusSessions.actualMinutes.sum()) ?? 0;
    });
  }

  @override
  Future<Map<String, int>> totalMinutesForTasks(List<String> taskIds) async {
    if (taskIds.isEmpty) return {};

    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.focusSessions)
        ..where((f) => f.taskId.isIn(taskIds));
      final entities = await query.get();

      final result = <String, int>{};
      for (final entity in entities) {
        final taskId = entity.taskId ?? '';
        result[taskId] = (result[taskId] ?? 0) + entity.actualMinutes;
      }
      return result;
    });
  }

  @override
  Future<int> totalMinutesOverall() async {
    return await _adapter.readTransaction(() async {
      final query = _db.selectOnly(_db.focusSessions)
        ..addColumns([_db.focusSessions.actualMinutes.sum()]);
      final result = await query.getSingle();
      return result.read(_db.focusSessions.actualMinutes.sum()) ?? 0;
    });
  }

  @override
  Future<FocusSession?> findById(String sessionId) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.focusSessions)..where((f) => f.id.equals(sessionId));
      final entity = await query.getSingleOrNull();
      if (entity == null) return null;
      return _toFocusSession(entity);
    });
  }

  /// 将 Drift FocusSession 实体转换为领域模型 FocusSession
  FocusSession _toFocusSession(drift.FocusSession entity) {
    return FocusSession(
      id: entity.id,
      taskId: entity.taskId ?? '',
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      actualMinutes: entity.actualMinutes,
      estimateMinutes: entity.estimateMinutes,
      alarmEnabled: entity.alarmEnabled,
      transferredToTaskId: entity.transferredToTaskId,
      reflectionNote: entity.reflectionNote,
    );
  }
}
