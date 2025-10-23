import 'dart:async';

import 'package:isar/isar.dart';

import '../isar/focus_session_entity.dart';
import '../models/focus_session.dart';

abstract class FocusSessionRepository {
  Future<FocusSession> startSession({
    required int taskId,
    int? estimateMinutes,
    bool alarmEnabled,
  });

  Future<void> endSession({
    required int sessionId,
    required int actualMinutes,
    int? transferToTaskId,
    String? reflectionNote,
  });

  Stream<FocusSession?> watchActiveSession(int taskId);

  Future<List<FocusSession>> listRecentSessions({
    required int taskId,
    int limit,
  });

  Future<int> totalMinutesForTask(int taskId);

  Future<int> totalMinutesOverall();

  Future<FocusSession?> findById(int sessionId);
}

class IsarFocusSessionRepository implements FocusSessionRepository {
  IsarFocusSessionRepository(this._isar);

  final Isar _isar;

  @override
  Future<FocusSession> startSession({
    required int taskId,
    int? estimateMinutes,
    bool alarmEnabled = false,
  }) async {
    final existing = await _isar.focusSessionEntitys
        .filter()
        .taskIdEqualTo(taskId)
        .endedAtIsNull()
        .findFirst();
    if (existing != null) {
      return _toDomain(existing);
    }
    return _isar.writeTxn<FocusSession>(() async {
      final entity = FocusSessionEntity()
        ..taskId = taskId
        ..startedAt = DateTime.now()
        ..estimateMinutes = estimateMinutes
        ..alarmEnabled = alarmEnabled;
      final id = await _isar.focusSessionEntitys.put(entity);
      entity.id = id;
      return _toDomain(entity);
    });
  }

  @override
  Future<void> endSession({
    required int sessionId,
    required int actualMinutes,
    int? transferToTaskId,
    String? reflectionNote,
  }) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.focusSessionEntitys.get(sessionId);
      if (entity == null) {
        return;
      }
      entity
        ..endedAt = DateTime.now()
        ..actualMinutes = actualMinutes
        ..transferredToTaskId = transferToTaskId
        ..reflectionNote = reflectionNote;
      await _isar.focusSessionEntitys.put(entity);
    });
  }

  @override
  Stream<FocusSession?> watchActiveSession(int taskId) {
    return _watchQuery(() async {
      final entity = await _isar.focusSessionEntitys
          .filter()
          .taskIdEqualTo(taskId)
          .endedAtIsNull()
          .findFirst();
      return entity == null ? null : _toDomain(entity);
    }, _isar.focusSessionEntitys);
  }

  @override
  Future<List<FocusSession>> listRecentSessions({
    required int taskId,
    int limit = 10,
  }) async {
    final sessions = await _isar.focusSessionEntitys
        .filter()
        .taskIdEqualTo(taskId)
        .sortByStartedAtDesc()
        .findAll();
    return sessions.map(_toDomain).take(limit).toList(growable: false);
  }

  @override
  Future<int> totalMinutesForTask(int taskId) async {
    final sessions = await _isar.focusSessionEntitys
        .filter()
        .taskIdEqualTo(taskId)
        .findAll();
    return sessions.fold<int>(0, (sum, session) => sum + session.actualMinutes);
  }

  @override
  Future<int> totalMinutesOverall() async {
    final sessions = await _isar.focusSessionEntitys.where().findAll();
    return sessions.fold<int>(0, (sum, session) => sum + session.actualMinutes);
  }

  @override
  Future<FocusSession?> findById(int sessionId) async {
    final entity = await _isar.focusSessionEntitys.get(sessionId);
    return entity == null ? null : _toDomain(entity);
  }

  FocusSession _toDomain(FocusSessionEntity entity) {
    return FocusSession(
      id: entity.id,
      taskId: entity.taskId,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      actualMinutes: entity.actualMinutes,
      estimateMinutes: entity.estimateMinutes,
      alarmEnabled: entity.alarmEnabled,
      transferredToTaskId: entity.transferredToTaskId,
      reflectionNote: entity.reflectionNote,
    );
  }

  Stream<T> _watchQuery<T>(
    Future<T> Function() fetch,
    IsarCollection<dynamic> collection,
  ) {
    late StreamController<T> controller;
    StreamSubscription<void>? subscription;

    Future<void> emit() async {
      try {
        final value = await fetch();
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
        subscription = collection
            .watchLazy(fireImmediately: false)
            .listen((_) => emit());
      },
      onCancel: () async {
        await subscription?.cancel();
      },
    );

    return controller.stream;
  }
}
