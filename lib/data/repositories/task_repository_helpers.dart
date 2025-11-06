part of 'task_repository.dart';

/// TaskRepository 辅助方法 mixin
/// 
/// 包含所有辅助方法，如 Entity/Domain 转换、任务 ID 生成等
mixin TaskRepositoryHelpers {
  /// 获取 Isar 实例（由实现类提供）
  Isar get _isar;

  /// 获取时钟函数（由实现类提供）
  DateTime Function() get _clock;

  /// 将 Entity 转换为 Domain 模型
  Task _toDomain(TaskEntity entity) {
    // 规范化 tags（兼容旧数据，去除前缀）
    final normalizedTags = entity.tags
        .map((tag) => TagService.normalizeSlug(tag))
        .toList(growable: false);

    return Task(
      id: entity.id,
      taskId: entity.taskId,
      title: entity.title,
      status: entity.status,
      dueAt: entity.dueAt,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      archivedAt: entity.archivedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      parentId: entity.parentId,
      parentTaskId: entity.parentTaskId,
      projectId: entity.projectId,
      milestoneId: entity.milestoneId,
      sortIndex: entity.sortIndex,
      tags: List.unmodifiable(normalizedTags),
      templateLockCount: entity.templateLockCount,
      seedSlug: entity.seedSlug,
      allowInstantComplete: entity.allowInstantComplete,
      description: entity.description,
      logs: List.unmodifiable(entity.logs.map(_logToDomain)),
    );
  }

  /// 将 Domain 模型转换为 Entity
  TaskEntity _fromDomain(Task task) {
    final entity = TaskEntity()
      ..id = task.id
      ..taskId = task.taskId
      ..title = task.title
      ..status = task.status
      ..dueAt = task.dueAt
      ..startedAt = task.startedAt
      ..endedAt = task.endedAt
      ..archivedAt = task.archivedAt
      ..createdAt = task.createdAt
      ..updatedAt = task.updatedAt
      ..parentId = task.parentId
      ..parentTaskId = task.parentTaskId
      ..projectId = task.projectId
      ..milestoneId = task.milestoneId
      ..sortIndex = task.sortIndex
      ..tags = task.tags.map((tag) => TagService.normalizeSlug(tag)).toList()
      ..templateLockCount = task.templateLockCount
      ..seedSlug = task.seedSlug
      ..allowInstantComplete = task.allowInstantComplete
      ..description = task.description
      ..logs = task.logs.map(_logFromDomain).toList();
    return entity;
  }

  /// 将日志 Entity 转换为 Domain 模型
  TaskLogEntry _logToDomain(TaskLogEntryEntity entity) {
    return TaskLogEntry(
      timestamp: entity.timestamp,
      action: entity.action,
      previous: entity.previous,
      next: entity.next,
      actor: entity.actor,
    );
  }

  /// 将日志 Domain 模型转换为 Entity
  TaskLogEntryEntity _logFromDomain(TaskLogEntry entry) {
    return TaskLogEntryEntity()
      ..timestamp = entry.timestamp
      ..action = entry.action
      ..previous = entry.previous
      ..next = entry.next
      ..actor = entry.actor;
  }

  /// 生成任务 ID
  /// 
  /// 格式：${秒级时间戳}${4位序号}（14位纯数字）
  /// 同一秒内的任务序号递增，新的一秒从 0001 开始
  Future<String> _generateTaskId(DateTime now) async {
    final secondsSinceEpoch = now.millisecondsSinceEpoch ~/ 1000;

    try {
      // 获取同一秒内已使用的最大序号
      final maxSequence = await _getMaxSequenceInSecond(secondsSinceEpoch);
      
      // 生成下一个序号
      final nextSequence = maxSequence + 1;
      
      // 检查序号是否溢出（4位最大9999）
      if (nextSequence > 9999) {
        debugPrint('Warning: Sequence overflow in second $secondsSinceEpoch. Using 9999.');
        // 如果溢出，等待到下一秒或使用9999
        // 这里选择等待到下一秒，生成新的 taskId
        final nextSecond = secondsSinceEpoch + 1;
        final sequenceStr = '0001';
        return '$nextSecond$sequenceStr';
      }
      
      final sequenceStr = nextSequence.toString().padLeft(4, '0');
      return '$secondsSinceEpoch$sequenceStr';
    } catch (e) {
      debugPrint('Error generating taskId: $e');
      // 错误时返回默认格式
      final sequenceStr = '0001';
      return '$secondsSinceEpoch$sequenceStr';
    }
  }

  /// 获取同一秒内创建的任务的最大序号
  /// 
  /// [secondsSinceEpoch] 秒级时间戳
  /// 返回该秒内已使用的最大序号，如果没有则返回 0
  Future<int> _getMaxSequenceInSecond(int secondsSinceEpoch) async {
    try {
      final timestampPrefix = secondsSinceEpoch.toString();
      
      // 查询最近创建的任务（限制数量以提高性能）
      // 同一秒内的任务应该在最近创建的任务中，所以先查询最近的任务
      final recentTasks = await _isar.taskEntitys
          .where()
          .sortByCreatedAtDesc()
          .limit(100) // 限制查询数量，通常同一秒内不会有太多任务
          .findAll();

      int maxSequence = 0;
      
      // 遍历任务，查找同一秒内的任务
      for (final entity in recentTasks) {
        // 检查 taskId 是否以该秒级时间戳开头且长度为14位
        if (entity.taskId.length == 14 && 
            entity.taskId.startsWith(timestampPrefix)) {
          final parsed = _parseTaskId(entity.taskId);
          if (parsed != null && 
              parsed['timestamp'] == secondsSinceEpoch) {
            final sequence = parsed['sequence'] as int;
            maxSequence = math.max(maxSequence, sequence);
          }
        }
      }

      return maxSequence;
    } catch (e) {
      debugPrint('Error getting max sequence in second: $e');
      return 0;
    }
  }

  /// 解析任务 ID 格式
  /// 
  /// 格式：14位纯数字，前10位是秒级时间戳，后4位是序号
  /// 返回 Map 包含 'timestamp' 和 'sequence' 键，或 null 如果格式无效
  Map<String, dynamic>? _parseTaskId(String taskId) {
    try {
      if (taskId.isEmpty || taskId.length != 14) return null;

      final timestampStr = taskId.substring(0, 10);
      final sequenceStr = taskId.substring(10, 14);

      final timestamp = int.tryParse(timestampStr);
      final sequence = int.tryParse(sequenceStr);

      if (timestamp == null || sequence == null) return null;

      return {'timestamp': timestamp, 'sequence': sequence};
    } catch (e) {
      debugPrint('Error parsing taskId: $e');
      return null;
    }
  }

  /// 判断是否为普通任务（没有关联项目或里程碑）
  bool _isRegularTask(TaskEntity entity) {
    return entity.projectId == null && entity.milestoneId == null;
  }

  /// 判断是否为活跃轻量任务状态
  bool _isActiveQuickTaskStatus(TaskStatus status) {
    return status != TaskStatus.archived &&
        status != TaskStatus.trashed &&
        status != TaskStatus.pseudoDeleted &&
        status != TaskStatus.completedActive;
  }
}


