part of 'task_repository.dart';

// ignore_for_file: override_on_non_overriding_member

/// TaskRepository 变更方法 mixin - 移动操作
/// 
/// 包含任务移动相关的方法
/// 
/// 依赖：
/// - TaskRepositoryHelpers: 提供基础辅助方法
/// - TaskRepositorySectionQueries: 提供区域查询方法
/// - TaskRepositoryTaskHierarchy: 提供任务层级方法
/// - TaskRepositoryMutationsStatus: 提供 updateTask 方法
mixin TaskRepositoryMutationsMove
    on TaskRepositoryHelpers,
        TaskRepositorySectionQueries,
        TaskRepositoryTaskHierarchy,
        TaskRepositoryMutationsStatus {
  /// 移动任务到指定位置
  @override
  Future<void> moveTask({
    required int taskId,
    required int? targetParentId,
    required TaskSection targetSection,
    required double sortIndex,
    DateTime? dueAt,
  }) async {
    // 通过 updateTask 统一处理，显式指定 status 确保状态根据 section 正确设置
    // 显式指定的 status 优先级高于自动状态转换逻辑
    final status = _sectionToStatus(targetSection);
    await updateTask(
      taskId,
      TaskUpdate(
        parentId: targetParentId,
        parentTaskId: targetParentId,
        clearParent:
            targetParentId == null, // 如果 targetParentId 为 null，清空 parentId
        status: status,
        sortIndex: sortIndex,
        dueAt: dueAt,
      ),
    );
  }
}

