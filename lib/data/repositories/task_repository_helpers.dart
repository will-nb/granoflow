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
  /// 格式：YYYYMMDD-XXXX（日期-序号）
  /// 同一天的任务序号递增，新的一天从 0001 开始
  Future<String> _generateTaskId(DateTime now) async {
    final dateString =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    try {
      final latestTask = await _getLatestTask();

      if (latestTask == null) {
        return '$dateString-0001';
      }

      final parsed = _parseTaskId(latestTask.taskId);
      if (parsed == null) {
        return '$dateString-0001';
      }

      final latestDate = parsed['date'] as String;
      final latestSuffix = parsed['suffix'] as int;

      if (latestDate == dateString) {
        // 如果是今天，后缀+1
        final nextSuffix = (latestSuffix + 1).toString().padLeft(4, '0');
        return '$dateString-$nextSuffix';
      } else {
        // 如果不是今天，从0001开始
        return '$dateString-0001';
      }
    } catch (e) {
      debugPrint('Error generating taskId: $e');
      return '$dateString-0001';
    }
  }

  /// 查询最新创建的任务
  Future<Task?> _getLatestTask() async {
    try {
      final tasks = await _isar.taskEntitys
          .where()
          .sortByCreatedAtDesc()
          .limit(1)
          .findAll();

      return tasks.isNotEmpty ? _toDomain(tasks.first) : null;
    } catch (e) {
      debugPrint('Error querying latest task: $e');
      return null;
    }
  }

  /// 解析任务 ID 格式，提取日期和后缀
  /// 
  /// 返回 Map 包含 'date' 和 'suffix' 键，或 null 如果格式无效
  Map<String, dynamic>? _parseTaskId(String taskId) {
    try {
      if (taskId.isEmpty) return null;

      final parts = taskId.split('-');
      if (parts.length != 2) return null;

      final datePart = parts[0];
      final suffixPart = parts[1];

      if (datePart.length != 8) return null;

      final suffixInt = int.tryParse(suffixPart);
      if (suffixInt == null) return null;

      return {'date': datePart, 'suffix': suffixInt};
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


