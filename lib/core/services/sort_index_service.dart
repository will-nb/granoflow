import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';

/// 稀疏整数排序（gap-based ranking）服务
/// - 取中值插入；
/// - 无间隙时在插入点附近做局部重排；
/// - 支持整域批量重排（按有序ID列表）。
class SortIndexService {
  SortIndexService({
    required TaskRepository taskRepository,
    DateTime Function()? clock,
  })  : _tasks = taskRepository,
        _clock = clock ?? DateTime.now;

  final TaskRepository _tasks;
  final DateTime Function() _clock;

  // 默认参数
  static const double _step = 1024.0;
  static const double _minGap = 2.0;
  static const int _window = 50;

  /// 直接按域内的有序ID进行重排（标准化）
  Future<void> reorderIds({
    required List<int> orderedIds,
    String? domainKey,
    double start = 1024,
    double step = _step,
  }) async {
    if (orderedIds.isEmpty) return;
    final updates = <int, TaskUpdate>{};
    for (int i = 0; i < orderedIds.length; i++) {
      updates[orderedIds[i]] = TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    await _tasks.batchUpdate(updates);
  }

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

    final section = _sectionOf(before);
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
  Future<void> normalizeSection({
    required TaskSection section,
    double start = 1024,
    double step = _step,
  }) async {
    final tasks = await _tasks.listSectionTasks(section);
    if (tasks.isEmpty) return;
    final ordered = tasks..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
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

  // 已不再使用的方法移除，避免未引用告警

  TaskSection _sectionOf(Task task) {
    final now = _clock();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final dayAfterTomorrowStart = tomorrowStart.add(const Duration(days: 1));
    final nextMondayStart = _getNextMonday(todayStart);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    final due = task.dueAt;
    if (due == null) return TaskSection.later; // 兜底
    if (due.isBefore(todayStart)) return TaskSection.overdue;
    if (due.isBefore(tomorrowStart)) return TaskSection.today;
    if (due.isBefore(dayAfterTomorrowStart)) return TaskSection.tomorrow;
    if (due.isBefore(nextMondayStart)) return TaskSection.thisWeek;
    if (due.isBefore(nextMonthStart)) return TaskSection.thisMonth;
    return TaskSection.later;
  }

  DateTime _getNextMonday(DateTime today) {
    final daysUntilNextMonday = (DateTime.monday - today.weekday + 7) % 7;
    return today.add(Duration(days: daysUntilNextMonday == 0 ? 7 : daysUntilNextMonday));
  }
}


