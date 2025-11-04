import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../utils/task_section_utils.dart';
import 'sort_index_service_reorder.dart';
import 'sort_index_service_sorting.dart';

/// 稀疏整数排序（gap-based ranking）服务
/// - 取中值插入；
/// - 无间隙时在插入点附近做局部重排；
/// - 支持整域批量重排（按有序ID列表）。
/// - 统一管理任务排序规则和 sortIndex 修改逻辑
class SortIndexService {
  SortIndexService({
    required TaskRepository taskRepository,
    DateTime Function()? clock,
  })  : _tasks = taskRepository,
        _clock = clock ?? DateTime.now,
        _reorder = SortIndexServiceReorder(taskRepository: taskRepository);

  final TaskRepository _tasks;
  final DateTime Function() _clock;
  final SortIndexServiceReorder _reorder;

  // 默认参数
  static const double _step = 1024.0;
  static const double _minGap = 2.0;
  static const int _window = 50;

  // ===== 排序方法（静态方法，纯函数，不依赖服务状态） =====

  /// 对任务列表进行排序（Inbox页面）
  ///
  /// [tasks] 要排序的任务列表（会被原地修改）
  static void sortTasksForInbox(List<Task> tasks) {
    SortIndexServiceSorting.sortTasksForInbox(tasks);
  }

  /// 对任务列表进行排序（Tasks页面）
  ///
  /// [tasks] 要排序的任务列表（会被原地修改）
  static void sortTasksForTasksPage(List<Task> tasks) {
    SortIndexServiceSorting.sortTasksForTasksPage(tasks);
  }

  /// 对子任务列表进行排序
  ///
  /// [tasks] 要排序的子任务列表（会被原地修改）
  static void sortChildrenTasks(List<Task> tasks) {
    SortIndexServiceSorting.sortChildrenTasks(tasks);
  }

  /// 直接按域内的有序ID进行重排（标准化）
  ///
  /// [orderedIds] 已排序的任务ID列表
  Future<void> reorderIds({
    required List<int> orderedIds,
    String? domainKey,
    double start = 1024,
    double step = _step,
  }) =>
      _reorder.reorderIds(
        orderedIds: orderedIds,
        domainKey: domainKey,
        start: start,
        step: step,
      );

  /// 按任务列表排序并重排（Inbox页面）
  ///
  /// 接收任务列表，使用统一的排序规则排序后，批量更新 sortIndex
  Future<void> reorderTasksForInbox({
    required List<Task> tasks,
    double start = 1024,
    double step = _step,
  }) =>
      _reorder.reorderTasksForInbox(
        tasks: tasks,
        start: start,
        step: step,
      );

  /// 按任务列表排序并重排（Tasks页面）
  ///
  /// 接收任务列表，使用统一的排序规则排序后，批量更新 sortIndex
  Future<void> reorderTasksForTasksPage({
    required List<Task> tasks,
    double start = 1024,
    double step = _step,
  }) =>
      _reorder.reorderTasksForTasksPage(
        tasks: tasks,
        start: start,
        step: step,
      );

  /// 批量重排子任务的sortIndex
  ///
  /// 接收子任务列表，使用统一的排序规则排序后，批量更新 sortIndex
  /// 用于父任务内的子任务重排序
  ///
  /// [children] 子任务列表
  /// [start] 起始 sortIndex 值
  /// [step] sortIndex 间隔
  Future<void> reorderChildrenTasks({
    required List<Task> children,
    double start = 1024,
    double step = _step,
  }) =>
      _reorder.reorderChildrenTasks(
        children: children,
        start: start,
        step: step,
      );

  /// 按日期分组批量重排同一天的任务（Tasks页面）
  ///
  /// 从任务列表中筛选出与目标日期同一天的任务，按统一排序规则排序后批量更新 sortIndex
  /// 用于Tasks页面中，当任务移动后，只重排同一天内的任务
  ///
  /// [allTasks] 所有任务列表（用于筛选）
  /// [targetDate] 目标日期（只比较日期部分，忽略时分秒）
  /// [start] 起始 sortIndex 值
  /// [step] sortIndex 间隔
  Future<void> reorderTasksForSameDate({
    required List<Task> allTasks,
    required DateTime? targetDate,
    double start = 1024,
    double step = _step,
  }) =>
      _reorder.reorderTasksForSameDate(
        allTasks: allTasks,
        targetDate: targetDate,
        start: start,
        step: step,
      );

