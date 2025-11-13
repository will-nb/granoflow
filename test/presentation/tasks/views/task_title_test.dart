import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/tasks/views/task_title.dart';

Task _createTask() {
  return Task(
    id: '1',

    title: 'Sample Task',
    status: TaskStatus.pending,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    tags: const [],
    templateLockCount: 0,
    allowInstantComplete: false,
    logs: const [],
  );
}

void main() {
  testWidgets('TaskTitle applies highlight style when requested', (
    tester,
  ) async {
    final task = _createTask();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TaskTitle(task: task, depth: 1, highlight: true)),
      ),
    );

    final textWidget = tester.widget<Text>(find.text('Sample Task'));
    expect(textWidget.style?.fontWeight, FontWeight.w400);
  });
}
