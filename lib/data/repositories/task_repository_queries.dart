part of 'task_repository.dart';

// ignore_for_file: override_on_non_overriding_member
// 这些方法实现抽象类 TaskRepository 中定义的方法，@override 注解是正确的
// analyzer 无法正确识别 part of 文件中的 override 关系

/// TaskRepository 查询方法 mixin
/// 
/// 包含所有查询方法，如 findById、listRoots、listChildren 等
/// 
/// 依赖：
/// - TaskRepositoryHelpers: 提供基础辅助方法
/// - TaskRepositorySectionQueries: 提供区域查询方法
mixin TaskRepositoryQueries
    on TaskRepositoryHelpers, TaskRepositorySectionQueries {
  /// 查询单个任务（通过 ID）
  @override
  Future<Task?> findById(int id) async {
    final entity = await _isar.taskEntitys.get(id);
    return entity == null ? null : _toDomain(entity);
  }

  /// 通过 slug 查询任务
  @override
  Future<Task?> findBySlug(String slug) async {
    final entity = await _isar.taskEntitys
        .filter()
        .seedSlugEqualTo(slug)
        .findFirst();
    return entity == null ? null : _toDomain(entity);
  }

  /// 列出所有根任务
  @override
  Future<List<Task>> listRoots() async {
    final roots = await _isar.taskEntitys
        .filter()
        .parentIdIsNull()
        .sortBySortIndex()
        .thenByCreatedAtDesc()
        .findAll();
    // 过滤出普通任务（没有关联项目或里程碑）
    return roots
        .where(_isRegularTask)
        .map(_toDomain)
        .toList(growable: false);
  }

  /// 列出父任务的所有子任务（排除 trashed 状态）
  @override
  Future<List<Task>> listChildren(int parentId) async {
    final children = await _isar.taskEntitys
        .filter()
        .parentIdEqualTo(parentId)
        .sortBySortIndex()
        .thenByCreatedAtDesc()
        .findAll();
    // 过滤掉 trashed 状态的任务和里程碑（里程碑只能在项目详情页显示）
    return children
        .where(
          (entity) =>
              entity.status != TaskStatus.trashed &&
              entity.milestoneId == null, // 排除里程碑
        )
        .map(_toDomain)
        .toList(growable: false);
  }

  /// 列出父任务的所有子任务（包括 trashed 状态）
  /// 用于在父任务展开时显示已删除的子任务
  @override
  Future<List<Task>> listChildrenIncludingTrashed(int parentId) async {
    final children = await _isar.taskEntitys
        .filter()
        .parentIdEqualTo(parentId)
        .sortBySortIndex()
        .thenByCreatedAtDesc()
        .findAll();
    // 只排除里程碑（里程碑只能在项目详情页显示），包含 trashed 状态的任务
    return children
        .where(
          (entity) => entity.milestoneId == null, // 排除里程碑
        )
        .map(_toDomain)
        .toList(growable: false);
  }

  /// 列出所有任务
  @override
  Future<List<Task>> listAll() async {
    final records = await _isar.taskEntitys.where().findAll();
    return records.map(_toDomain).toList(growable: false);
  }

  /// 按标题搜索任务
  @override
  Future<List<Task>> searchByTitle(
    String query, {
    TaskStatus? status,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      return const <Task>[];
    }
    QueryBuilder<TaskEntity, TaskEntity, QAfterFilterCondition> builder = _isar
        .taskEntitys
        .filter()
        .titleContains(query, caseSensitive: false);
    if (status != null) {
      builder = builder.statusEqualTo(status);
    }
    final results = await builder.sortByUpdatedAtDesc().findAll();
    // 过滤出普通任务（没有关联项目或里程碑）
    final regularTasks = results
        .where(_isRegularTask)
        .take(limit)
        .map(_toDomain)
        .toList(growable: false);
    return regularTasks;
  }

  /// 列出某个区域内用于排序的任务（与 UI 一致，已排序的叶任务）
  @override
  Future<List<Task>> listSectionTasks(TaskSection section) async {
    // 复用 _fetchSection（已是叶任务，并按 sortIndex 排序）
    return _fetchSection(section);
  }

  /// 列出指定里程碑的任务
  @override
  Future<List<Task>> listTasksByMilestoneId(String milestoneId) async {
    final entities = await _isar.taskEntitys
        .filter()
        .milestoneIdEqualTo(milestoneId)
        .findAll();
    return entities.map(_toDomain).toList(growable: false);
  }
}

