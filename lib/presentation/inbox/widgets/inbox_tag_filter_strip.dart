import 'package:flutter/material.dart';
import '../../widgets/task_tag_filter_strip.dart';
import '../../../core/providers/app_providers.dart';

/// Inbox标签筛选条组件（向后兼容）
/// 
/// 使用通用的TaskTagFilterStrip，保持向后兼容
class InboxTagFilterStrip extends StatelessWidget {
  const InboxTagFilterStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return TaskTagFilterStrip(filterProvider: inboxFilterProvider);
  }
}

