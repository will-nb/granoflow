import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import '../../presentation/test_support/fakes.dart';

void main() {
  group('TaskRepository Completion Time Trigger Tests', () {
    late StubTaskRepository repository;
    late DateTime fixedNow;

    setUp(() {
      fixedNow = DateTime(2025, 1, 1, 12, 0, 0);
      repository = StubTaskRepository();
      repository.setClock(() => fixedNow);
    });

    test('updateTask should automatically set endedAt when status changes to completedActive', () async {
      // 创建待处理状态的任务
      final task = await repository.createTask(
        TaskDraft(
          title: 'Test Task',
          status: TaskStatus.pending,
          dueAt: DateTime(2025, 1, 2),
        ),
      );
      
      expect(task.endedAt, isNull, reason: '初始任务不应该有完成时间');
      
      // 更新状态为完成，但不指定 endedAt
      await repository.updateTask(
        task.id,
        TaskUpdate(status: TaskStatus.completedActive),
      );
      
      // 验证 endedAt 已自动设置
      final updated = await repository.findById(task.id);
      expect(updated, isNotNull);
      expect(updated!.status, TaskStatus.completedActive);
      expect(updated.endedAt, isNotNull, reason: '状态变为完成时应该自动记录完成时间');
      expect(updated.endedAt, equals(fixedNow), reason: '完成时间应该是当前时间');
    });

    test('updateTask should not override explicit endedAt when status changes to completedActive', () async {
      // 创建待处理状态的任务
      final task = await repository.createTask(
        TaskDraft(
          title: 'Test Task',
          status: TaskStatus.pending,
        ),
      );
      
      final explicitEndedAt = DateTime(2025, 1, 1, 10, 0, 0);
      
      // 更新状态为完成，同时显式指定 endedAt
      await repository.updateTask(
        task.id,
        TaskUpdate(
          status: TaskStatus.completedActive,
          endedAt: explicitEndedAt,
        ),
      );
      
      // 验证使用显式指定的 endedAt
      final updated = await repository.findById(task.id);
      expect(updated, isNotNull);
      expect(updated!.status, TaskStatus.completedActive);
      expect(updated.endedAt, equals(explicitEndedAt), reason: '应该使用显式指定的完成时间');
    });

    test('updateTask should not set endedAt when status is already completedActive', () async {
      // 创建已完成状态的任务（已有 endedAt）
      final existingEndedAt = DateTime(2025, 1, 1, 8, 0, 0);
      final task = await repository.createTask(
        TaskDraft(
          title: 'Completed Task',
          status: TaskStatus.completedActive,
        ),
      );
      
      // 先手动设置 endedAt
      await repository.updateTask(
        task.id,
        TaskUpdate(endedAt: existingEndedAt),
      );
      
      // 再次更新任务（例如更新标题），状态保持为 completedActive
      await repository.updateTask(
        task.id,
        TaskUpdate(title: 'Updated Title'),
      );
      
      // 验证 endedAt 保持不变
      final updated = await repository.findById(task.id);
      expect(updated, isNotNull);
      expect(updated!.status, TaskStatus.completedActive);
      expect(updated.endedAt, equals(existingEndedAt), reason: '已完成任务的结束时间不应被覆盖');
    });

    test('markStatus should automatically set endedAt when status changes to completedActive', () async {
      // 创建待处理状态的任务
      final task = await repository.createTask(
        TaskDraft(
          title: 'Test Task',
          status: TaskStatus.pending,
        ),
      );
      
      expect(task.endedAt, isNull);
      
      // 使用 markStatus 将状态改为完成
      await repository.markStatus(
        taskId: task.id,
        status: TaskStatus.completedActive,
      );
      
      // 验证 endedAt 已自动设置
      final updated = await repository.findById(task.id);
      expect(updated, isNotNull);
      expect(updated!.status, TaskStatus.completedActive);
      expect(updated.endedAt, isNotNull, reason: 'markStatus 状态变为完成时应该自动记录完成时间');
      expect(updated.endedAt, equals(fixedNow), reason: '完成时间应该是当前时间');
    });

    test('markStatus should not set endedAt when status is already completedActive', () async {
      // 创建已完成状态的任务
      final existingEndedAt = DateTime(2025, 1, 1, 8, 0, 0);
      final task = await repository.createTask(
        TaskDraft(
          title: 'Completed Task',
          status: TaskStatus.completedActive,
        ),
      );
      
      // 先手动设置 endedAt
      await repository.updateTask(
        task.id,
        TaskUpdate(endedAt: existingEndedAt),
      );
      
      // 再次调用 markStatus，状态保持为 completedActive
      await repository.markStatus(
        taskId: task.id,
        status: TaskStatus.completedActive,
      );
      
      // 验证 endedAt 保持不变
      final updated = await repository.findById(task.id);
      expect(updated, isNotNull);
      expect(updated!.status, TaskStatus.completedActive);
      expect(updated.endedAt, equals(existingEndedAt), reason: '已完成任务的结束时间不应被覆盖');
    });

    test('batchUpdate should automatically set endedAt for multiple tasks', () async {
      // 创建多个待处理状态的任务
      final task1 = await repository.createTask(
        TaskDraft(title: 'Task 1', status: TaskStatus.pending),
      );
      final task2 = await repository.createTask(
        TaskDraft(title: 'Task 2', status: TaskStatus.doing),
      );
      
      // 批量更新状态为完成
      await repository.batchUpdate(<String, TaskUpdate>{
        task1.id: TaskUpdate(status: TaskStatus.completedActive),
        task2.id: TaskUpdate(status: TaskStatus.completedActive),
      });
      
      // 验证所有任务的 endedAt 都已自动设置
      final updated1 = await repository.findById(task1.id);
      final updated2 = await repository.findById(task2.id);
      
      expect(updated1, isNotNull);
      expect(updated1!.status, TaskStatus.completedActive);
      expect(updated1.endedAt, isNotNull);
      expect(updated1.endedAt, equals(fixedNow));
      
      expect(updated2, isNotNull);
      expect(updated2!.status, TaskStatus.completedActive);
      expect(updated2.endedAt, isNotNull);
      expect(updated2.endedAt, equals(fixedNow));
    });
  });
}