  /// 插入到相邻任务之间；必要时做局部重排
  Future<void> insertBetween({
    required int draggedId,
    required int beforeId,
    required int afterId,
    String? domainKey,
    int window = _window,
    double step = _step,
  }) async {
    final before = await _tasks.findById(beforeId);
    final after = await _tasks.findById(afterId);
    if (before == null || after == null) {
      throw StateError('Task not found');
    }

    // 使用 TaskSectionUtils 统一边界定义（严禁修改）
    final section = TaskSectionUtils.getSectionForDate(before.dueAt, now: _clock());
    double left = before.sortIndex;
    double right = after.sortIndex;

    if ((right - left) < _minGap) {
      // 在插入点附近做局部等差重排
      await _reindexAround(
        section: section,
        anchorBeforeId: beforeId,
        anchorAfterId: afterId,
        window: window,
        step: step,
      );
      final b2 = await _tasks.findById(beforeId);
      final a2 = await _tasks.findById(afterId);
      if (b2 == null || a2 == null) {
        throw StateError('Task not found after reindex');
      }
      left = b2.sortIndex;
      right = a2.sortIndex;
    }

    final newIndex = ((left + right) / 2).floorToDouble();
    await _tasks.updateTask(draggedId, TaskUpdate(sortIndex: newIndex));
  }

  /// 移动到区域头部
  Future<void> moveToHead({
    required int draggedId,
    required TaskSection section,
    required int firstId,
    int window = _window,
    double step = _step,
  }) async {
    final first = await _tasks.findById(firstId);
    final dragged = await _tasks.findById(draggedId);
    if (first == null || dragged == null) {
      // 区域为空或首元素缺失，赋默认
      await _tasks.updateTask(draggedId, const TaskUpdate(sortIndex: 1024));
      return;
    }
    // 若 first 与 dragged sortIndex 相等或非常接近，先规范化该区再计算
    if ((first.sortIndex - dragged.sortIndex).abs() < _minGap) {
      await normalizeSection(section: section);
      final f2 = await _tasks.findById(firstId);
      final head2 = (f2?.sortIndex ?? 1024.0) - step;
      await _tasks.updateTask(draggedId, TaskUpdate(sortIndex: head2));
      return;
    }
    final headCandidate = first.sortIndex - step;
    await _tasks.updateTask(draggedId, TaskUpdate(sortIndex: headCandidate));
  }

  /// 移动到区域尾部
  Future<void> moveToTail({
    required int draggedId,
    required TaskSection section,
    required int lastId,
    double step = _step,
  }) async {
    final last = await _tasks.findById(lastId);
    final dragged = await _tasks.findById(draggedId);
    if (last == null || dragged == null) {
      await _tasks.updateTask(draggedId, const TaskUpdate(sortIndex: 1024));
      return;
    }
    // 若 last 与 dragged sortIndex 相等或非常接近，先规范化该区再计算
    if ((last.sortIndex - dragged.sortIndex).abs() < _minGap) {
      await normalizeSection(section: section);
      final last2 = await _tasks.findById(lastId);
      final tail2 = (last2?.sortIndex ?? 1024.0) + step;
      await _tasks.updateTask(draggedId, TaskUpdate(sortIndex: tail2));
      return;
    }
    final tail = last.sortIndex + step;
    await _tasks.updateTask(draggedId, TaskUpdate(sortIndex: tail));
  }

  /// 对一个区域做规范化（按当前顺序等差赋值）
  ///
  /// 使用统一的排序规则：Tasks页面使用 dueAt升序 → sortIndex升序 → createdAt降序
  Future<void> normalizeSection({
    required TaskSection section,
    double start = 1024,
    double step = _step,
  }) async {
    final tasks = await _tasks.listSectionTasks(section);
    if (tasks.isEmpty) return;
    // 使用统一的排序函数：Tasks页面的排序规则
    final ordered = List<Task>.from(tasks);
    sortTasksForTasksPage(ordered);
    final updates = <int, TaskUpdate>{};
    for (int i = 0; i < ordered.length; i++) {
      updates[ordered[i].id] = TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    await _tasks.batchUpdate(updates);
  }

  // —— 内部实现 ——

  Future<void> _reindexAround({
    required TaskSection section,
    required int anchorBeforeId,
    required int anchorAfterId,
    required int window,
    required double step,
  }) async {
    final tasks = await _tasks.listSectionTasks(section);
    if (tasks.isEmpty) return;
    final idxBefore = tasks.indexWhere((t) => t.id == anchorBeforeId);
    final idxAfter = tasks.indexWhere((t) => t.id == anchorAfterId);
    if (idxBefore == -1 || idxAfter == -1) return;

    final start = (idxBefore - window).clamp(0, tasks.length - 1);
    final end = (idxAfter + window).clamp(0, tasks.length - 1);
    final updates = <int, TaskUpdate>{};
    double base = 1024.0;
    for (int i = start; i <= end; i++) {
      updates[tasks[i].id] = TaskUpdate(sortIndex: base);
      base += step;
    }
    await _tasks.batchUpdate(updates);
  }
}
