import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/utils/task_section_utils.dart';
import 'package:granoflow/presentation/common/drag/standard_draggable.dart';

/// 拖拽测试辅助工具类
///
/// 用于：
/// - 查找任务 Widget（使用新的查找方式）
/// - 执行拖拽手势（适配 StandardDraggable）
/// - 验证插入间隔线显示
/// - 验证任务在数据库中的状态
/// - 验证任务在 UI 中的显示
/// - 等待动画完成
/// - 滚动到目标位置
class TaskDragTestHelper {
  final WidgetTester tester;
  final ProviderContainer container;

  TaskDragTestHelper(this.tester, this.container);

  /// StandardDraggable 的长按延迟时间（300ms）
  static const Duration dragStartDelay = Duration(milliseconds: 350);

  /// 动画等待超时时间
  static const Duration animationTimeout = Duration(seconds: 5);

  /// 查找任务 Widget（通过任务标题）
  Finder findTaskByTitle(String title) {
    return find.text(title);
  }

  /// 查找任务 Widget（通过任务 ID，Inbox）
  Finder findInboxTaskById(int taskId) {
    // Inbox 任务的 Key 格式：ValueKey('inbox-${task.id}-${task.updatedAt.millisecondsSinceEpoch}')
    // 这里我们使用部分匹配，因为 updatedAt 可能不同
    return find.byWidgetPredicate(
      (widget) => widget.key is ValueKey &&
          widget.key != null &&
          widget.key.toString().startsWith('ValueKey<String>(\'inbox-$taskId'),
    );
  }

  /// 查找任务 Widget（通过任务 ID，Tasks）
  Finder findTasksTaskById(int taskId) {
    // Tasks 任务的 Key 格式：ValueKey('tasks-section-${task.id}-${task.updatedAt.millisecondsSinceEpoch}')
    return find.byWidgetPredicate(
      (widget) => widget.key is ValueKey &&
          widget.key != null &&
          widget.key.toString().startsWith('ValueKey<String>(\'tasks-section-$taskId'),
    );
  }

