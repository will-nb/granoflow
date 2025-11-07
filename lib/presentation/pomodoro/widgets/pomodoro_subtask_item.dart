import 'package:flutter/material.dart';

import '../../../data/models/task.dart';

/// 子任务项组件
class PomodoroSubtaskItem extends StatelessWidget {
  const PomodoroSubtaskItem({
    super.key,
    required this.subtask,
    required this.onStartTimer,
  });

  final Task subtask;
  final VoidCallback onStartTimer;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(subtask.title),
      trailing: IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: onStartTimer,
      ),
    );
  }
}

