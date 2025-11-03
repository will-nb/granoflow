import 'package:flutter/material.dart';
import '../../widgets/task_filter_collapsible.dart';
import '../../../core/providers/app_providers.dart';

/// Inbox筛选折叠组件（向后兼容）
///
/// 使用通用的TaskFilterCollapsible，保持向后兼容
class InboxFilterCollapsible extends StatelessWidget {
  const InboxFilterCollapsible({super.key});

  @override
  Widget build(BuildContext context) {
    return TaskFilterCollapsible(filterProvider: inboxFilterProvider);
  }
}


