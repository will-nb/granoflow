import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../presentation/tasks/utils/hierarchy_utils.dart';
import '../constants/task_constants.dart';
import 'metric_orchestrator.dart';

class TaskHierarchyService {
  TaskHierarchyService({
    required TaskRepository taskRepository,
    required MetricOrchestrator metricOrchestrator,
  }) : _tasks = taskRepository,
       _metricOrchestrator = metricOrchestrator;

  final TaskRepository _tasks;
  final MetricOrchestrator _metricOrchestrator;

  Future<void> reorderWithinSection({
    required int taskId,
    required double targetIndex,
    required TaskSection section,
  }) async {
    await _tasks.moveTask(
      taskId: taskId,
      targetParentId: null,
      targetSection: section,
      sortIndex: targetIndex,
    );
  }

  Future<void> moveToParent({
    required int taskId,
    required int? parentId,
    required double sortIndex,
  }) async {
    final task = await _tasks.findById(taskId);
    if (task == null) return;
    
    // 验证锁定状态：被拖拽的任务是否被锁定
    if (!canMoveTask(task)) {
      throw StateError('Task is locked and cannot be moved.');
    }
    
    Task? parent;
    if (parentId != null) {
      parent = await _tasks.findById(parentId);
      if (parent == null) {
        throw StateError('Parent task $parentId not found.');
      }
      
      // 验证锁定状态：目标父任务是否可以接受子任务
      if (!canAcceptChildren(parent)) {
        throw StateError('Parent task is locked; cannot add children.');
      }
      
      // 验证循环引用
      if (await hasCircularReference(task, parentId, _tasks)) {
        throw StateError('Cannot move task to its own descendant.');
      }
      
      // 验证层级深度限制（最多3级，不含里程碑和项目）
      final currentDepth = await calculateHierarchyDepth(task, _tasks);
      if (currentDepth >= 3) {
        throw StateError('Task hierarchy depth limit (3 levels) exceeded.');
      }
    }
    
    await _tasks.updateTask(
      taskId,
      TaskUpdate(
        parentId: parentId,
        sortIndex: sortIndex,
        clearParent: parentId == null ? true : null,
      ),
    );
  }
  
  /// 计算将任务移动到父任务下的合适 sortIndex
  /// 
  /// 如果父任务已有子任务，插入到第一个子任务之前；
  /// 否则使用默认值
  Future<double> calculateSortIndexForNewChild(int parentId) async {
    final children = await _tasks.listChildren(parentId);
    
    if (children.isEmpty) {
      return TaskConstants.DEFAULT_SORT_INDEX;
    }
    
    // 插入到第一个子任务之前
    final firstChildSortIndex = children.first.sortIndex;
    final newSortIndex = (firstChildSortIndex - 1024.0).clamp(
      TaskConstants.DEFAULT_SORT_INDEX - 10000.0,
      TaskConstants.DEFAULT_SORT_INDEX,
    );
    
    return newSortIndex;
  }

  Future<void> moveAcrossSections({
    required int taskId,
    required TaskSection section,
    required double sortIndex,
    required DateTime dueDateLocal,
  }) async {
    final normalized = DateTime(
      dueDateLocal.year,
      dueDateLocal.month,
      dueDateLocal.day,
      23,
      59,
      59,
    );
    await _tasks.moveTask(
      taskId: taskId,
      targetParentId: null,
      targetSection: section,
      sortIndex: sortIndex,
      dueAt: normalized,
    );
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }
}