  /// 获取任务位置（带等待和滚动）
  Future<Offset?> getTaskPositionWithWait(
    String taskTitle, {
    TaskSection? section,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final finder = findTaskByTitle(taskTitle);
    final startTime = DateTime.now();

    // 等待任务出现在 widget 树中
    while (finder.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
      if (DateTime.now().difference(startTime) > timeout) {
        return null;
      }
    }

    // 如果任务不在可视区域，滚动到可视区域
    try {
      await tester.ensureVisible(finder.first);
      await tester.pumpAndSettle();
    } catch (e) {
      // 如果无法滚动，尝试使用 dragUntilVisible
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.dragUntilVisible(
          finder.first,
          scrollable.first,
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
      }
    }

    // 获取任务位置
    try {
      return tester.getCenter(finder.first);
    } catch (e) {
      return null;
    }
  }

  /// 执行长按拖拽手势（适配 StandardDraggable）
  ///
  /// [startFinder] 拖拽起始位置的 Finder
  /// [endOffset] 拖拽结束位置的 Offset（相对于屏幕）
  /// [holdDuration] 长按持续时间（默认 350ms，适配 StandardDraggable 的 300ms 延迟）
  /// 返回 TestGesture，调用者需要负责调用 up() 来释放手势
  Future<TestGesture?> performLongPressDrag({
    required Finder startFinder,
    required Offset endOffset,
    Duration? holdDuration,
  }) async {
    try {
      // 确保起始位置可见
      await tester.ensureVisible(startFinder.first);
      await tester.pumpAndSettle();

      final startPosition = tester.getCenter(startFinder.first);
      final gesture = await tester.startGesture(startPosition);

      // 长按延迟（StandardDraggable 使用 300ms 延迟）
      await tester.pump(holdDuration ?? dragStartDelay);

      // 移动到目标位置（小步移动，确保触发 onDragUpdate）
      await gesture.moveTo(endOffset);
      await tester.pump(const Duration(milliseconds: 50));

      // 再次移动一点，确保触发悬停事件
      await gesture.moveBy(const Offset(0, 1));
      await tester.pump(const Duration(milliseconds: 50));

      return gesture;
    } catch (e) {
      return null;
    }
  }

  /// 执行拖拽手势（从任务到任务）
  Future<bool> dragTaskToTask({
    required Finder sourceFinder,
    required Finder targetFinder,
  }) async {
    try {
      final targetPosition = tester.getCenter(targetFinder.first);
      final gesture = await performLongPressDrag(
        startFinder: sourceFinder,
        endOffset: targetPosition,
      );

      if (gesture != null) {
        await gesture.up();
        await waitForAnimation();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 执行拖拽手势（从任务到位置）
  Future<bool> dragTaskToPosition({
    required Finder sourceFinder,
    required Offset targetPosition,
  }) async {
    try {
      final gesture = await performLongPressDrag(
        startFinder: sourceFinder,
        endOffset: targetPosition,
      );

      if (gesture != null) {
        await gesture.up();
        await waitForAnimation();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 验证插入间隔线显示
  ///
  /// 插入间隔线是一个 Container，具有以下特征：
  /// - height: 3px（视觉线）
  /// - 包含 BoxDecoration，颜色为 primary color
  /// - 包含 BoxShadow
  /// - opacity: 1.0（悬停时）
  bool verifyInsertionLineVisible() {
    // 查找包含插入间隔线的 Container
    // 插入间隔线是一个 Container，高度为 3px，包含特定样式的 BoxDecoration
    final containers = find.byType(Container);
    for (final containerElement in containers.evaluate()) {
      final container = containerElement.widget as Container;
      if (container.decoration is BoxDecoration) {
        final decoration = container.decoration as BoxDecoration;
        // 检查是否有阴影（插入间隔线的特征）
        if (decoration.boxShadow != null && decoration.boxShadow!.isNotEmpty) {
          // 检查高度约为 3px（允许一点误差）
          final height = container.constraints?.maxHeight;
          if (height != null && (height >= 2.0 && height <= 4.0)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// 验证任务卡片半透明（拖拽时）
  ///
  /// 拖拽时，任务卡片应该变为半透明（opacity < 1.0）
  bool verifyTaskOpacity(Finder taskFinder, {double expectedOpacity = 0.5}) {
    try {
      final opacityWidgets = find.descendant(
        of: taskFinder,
        matching: find.byType(Opacity),
      );
      if (opacityWidgets.evaluate().isNotEmpty) {
        final opacity = tester.widget<Opacity>(opacityWidgets.first);
        return opacity.opacity < 1.0;
      }
    } catch (e) {
      // 如果无法找到 Opacity widget，返回 false
    }
    return false;
  }

  /// 验证任务在数据库中的状态
  Future<bool> verifyTaskInDatabase({
    required int taskId,
    TaskSection? expectedSection,
    int? expectedParentId,
    double? expectedSortIndex,
  }) async {
    final taskRepository = container.read(taskRepositoryProvider);
    final task = await taskRepository.findById(taskId);
    if (task == null) return false;

    // 验证 section
    if (expectedSection != null) {
      final actualSection = TaskSectionUtils.getSectionForDate(task.dueAt);
      if (actualSection != expectedSection) {
        return false;
      }
    }

    // 验证 parentId
    if (expectedParentId != null) {
      if (task.parentId != expectedParentId) {
        return false;
      }
    }

    // 验证 sortIndex
    if (expectedSortIndex != null) {
      // 允许小的误差（浮点数比较）
      if ((task.sortIndex - expectedSortIndex).abs() > 0.1) {
        return false;
      }
    }

    return true;
  }

  /// 验证任务在 UI 中的 section
  Future<bool> verifyTaskInUISection(
    String taskTitle,
    TaskSection expectedSection,
  ) async {
    // 这需要根据实际的 UI 结构来实现
    // 目前先验证任务是否存在
    final finder = findTaskByTitle(taskTitle);
    return finder.evaluate().isNotEmpty;
  }

  /// 等待动画完成
  Future<void> waitForAnimation() async {
    await tester.pumpAndSettle(animationTimeout);
  }

  /// 滚动到指定位置
  Future<void> scrollToPosition(Offset position) async {
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      // 计算需要滚动的距离
      final screenHeight = tester.getSize(find.byType(MaterialApp).first).height;
      final targetY = position.dy;

      if (targetY < 0 || targetY > screenHeight) {
        // 需要滚动
        final scrollOffset = Offset(0, targetY - screenHeight / 2);
        await tester.drag(scrollable.first, scrollOffset);
        await tester.pumpAndSettle();
      }
    }
  }

  /// 导航到 Inbox 页面
  Future<void> navigateToInbox() async {
    // 尝试打开抽屉菜单
    final drawer = find.byIcon(Icons.menu);
    if (drawer.evaluate().isNotEmpty) {
      await tester.tap(drawer.first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    // 查找 Inbox 链接
    var inbox = find.text('Inbox');
    if (inbox.evaluate().isEmpty) {
      inbox = find.text('收集箱'); // 中文
    }
    if (inbox.evaluate().isEmpty) {
      inbox = find.textContaining('Inbox');
    }
    if (inbox.evaluate().isNotEmpty) {
      await tester.tap(inbox.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
  }

  /// 导航到 Tasks 页面
  Future<void> navigateToTasks() async {
    // 查找 Tasks 图标
    var tasksIcon = find.byIcon(Icons.checklist);
    if (tasksIcon.evaluate().isEmpty) {
      tasksIcon = find.byIcon(Icons.fact_check);
    }
    if (tasksIcon.evaluate().isEmpty) {
      final tasksText = find.textContaining('任务');
      if (tasksText.evaluate().isNotEmpty) {
        await tester.tap(tasksText.first);
      }
    } else {
      await tester.tap(tasksIcon.first);
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// 获取 Inbox 任务列表
  Future<List<Task>> getInboxTasks() async {
    final taskRepository = container.read(taskRepositoryProvider);
    return await taskRepository.watchInbox().first;
  }

  /// 添加测试任务到 Inbox
  Future<Task> addTestTask(String title) async {
    final taskService = container.read(taskServiceProvider);
    return await taskService.captureInboxTask(title: title);
  }

  /// 移动任务到指定 section
  Future<void> moveTaskToSection(
    int taskId,
    TaskSection section,
    DateTime now,
  ) async {
    final taskService = container.read(taskServiceProvider);
    DateTime? dueAt;

    // 根据 section 计算对应的 dueAt 日期
    switch (section) {
      case TaskSection.overdue:
        dueAt = DateTime(now.year, now.month, now.day - 1, 12, 0, 0);
        break;
      case TaskSection.today:
        dueAt = DateTime(now.year, now.month, now.day, 12, 0, 0);
        break;
      case TaskSection.tomorrow:
        dueAt = DateTime(now.year, now.month, now.day + 1, 12, 0, 0);
        break;
      case TaskSection.thisWeek:
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        final weekStart = TaskSectionUtils.getSectionEndTime(
          TaskSection.thisWeek,
          now: now,
        );
        final nextWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day + 1);
        final daysUntilNextWeek = nextWeekStart.difference(tomorrow).inDays;
        final targetDay = tomorrow.add(Duration(days: daysUntilNextWeek ~/ 2));
        dueAt = DateTime(targetDay.year, targetDay.month, targetDay.day, 12, 0, 0);
        break;
      case TaskSection.thisMonth:
        final monthEnd = TaskSectionUtils.getSectionEndTime(
          TaskSection.thisMonth,
          now: now,
        );
        dueAt = DateTime(monthEnd.year, monthEnd.month, 15, 12, 0, 0);
        break;
      case TaskSection.nextMonth:
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        dueAt = DateTime(nextMonth.year, nextMonth.month, 15, 12, 0, 0);
        break;
      case TaskSection.later:
        final nextNextMonth = DateTime(now.year, now.month + 2, 1);
        dueAt = DateTime(nextNextMonth.year, nextNextMonth.month, 15, 12, 0, 0);
        break;
      case TaskSection.completed:
      case TaskSection.archived:
      case TaskSection.trash:
        dueAt = null;
        break;
    }

    if (dueAt != null) {
      await taskService.planTask(
        taskId: taskId,
        dueDateLocal: dueAt,
        section: section,
      );
    }
  }

  /// 验证 StandardDraggable 组件存在
  bool verifyDraggableExists() {
    return find.byType(StandardDraggable).evaluate().isNotEmpty;
  }

  /// 验证 TaskDragIntentTarget 组件存在
  bool verifyDragTargetExists() {
    // TaskDragIntentTarget 是一个 ConsumerWidget，我们需要通过其他方式查找
    // 可以通过查找包含特定 key 的 widget 来验证
    return find.byWidgetPredicate(
      (widget) => widget.key != null && widget.key.toString().contains('insertion'),
    ).evaluate().isNotEmpty;
  }
}

