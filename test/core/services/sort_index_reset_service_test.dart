import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/sort_index_reset_service.dart';
import 'package:granoflow/data/models/task.dart';
import '../../presentation/test_support/fakes.dart';

void main() {
  group('SortIndexResetService', () {
    late StubTaskRepository taskRepository;
    late SortIndexResetService service;

    setUp(() {
      taskRepository = StubTaskRepository();
      service = SortIndexResetService(taskRepository: taskRepository);
    });

    test('空任务列表时不会出错', () async {
      await expectLater(
        service.resetAllSortIndexes(),
        completes,
      );
    });

    test('根据任务状态和创建时间生成不同的初始 sortIndex', () async {
      final baseDate = DateTime(2024, 1, 1, 10, 0);
      
      // 创建已完成任务（按创建时间顺序）
      final completed1 = await taskRepository.createTaskWithId(
        TaskDraft(
          title: '已完成任务1',
          status: TaskStatus.completedActive,
        ),
        'completed1',
        baseDate,
        baseDate,
      );
      final completed2 = await taskRepository.createTaskWithId(
        TaskDraft(
          title: '已完成任务2',
          status: TaskStatus.completedActive,
        ),
        'completed2',
        baseDate.add(const Duration(hours: 1)),
        baseDate.add(const Duration(hours: 1)),
      );

      // 创建未完成任务（按创建时间顺序）
      final pending1 = await taskRepository.createTaskWithId(
        TaskDraft(
          title: '待办任务1',
          status: TaskStatus.pending,
        ),
        'pending1',
        baseDate.add(const Duration(hours: 2)),
        baseDate.add(const Duration(hours: 2)),
      );
      final pending2 = await taskRepository.createTaskWithId(
        TaskDraft(
          title: '待办任务2',
          status: TaskStatus.pending,
        ),
        'pending2',
        baseDate.add(const Duration(hours: 3)),
        baseDate.add(const Duration(hours: 3)),
      );
      final inbox1 = await taskRepository.createTaskWithId(
        TaskDraft(
          title: '收件箱任务1',
          status: TaskStatus.inbox,
        ),
        'inbox1',
        baseDate.add(const Duration(hours: 4)),
        baseDate.add(const Duration(hours: 4)),
      );

      // 重置 sortIndex
      await service.resetAllSortIndexes();

      // 验证已完成任务的 sortIndex
      final allTasks = await taskRepository.listAll();
      final completed1After = allTasks.firstWhere((t) => t.id == completed1.id);
      final completed2After = allTasks.firstWhere((t) => t.id == completed2.id);
      
      expect(completed1After.sortIndex, -100000.0);
      expect(completed2After.sortIndex, -99000.0); // -100000 + 1000

      // 验证未完成任务的 sortIndex
      final pending1After = allTasks.firstWhere((t) => t.id == pending1.id);
      final pending2After = allTasks.firstWhere((t) => t.id == pending2.id);
      final inbox1After = allTasks.firstWhere((t) => t.id == inbox1.id);
      
      expect(pending1After.sortIndex, 0.0);
      expect(pending2After.sortIndex, 1000.0); // 0 + 1000
      expect(inbox1After.sortIndex, 2000.0); // 0 + 2000

      // 验证已完成任务的 sortIndex 都小于未完成任务的 sortIndex
      final completedTasks = allTasks
          .where((t) => t.status == TaskStatus.completedActive)
          .toList();
      final otherTasks = allTasks
          .where((t) => t.status != TaskStatus.completedActive)
          .toList();

      for (final completed in completedTasks) {
        for (final other in otherTasks) {
          expect(
            completed.sortIndex,
            lessThan(other.sortIndex),
            reason: '已完成任务的 sortIndex 应该小于未完成任务的 sortIndex',
          );
        }
      }
    });

    test('在同一组内按创建时间保持相对顺序', () async {
      final baseDate = DateTime(2024, 1, 1, 10, 0);
      
      // 创建多个已完成任务，创建时间顺序与 id 顺序不同
      final completed3 = await taskRepository.createTaskWithId(
        TaskDraft(
          title: '已完成任务3',
          status: TaskStatus.completedActive,
        ),
        'completed3',
        baseDate.add(const Duration(hours: 2)),
        baseDate.add(const Duration(hours: 2)),
      );
      final completed1 = await taskRepository.createTaskWithId(
        TaskDraft(
          title: '已完成任务1',
          status: TaskStatus.completedActive,
        ),
        'completed1',
        baseDate,
        baseDate,
      );
      final completed2 = await taskRepository.createTaskWithId(
        TaskDraft(
          title: '已完成任务2',
          status: TaskStatus.completedActive,
        ),
        'completed2',
        baseDate.add(const Duration(hours: 1)),
        baseDate.add(const Duration(hours: 1)),
      );

      // 重置 sortIndex
      await service.resetAllSortIndexes();

      // 验证按创建时间排序
      final allTasks = await taskRepository.listAll();
      final completed1After = allTasks.firstWhere((t) => t.id == completed1.id);
      final completed2After = allTasks.firstWhere((t) => t.id == completed2.id);
      final completed3After = allTasks.firstWhere((t) => t.id == completed3.id);
      
      expect(completed1After.sortIndex, lessThan(completed2After.sortIndex));
      expect(completed2After.sortIndex, lessThan(completed3After.sortIndex));
    });

    test('所有任务的 sortIndex 都不相同', () async {
      final baseDate = DateTime(2024, 1, 1, 10, 0);
      
      // 创建多个任务，初始 sortIndex 都相同（模拟种子导入后的情况）
      final tasks = <Task>[];
      for (var i = 0; i < 10; i++) {
        final createdAt = baseDate.add(Duration(hours: i));
        final task = await taskRepository.createTaskWithId(
          TaskDraft(
            title: '任务$i',
            status: i < 5 ? TaskStatus.completedActive : TaskStatus.pending,
            sortIndex: 0.0, // 所有任务初始 sortIndex 都是 0.0
          ),
          'task$i',
          createdAt,
          createdAt,
        );
        tasks.add(task);
      }

      // 重置 sortIndex
      await service.resetAllSortIndexes();

      // 验证所有任务的 sortIndex 都不相同
      final allTasks = await taskRepository.listAll();
      final sortIndexes = allTasks.map((t) => t.sortIndex).toSet();
      expect(sortIndexes.length, allTasks.length);
    });

    test('只有已完成任务时，sortIndex 从 -100000 开始', () async {
      final baseDate = DateTime(2024, 1, 1, 10, 0);
      
      for (var i = 0; i < 3; i++) {
        final createdAt = baseDate.add(Duration(hours: i));
        await taskRepository.createTaskWithId(
          TaskDraft(
            title: '已完成任务$i',
            status: TaskStatus.completedActive,
          ),
          'completed$i',
          createdAt,
          createdAt,
        );
      }

      await service.resetAllSortIndexes();

      final allTasks = await taskRepository.listAll();
      final sortIndexes = allTasks.map((t) => t.sortIndex).toList()..sort();
      
      expect(sortIndexes[0], -100000.0);
      expect(sortIndexes[1], -99000.0);
      expect(sortIndexes[2], -98000.0);
    });

    test('只有未完成任务时，sortIndex 从 0 开始', () async {
      final baseDate = DateTime(2024, 1, 1, 10, 0);
      
      for (var i = 0; i < 3; i++) {
        final createdAt = baseDate.add(Duration(hours: i));
        await taskRepository.createTaskWithId(
          TaskDraft(
            title: '待办任务$i',
            status: TaskStatus.pending,
          ),
          'pending$i',
          createdAt,
          createdAt,
        );
      }

      await service.resetAllSortIndexes();

      final allTasks = await taskRepository.listAll();
      final sortIndexes = allTasks.map((t) => t.sortIndex).toList()..sort();
      
      expect(sortIndexes[0], 0.0);
      expect(sortIndexes[1], 1000.0);
      expect(sortIndexes[2], 2000.0);
    });
  });
}

