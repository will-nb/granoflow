import 'package:flutter/material.dart';
import '../../data/models/task.dart';
import 'task_row_content.dart';

/// 统一的任务卡片内容布局
/// 
/// 包含：
/// - 左侧拖拽指示器（drag_indicator 图标）
/// - 右侧任务内容（TaskRowContent，支持 inline 编辑）
/// 
/// 用于 Inbox 和 Tasks 页面，确保视觉和交互的完全一致性。
/// 
/// 使用方式：
/// ```dart
/// TaskTileContent(task: myTask)
/// ```
class TaskTileContent extends StatelessWidget {
  const TaskTileContent({
    super.key,
    required this.task,
    this.compact = false,
  });

  final Task task;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖拽指示器
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 4),
            child: Icon(
              Icons.drag_indicator,
              color: Colors.grey[400],
              size: 20,
            ),
          ),
          // 任务内容（使用 TaskRowContent 实现 inline 编辑）
          Expanded(
            child: TaskRowContent(
              task: task,
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }
}
