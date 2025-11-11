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
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        subtask.title,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: onStartTimer,
      ),
    );
  }
}

