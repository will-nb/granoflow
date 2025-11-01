import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';

/// 层级工具函数
///
/// 提供任务层级相关的纯函数逻辑，包括：
/// - 循环引用检查
/// - 层级深度计算
/// - 项目和里程碑过滤
/// - 祖先任务链构建

/// 检查是否可以将任务设置为目标父任务的子任务（避免循环引用）
///
/// [task] 要移动的任务
/// [targetParentId] 目标父任务的 ID
/// [repository] 任务仓库，用于查询任务信息
///
/// 返回 true 如果存在循环引用，不能设置为子任务
/// 返回 false 如果不存在循环引用，可以设置为子任务
Future<bool> hasCircularReference(
  Task task,
  int targetParentId,
  TaskRepository repository,
) async {
  // 不能将任务设置为自己的子任务
  if (task.id == targetParentId) {
    return true; // 存在循环引用
  }

  // 递归检查：目标父任务是否是当前任务的后代（descendant）
  // 即：检查 targetParentId 的所有祖先中是否包含 task.id
  int? currentParentId = targetParentId;
  int depth = 0;
  const maxDepth = 10; // 防止无限循环的保护措施

  while (currentParentId != null && depth < maxDepth) {
    final targetParent = await repository.findById(currentParentId);
    if (targetParent == null) {
      break;
    }

    // 如果目标父任务就是当前任务，说明存在循环引用
    if (targetParent.id == task.id) {
      return true; // 存在循环引用
    }

    currentParentId = targetParent.parentId;
    depth++;
  }

  return false; // 不存在循环引用
}

/// 计算任务的层级深度（同步版本，使用任务映射）
///
/// [task] 要计算深度的任务
/// [taskMap] 任务 ID 到任务的映射（已查询好的任务列表）
///
/// 返回任务的层级深度（从0开始，根任务为0）
/// 最多支持3级（不含里程碑和项目）
/// 项目和里程碑不计入层级深度
///
/// 如果任务映射中缺少父任务信息，会返回已计算的深度
int calculateTaskDepthSync(Task task, Map<int, Task> taskMap) {
  if (task.parentId == null) {
    return 0;
  }

  int depth = 0;
  int? currentParentId = task.parentId;
  const maxDepth = 10; // 防止无限循环的保护措施

  while (currentParentId != null && depth < maxDepth) {
    final parent = taskMap[currentParentId];
    if (parent == null) {
      // 如果任务映射中找不到父任务，返回已计算的深度
      break;
    }

    // 项目和里程碑不计入层级深度
    if (parent.taskKind == TaskKind.project ||
        parent.taskKind == TaskKind.milestone) {
      currentParentId = parent.parentId;
      continue;
    }

    depth++;
    currentParentId = parent.parentId;
  }

  return depth;
}

/// 计算任务的层级深度
///
/// [task] 要计算深度的任务
/// [repository] 任务仓库，用于查询父任务
///
/// 返回任务的层级深度（从0开始，根任务为0）
/// 最多支持3级（不含里程碑和项目）
/// 项目和里程碑不计入层级深度
Future<int> calculateHierarchyDepth(
  Task task,
  TaskRepository repository,
) async {
  if (task.parentId == null) {
    return 0;
  }

  int depth = 0;
  int? currentParentId = task.parentId;
  const maxDepth = 10; // 防止无限循环的保护措施

  while (currentParentId != null && depth < maxDepth) {
    final parent = await repository.findById(currentParentId);
    if (parent == null) {
      break;
    }

    // 项目和里程碑不计入层级深度
    if (parent.taskKind == TaskKind.project ||
        parent.taskKind == TaskKind.milestone) {
      currentParentId = parent.parentId;
      continue;
    }

    depth++;
    currentParentId = parent.parentId;
  }

  return depth;
}

/// 计算任务子树的最大深度（从该任务自身算起，叶子=1）
/// - 仅统计普通任务（排除项目/里程碑）
/// - trashed 节点在仓库层已过滤
Future<int> calculateSubtreeDepth(Task root, TaskRepository repository) async {
  // 项目/里程碑不计入层级深度：返回其普通子树的最大深度
  if (isProjectOrMilestone(root)) {
    final children = await repository.listChildren(root.id);
    if (children.isEmpty) return 0;
    int maxDepth = 0;
    for (final child in children) {
      final d = await calculateSubtreeDepth(child, repository);
      if (d > maxDepth) maxDepth = d;
    }
    return maxDepth;
  }

  final children = await repository.listChildren(root.id);
  final normalChildren = children
      .where((c) => !isProjectOrMilestone(c))
      .toList();
  if (normalChildren.isEmpty) return 1; // 自身算1层

  int maxDepth = 0;
  for (final child in normalChildren) {
    final d = await calculateSubtreeDepth(child, repository);
    if (d > maxDepth) maxDepth = d;
  }
  return 1 + maxDepth;
}

/// 检查任务是否是项目或里程碑
///
/// [task] 要检查的任务
///
/// 返回 true 如果任务是项目或里程碑
bool isProjectOrMilestone(Task task) {
  return task.taskKind == TaskKind.project ||
      task.taskKind == TaskKind.milestone;
}

/// 构建任务的祖先任务链（向上递归查找）
///
/// [taskId] 起始任务 ID
/// [repository] 任务仓库，用于查询任务
///
/// 返回祖先任务列表（从最远的祖先到最近的父任务）
/// 最多3级（不含里程碑和项目）
/// 排除项目和里程碑类型的父任务
Future<List<Task>> buildAncestorChain(
  int taskId,
  TaskRepository repository,
) async {
  final ancestors = <Task>[];
  int? currentParentId = await repository
      .findById(taskId)
      .then((task) => task?.parentId);
  const maxDepth = 10; // 防止无限循环的保护措施
  int depth = 0;

  while (currentParentId != null && depth < maxDepth) {
    final parent = await repository.findById(currentParentId);
    if (parent == null) {
      break;
    }

    // 排除项目和里程碑
    if (parent.taskKind == TaskKind.project ||
        parent.taskKind == TaskKind.milestone) {
      currentParentId = parent.parentId;
      continue;
    }

    ancestors.add(parent);
    currentParentId = parent.parentId;
    depth++;

    // 最多3级
    if (depth >= 3) {
      break;
    }
  }

  // 反转列表，使最远的祖先在最后（符合显示顺序：祖任务→父任务→当前任务）
  return ancestors.reversed.toList();
}

/// 检查任务是否可以接受子任务
///
/// [task] 要检查的任务
///
/// 返回 true 如果任务可以接受子任务（未被锁定且不是项目/里程碑）
bool canAcceptChildren(Task task) {
  // 业务约束：项目/里程碑不可作为父任务；且需可编辑结构
  if (isProjectOrMilestone(task)) return false;
  return task.canEditStructure;
}

/// 检查任务是否可以移动（成为其他任务的子任务）
///
/// [task] 要检查的任务
///
/// 返回 true 如果任务可以移动（未被锁定）
bool canMoveTask(Task task) {
  return task.canEditStructure;
}

/// 计算任务的层级（level 1/2/3）
///
/// level 1: 根任务（parentId 是 null/里程碑/project）
/// level 2: 二级任务
/// level 3: 三级任务
///
/// [task] 要计算层级的任务
/// [taskMap] 任务 ID 到任务的映射（用于查找父任务）
/// 返回任务的层级（1-3）
int getTaskLevel(Task task, Map<int, Task> taskMap) {
  return calculateTaskDepthSync(task, taskMap) + 1;
}
