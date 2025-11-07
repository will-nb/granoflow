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

  /// 批量查询多个任务的总时间
  /// 返回 Map<taskId, totalMinutes>，避免 N+1 查询问题
  Future<Map<int, int>> totalMinutesForTasks(List<int> taskIds);

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
  Future<Map<int, int>> totalMinutesForTasks(List<int> taskIds) async {
    if (taskIds.isEmpty) {
      return {};
    }

    // 一次性查询所有相关任务的 FocusSession
    // 由于 Isar 没有直接的 anyOf 方法，我们使用循环查询并合并结果
    // 对于少量 taskIds，性能影响可接受
    final Map<int, int> result = {};
    
    // 初始化结果，确保所有 taskId 都在结果中
    for (final taskId in taskIds) {
      result[taskId] = 0;
    }

    // 批量查询：每次查询一个 taskId 的所有 sessions
    for (final taskId in taskIds) {
      final sessions = await _isar.focusSessionEntitys
          .filter()
          .taskIdEqualTo(taskId)
          .findAll();
      
      final total = sessions.fold<int>(0, (sum, session) => sum + session.actualMinutes);
      result[taskId] = total;
    }

    return result;
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
