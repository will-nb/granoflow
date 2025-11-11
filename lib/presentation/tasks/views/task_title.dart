import 'package:flutter/material.dart';
import '../../../data/models/task.dart';

class TaskTitle extends StatelessWidget {
  const TaskTitle({
    super.key,
    required this.task,
    required this.depth,
    this.highlight = false,
  });

  final Task task;
  final int depth;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = highlight
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400)
        : theme.textTheme.bodyLarge;
    return Padding(
      padding: EdgeInsets.only(left: depth * 12),
      child: Text(
        task.title,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

