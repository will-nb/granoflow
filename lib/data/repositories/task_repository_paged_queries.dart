part of 'task_repository.dart';

// ignore_for_file: override_on_non_overriding_member
// 这些方法实现抽象类 TaskRepository 中定义的方法，@override 注解是正确的
// analyzer 无法正确识别 part of 文件中的 override 关系

/// TaskRepository 分页查询方法 mixin
/// 
/// 包含已完成、已归档、已删除任务的分页查询方法
/// 
/// 依赖：
/// - TaskRepositoryHelpers: 提供基础辅助方法
mixin TaskRepositoryPagedQueries on TaskRepositoryHelpers {
  /// 分页查询已完成任务（按完成时间降序）
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
    // 查询所有已完成任务（只查询根任务，parentId == null）
    final allTasks = await _isar.taskEntitys
        .filter()
        .statusEqualTo(TaskStatus.completedActive)
        .parentIdIsNull()
        .findAll();

    // 转换为 Domain 模型
    var tasks = allTasks.map(_toDomain).toList();

    // 应用标签筛选（内存筛选，参考watchInboxFiltered的实现）
    tasks = _applyTagAndProjectFilters(
      tasks,
      contextTag: contextTag,
      priorityTag: priorityTag,
      urgencyTag: urgencyTag,
      importanceTag: importanceTag,
      projectId: projectId,
      milestoneId: milestoneId,
      showNoProject: showNoProject,
    );

    // 手动排序：按 endedAt 降序，null 值排在最后
    tasks.sort((a, b) {
      if (a.endedAt == null && b.endedAt == null) return 0;
      if (a.endedAt == null) return 1; // a 的 endedAt 为 null，排在后面
      if (b.endedAt == null) return -1; // b 的 endedAt 为 null，a 排在前面
      return b.endedAt!.compareTo(a.endedAt!); // 降序排列
    });

    // 应用分页
    final endIndex = (offset + limit).clamp(0, tasks.length);
    return tasks.sublist(offset.clamp(0, tasks.length), endIndex);
  }

  /// 分页查询已归档任务（按归档时间降序）
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
    if (kDebugMode) {
      debugPrint(
        '[ArchiveTask] listArchivedTasks: limit=$limit, offset=$offset',
      );
    }
    
    // 查询所有已归档任务（只查询根任务，parentId == null）
    final allTasks = await _isar.taskEntitys
        .filter()
        .statusEqualTo(TaskStatus.archived)
        .parentIdIsNull()
        .findAll();

    if (kDebugMode) {
      debugPrint(
        '[ArchiveTask] listArchivedTasks: Found ${allTasks.length} archived tasks in DB',
      );
    }

    // 转换为 Domain 模型
    var tasks = allTasks.map(_toDomain).toList();

    // 应用标签筛选（内存筛选，参考watchInboxFiltered的实现）
    tasks = _applyTagAndProjectFilters(
      tasks,
      contextTag: contextTag,
      priorityTag: priorityTag,
      urgencyTag: urgencyTag,
      importanceTag: importanceTag,
      projectId: projectId,
      milestoneId: milestoneId,
      showNoProject: showNoProject,
    );

    // 手动排序：按 archivedAt 降序，null 值排在最后
    tasks.sort((a, b) {
      if (a.archivedAt == null && b.archivedAt == null) return 0;
      if (a.archivedAt == null) return 1; // a 的 archivedAt 为 null，排在后面
      if (b.archivedAt == null) return -1; // b 的 archivedAt 为 null，a 排在前面
      return b.archivedAt!.compareTo(a.archivedAt!); // 降序排列
    });

    if (kDebugMode && tasks.isNotEmpty) {
      debugPrint(
        '[ArchiveTask] listArchivedTasks: First task archivedAt=${tasks.first.archivedAt}, Last task archivedAt=${tasks.last.archivedAt}',
      );
    }

    // 应用分页
    final endIndex = (offset + limit).clamp(0, tasks.length);
    final result = tasks.sublist(offset.clamp(0, tasks.length), endIndex);
    
    if (kDebugMode) {
      debugPrint(
        '[ArchiveTask] listArchivedTasks: Returning ${result.length} tasks (offset=$offset, total=${tasks.length})',
      );
    }
    
    return result;
  }

  /// 分页查询已删除任务（按删除时间降序，使用 updatedAt 作为删除时间）
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
    if (kDebugMode) {
      debugPrint(
        '[TrashTask] listTrashedTasks: limit=$limit, offset=$offset',
      );
    }
    
    // 查询所有已删除任务（status == trashed）
    final allTasks = await _isar.taskEntitys
        .filter()
        .statusEqualTo(TaskStatus.trashed)
        .findAll();

    if (kDebugMode) {
      debugPrint(
        '[TrashTask] listTrashedTasks: Found ${allTasks.length} trashed tasks in DB',
      );
    }

    // 转换为 Domain 模型
    var tasks = allTasks.map(_toDomain).toList();

    // 应用标签筛选（内存筛选，参考watchInboxFiltered的实现）
    tasks = _applyTagAndProjectFilters(
      tasks,
      contextTag: contextTag,
      priorityTag: priorityTag,
      urgencyTag: urgencyTag,
      importanceTag: importanceTag,
      projectId: projectId,
      milestoneId: milestoneId,
      showNoProject: showNoProject,
    );

    // 手动排序：按 updatedAt 降序（作为删除时间的近似值）
    tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // 降序排列

    if (kDebugMode && tasks.isNotEmpty) {
      debugPrint(
        '[TrashTask] listTrashedTasks: First task updatedAt=${tasks.first.updatedAt}, Last task updatedAt=${tasks.last.updatedAt}',
      );
    }

    // 应用分页
    final endIndex = (offset + limit).clamp(0, tasks.length);
    final result = tasks.sublist(offset.clamp(0, tasks.length), endIndex);
    
    if (kDebugMode) {
      debugPrint(
        '[TrashTask] listTrashedTasks: Returning ${result.length} tasks (offset=$offset, total=${tasks.length})',
      );
    }
    
    return result;
  }

  /// 应用标签和项目筛选（辅助方法）
  /// 
  /// 用于分页查询方法中的标签和项目筛选逻辑
  List<Task> _applyTagAndProjectFilters(
    List<Task> tasks, {
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) {
    return tasks.where((task) {
      final tags = task.tags;
      
      // 场景标签筛选
      if (contextTag != null && contextTag.isNotEmpty) {
        final normalizedContextTag = TagService.normalizeSlug(contextTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedContextTag,
        )) {
          return false;
        }
      }
      
      // 优先级标签筛选（兼容旧数据）
      if (priorityTag != null && priorityTag.isNotEmpty) {
        final normalizedPriorityTag = TagService.normalizeSlug(priorityTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedPriorityTag,
        )) {
          return false;
        }
      }
      
      // 紧急度标签筛选
      if (urgencyTag != null && urgencyTag.isNotEmpty) {
        final normalizedUrgencyTag = TagService.normalizeSlug(urgencyTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedUrgencyTag,
        )) {
          return false;
        }
      }
      
      // 重要度标签筛选
      if (importanceTag != null && importanceTag.isNotEmpty) {
        final normalizedImportanceTag = TagService.normalizeSlug(importanceTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedImportanceTag,
        )) {
          return false;
        }
      }
      
      // 项目筛选（数据库层筛选）
      // 如果指定了showNoProject，只显示无项目的任务
      if (showNoProject == true) {
        if (task.projectId != null && task.projectId!.isNotEmpty) {
          return false;
        }
      } else {
        // 项目ID筛选
        if (projectId != null && projectId.isNotEmpty) {
          if (task.projectId != projectId) {
            return false;
          }
          
          // 里程碑ID筛选（仅在指定项目时有效）
          if (milestoneId != null && milestoneId.isNotEmpty) {
            if (task.milestoneId != milestoneId) {
              return false;
            }
          }
        } else {
          // 如果没有指定项目，但有指定showNoProject=false，则不筛选
          // 但如果指定了里程碑ID但没有项目ID，应该过滤掉所有任务
          if (milestoneId != null && milestoneId.isNotEmpty) {
            return false; // 里程碑筛选必须指定项目
          }
        }
      }
      
      return true;
    }).toList(growable: false);
  }

  /// 获取已完成任务总数
  @override
  Future<int> countCompletedTasks() async {
    // 只统计根任务（parentId == null）
    return await _isar.taskEntitys
        .filter()
        .statusEqualTo(TaskStatus.completedActive)
        .parentIdIsNull()
        .count();
  }

  /// 获取已归档任务总数
  @override
  Future<int> countArchivedTasks() async {
    // 只统计根任务（parentId == null）
    final count = await _isar.taskEntitys
        .filter()
        .statusEqualTo(TaskStatus.archived)
        .parentIdIsNull()
        .count();
    
    if (kDebugMode) {
      debugPrint('[ArchiveTask] countArchivedTasks: count=$count');
    }
    
    return count;
  }

  /// 获取已删除任务总数
  @override
  Future<int> countTrashedTasks() async {
    final count = await _isar.taskEntitys
        .filter()
        .statusEqualTo(TaskStatus.trashed)
        .count();
    
    if (kDebugMode) {
      debugPrint('[TrashTask] countTrashedTasks: count=$count');
    }
    
    return count;
  }
}

