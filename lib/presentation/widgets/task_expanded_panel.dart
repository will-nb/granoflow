import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/services/tag_service.dart';
import '../../core/utils/task_section_utils.dart';
import '../../data/models/tag.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import 'custom_date_picker.dart';
import 'error_banner.dart';
import 'tag_panel.dart';
import 'task_expanded_panel/task_expanded_panel_date_section.dart';

class TaskExpandedPanel extends ConsumerStatefulWidget {
  const TaskExpandedPanel({
    super.key,
    required this.task,
    required this.localeName,
    this.showQuickPlan = false,
    this.showDateSection = false,
    this.showSwipeHint = false,
    this.leftActionKey,
    this.rightActionKey,
    this.onQuickPlan,
    this.onDateChanged,
    this.taskLevel, // 任务的层级（level），用于判断是否是子任务
  });

  final Task task;
  final String localeName;
  final bool showQuickPlan;
  final bool showDateSection;
  final bool showSwipeHint;
  final String? leftActionKey;
  final String? rightActionKey;
  final VoidCallback? onQuickPlan;
  final ValueChanged<DateTime?>? onDateChanged;
  /// 任务的层级（level），用于判断是否是子任务
  /// level > 1 表示是子任务，子任务不显示截止日期
  final int? taskLevel;

  @override
  ConsumerState<TaskExpandedPanel> createState() => _TaskExpandedPanelState();
}

class _TaskExpandedPanelState extends ConsumerState<TaskExpandedPanel> {
  bool _isPlanning = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contextTags = ref.watch(contextTagOptionsProvider);
    final urgencyTags = ref.watch(urgencyTagOptionsProvider);
    final importanceTags = ref.watch(importanceTagOptionsProvider);
    
    final task = widget.task;
    // 使用 TagService 查找上下文标签和优先级标签（兼容旧数据）
    final contextTag = task.tags.firstWhere(
      (tag) => TagService.getKind(tag) == TagKind.context, 
      orElse: () => '',
    );
    final priorityTag = task.tags.firstWhere(
      (tag) {
        final kind = TagService.getKind(tag);
        return kind == TagKind.urgency || kind == TagKind.importance;
      }, 
      orElse: () => '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 如果是子任务（level > 1），不显示标签选择面板
        if (widget.taskLevel == null || widget.taskLevel! <= 1)
          contextTags.when(
            data: (tags) {
              // 合并urgency和importance标签
              final allPriorityTags = <Tag>[];
              urgencyTags.whenData((urgencyTags) => allPriorityTags.addAll(urgencyTags));
              importanceTags.whenData((importanceTags) => allPriorityTags.addAll(importanceTags));
              
              return TagPanel(
                contextTags: tags,
                priorityTags: allPriorityTags,
                localeName: widget.localeName,
                selectedContext: contextTag.isEmpty ? null : contextTag,
                selectedPriority: priorityTag.isEmpty ? null : priorityTag,
                onContextChanged: (tag) => _updateTags(context, ref, task.id, tag, priorityTag),
                onPriorityChanged: (tag) => _updateTags(context, ref, task.id, contextTag, tag),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => ErrorBanner(message: '$error'),
          ),
        
        if (widget.showSwipeHint) ...[
          const SizedBox(height: 12),
          Text(_buildSwipeHintText(l10n), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
        ],
        
        if (widget.showQuickPlan) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat.yMMMd(widget.localeName).format(task.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isPlanning ? null : () => _planTask(context, task),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(l10n.inboxPlanButtonLabel),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
        
        if (widget.showDateSection) ...[
          const SizedBox(height: 16),
          TaskExpandedPanelDateSection(
            task: task,
            localeName: widget.localeName,
            taskLevel: widget.taskLevel,
            onDateChanged: widget.onDateChanged,
          ),
        ],
        
        if (_isPlanning || _isDeleting)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  /// 构建动态滑动提示文字
  String _buildSwipeHintText(AppLocalizations l10n) {
    if (widget.leftActionKey == null || widget.rightActionKey == null) {
      return '';
    }
    
    final leftAction = _getLocalizedText(l10n, widget.leftActionKey!);
    final rightAction = _getLocalizedText(l10n, widget.rightActionKey!);
    
    // swipeHintTemplate 是一个带参数的函数，直接调用并传入参数
    return l10n.swipeHintTemplate(leftAction, rightAction);
  }

  /// 获取本地化文本
  String _getLocalizedText(AppLocalizations l10n, String key) {
    switch (key) {
      case 'inboxDeleteAction':
        return l10n.inboxDeleteAction;
      case 'inboxQuickPlanAction':
        return l10n.inboxQuickPlanAction;
      case 'taskArchiveAction':
        return l10n.taskArchiveAction;
      case 'taskPostponeAction':
        return l10n.taskPostponeAction;
      default:
        return key; // 如果找不到对应的本地化字符串，返回key本身
    }
  }

  Future<void> _planTask(BuildContext context, Task task) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 使用统一的日历弹窗，包含快速选择功能
    final initialDate = task.dueAt != null
        ? DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day)
        : today;
    
    final pickedDate = await showCustomDatePicker(
      context: context,
      initialDate: initialDate.isBefore(today) ? today : initialDate,
      firstDate: today, // 不能选择今天之前的日期
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: l10n.datePickerTitle,
    );
    
    if (pickedDate == null || !context.mounted) {
      return;
    }
    
    // 统一设置为当天的 23:59:59
    final selectedDate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      23,
      59,
      59,
    );
    
    setState(() {
      _isPlanning = true;
    });
    
    try {
      final section = _sectionForDate(selectedDate);
      await ref
          .read(taskServiceProvider)
          .planTask(taskId: task.id, dueDateLocal: selectedDate, section: section);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.inboxPlanSuccess)));
    } catch (error, stackTrace) {
      debugPrint('Failed to plan inbox task: $error\n$stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.inboxPlanError}: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlanning = false;
        });
      }
    }
  }

  // _selectDate 已移至 task_expanded_panel_date_actions.dart

  Future<void> _updateTags(
    BuildContext context,
    WidgetRef ref,
    String taskId,
    String? contextTag,
    String? priorityTag,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      await taskService.updateTags(taskId: taskId, contextTag: contextTag, priorityTag: priorityTag);
    } catch (error, stackTrace) {
      debugPrint('Failed to update tags: $error\n$stackTrace');
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('${l10n.inboxTagError}: $error')));
      }
    }
  }


  TaskSection _sectionForDate(DateTime date) {
    return TaskSectionUtils.getSectionForDate(date);
  }

}

// _QuickDatePicker 和 _QuickDateOption 已移至 task_expanded_panel_quick_date_picker.dart
