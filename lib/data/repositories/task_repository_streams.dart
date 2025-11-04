part of 'task_repository.dart';

// ignore_for_file: override_on_non_overriding_member
// 这些方法实现抽象类 TaskRepository 中定义的方法，@override 注解是正确的
// analyzer 无法正确识别 part of 文件中的 override 关系

/// TaskRepository Stream 监听方法 mixin
/// 
/// 包含所有 Stream 相关的方法，用于实时监听任务数据变化
/// 
/// 依赖：
/// - TaskRepositoryHelpers: 提供 _toDomain, _isActiveQuickTaskStatus, _isar, _clock
/// - TaskRepositorySectionQueries: 提供 _fetchSection
/// - TaskRepositoryTaskHierarchy: 提供 _buildTree
mixin TaskRepositoryStreams
    on TaskRepositoryHelpers,
        TaskRepositorySectionQueries,
        TaskRepositoryTaskHierarchy {

  /// 监听区域任务列表变化
  @override
  Stream<List<Task>> watchSection(TaskSection section) {
    return _watchQuery(() => _fetchSection(section));
  }

  /// 监听任务树变化
  @override
  Stream<TaskTreeNode> watchTaskTree(int rootTaskId) {
    return _watchQuery(() => _buildTree(rootTaskId));
  }

  /// 监听收集箱任务列表变化
  @override
  Stream<List<Task>> watchInbox() {
    return _watchQuery(() async {
      final results = await _isar.taskEntitys
          .filter()
          .statusEqualTo(TaskStatus.inbox)
          .sortBySortIndex()
          .thenByCreatedAtDesc()
          .findAll();
      // 移除过滤，让 inbox 页面显示所有任务（包括关联项目的）
      final tasks = results.map(_toDomain).toList(growable: false);
      return tasks;
    });
  }

  /// 监听过滤后的收集箱任务列表变化
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
    return _watchQuery(() async {
      final entities = await _isar.taskEntitys
          .filter()
          .statusEqualTo(TaskStatus.inbox)
          .sortBySortIndex()
          .thenByCreatedAtDesc()
          .findAll();
      // 移除 _isRegularTask 过滤，让 inbox 页面显示所有任务（包括关联项目的）
      // 然后按标签和项目过滤
      final filtered = entities.where((entity) {
            final tags = entity.tags;
            // 规范化标签后进行比较（兼容旧数据）
            if (contextTag != null && contextTag.isNotEmpty) {
              final normalizedContextTag = TagService.normalizeSlug(contextTag);
              if (!tags.any(
                (tag) => TagService.normalizeSlug(tag) == normalizedContextTag,
              )) {
                return false;
              }
            }
            if (priorityTag != null && priorityTag.isNotEmpty) {
              final normalizedPriorityTag = TagService.normalizeSlug(
                priorityTag,
              );
              if (!tags.any(
                (tag) => TagService.normalizeSlug(tag) == normalizedPriorityTag,
              )) {
                return false;
              }
            }
            if (urgencyTag != null && urgencyTag.isNotEmpty) {
              final normalizedUrgencyTag = TagService.normalizeSlug(urgencyTag);
              if (!tags.any(
                (tag) => TagService.normalizeSlug(tag) == normalizedUrgencyTag,
              )) {
                return false;
              }
            }
            if (importanceTag != null && importanceTag.isNotEmpty) {
              final normalizedImportanceTag = TagService.normalizeSlug(
                importanceTag,
              );
              if (!tags.any(
                (tag) =>
                    TagService.normalizeSlug(tag) == normalizedImportanceTag,
              )) {
                return false;
              }
            }
            
            // 项目筛选（与分页查询逻辑一致）
            if (showNoProject == true) {
              if (entity.projectId != null && entity.projectId!.isNotEmpty) {
                return false;
              }
            } else {
              // 项目ID筛选
              if (projectId != null && projectId.isNotEmpty) {
                if (entity.projectId != projectId) {
                  return false;
                }
                
                // 里程碑ID筛选（仅在指定项目时有效）
                if (milestoneId != null && milestoneId.isNotEmpty) {
                  if (entity.milestoneId != milestoneId) {
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
          })
          .map(_toDomain)
          .toList(growable: false);
      return filtered;
    });
  }

  /// 监听项目列表变化（已废弃）
  @override
  @Deprecated('使用 ProjectRepository 和 ProjectService 替代')
  Stream<List<Task>> watchProjects() {
    throw UnimplementedError(
      'watchProjects 已废弃，请使用 ProjectService.watchActiveProjects()',
    );
  }

  /// 监听轻量任务列表变化
  @override
  Stream<List<Task>> watchQuickTasks() {
    return _watchQuery(() async {
      final entities = await _isar.taskEntitys
          .filter()
          .parentIdIsNull()
          .findAll();
      // 过滤出普通任务且状态为活跃的
      final filtered = entities
          .where(_isRegularTask)
          .where((entity) => _isActiveQuickTaskStatus(entity.status))
          .toList(growable: false);
      filtered.sort((a, b) {
        final aDue =
            a.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000);
        final bDue =
            b.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000);
        final compare = aDue.compareTo(bDue);
        if (compare != 0) {
          return compare;
        }
        return a.createdAt.compareTo(b.createdAt);
      });
      return filtered.map(_toDomain).toList(growable: false);
    });
  }

  /// 监听里程碑任务列表变化（已废弃）
  @override
  @Deprecated('使用 MilestoneRepository 和 MilestoneService 替代')
  Stream<List<Task>> watchMilestones(int projectId) {
    throw UnimplementedError(
      'watchMilestones 已废弃，请使用 MilestoneService.watchMilestones()',
    );
  }

  /// 监听项目任务列表变化
  @override
  Stream<List<Task>> watchTasksByProjectId(String projectId) {
    return _watchQuery(() async {
      final entities = await _isar.taskEntitys
          .filter()
          .projectIdEqualTo(projectId)
          .findAll();
      return entities.map(_toDomain).toList(growable: false);
    });
  }

  /// 监听里程碑任务列表变化
  @override
  Stream<List<Task>> watchTasksByMilestoneId(String milestoneId) {
    return _watchQuery(() async {
      final entities = await _isar.taskEntitys
          .filter()
          .milestoneIdEqualTo(milestoneId)
          .findAll();
      return entities.map(_toDomain).toList(growable: false);
    });
  }

  /// 监听单个任务变化
  @override
  Stream<Task?> watchTaskById(int id) {
    return _watchQuery(() async {
      final entity = await _isar.taskEntitys.get(id);
      return entity != null ? _toDomain(entity) : null;
    });
  }

  /// Stream 查询辅助方法
  /// 
  /// 创建一个 Stream，当数据库变化时自动重新查询并发送新数据
  Stream<T> _watchQuery<T>(Future<T> Function() fetcher) {
    late StreamController<T> controller;
    StreamSubscription<void>? subscription;
    Future<void> emit() async {
      try {
        final value = await fetcher();
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
        subscription = _isar.taskEntitys
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

