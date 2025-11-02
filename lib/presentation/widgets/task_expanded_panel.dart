import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/services/tag_service.dart';
import '../../data/models/tag.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import 'tag_panel.dart';
import 'error_banner.dart';

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
          _buildDateSection(context),
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

  Widget _buildDateSection(BuildContext context) {
    // 如果是子任务（level > 1），不显示日期部分
    if (widget.taskLevel != null && widget.taskLevel! > 1) {
      return const SizedBox.shrink();
    }
    
    final l10n = AppLocalizations.of(context);
    
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.task.dueAt == null
                ? l10n.noDueDateSet
                : DateFormat.yMMMd(widget.localeName).format(widget.task.dueAt!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _selectDate(context),
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(l10n.inboxPlanButtonLabel),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Future<void> _planTask(BuildContext context, Task task) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    
    // 计算特殊日期
    final today = now;
    final tomorrow = now.add(const Duration(days: 1));
    final thisWeek = _getThisWeekSaturday(now);
    final thisMonth = _getEndOfMonth(now);
    
    // 显示快速选择对话框
    final quickChoice = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (context) => _QuickDatePicker(
        today: today,
        tomorrow: tomorrow,
        thisWeek: thisWeek,
        thisMonth: thisMonth,
      ),
    );
    
    DateTime? selectedDate = quickChoice;
    
    // 如果没有选择快速选项，显示标准日期选择器
    if (selectedDate == null) {
      selectedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now, // 今天以前不可选择
        lastDate: now.add(const Duration(days: 365)),
      );
    }
    
    if (selectedDate == null) {
      return;
    }
    
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

  Future<void> _selectDate(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 显示快速选择对话框
    final quickSelection = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.today),
            title: Text(l10n.datePickerToday),
            onTap: () => Navigator.pop(context, 'today'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(l10n.datePickerTomorrow),
            onTap: () => Navigator.pop(context, 'tomorrow'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_view_week),
            title: Text(l10n.datePickerThisWeek),
            onTap: () => Navigator.pop(context, 'thisWeek'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(l10n.datePickerThisMonth),
            onTap: () => Navigator.pop(context, 'thisMonth'),
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: Text(l10n.datePickerCustom),
            onTap: () => Navigator.pop(context, 'custom'),
          ),
        ],
      ),
    );

    if (quickSelection == null || !context.mounted) return;

    DateTime? selectedDate;

    switch (quickSelection) {
      case 'today':
        selectedDate = today;
        break;
      case 'tomorrow':
        selectedDate = today.add(const Duration(days: 1));
        break;
      case 'thisWeek':
        selectedDate = _getThisWeekSaturday(today);
        break;
      case 'thisMonth':
        selectedDate = _getEndOfMonth(today);
        break;
      case 'custom':
        selectedDate = await showDatePicker(
          context: context,
          initialDate: widget.task.dueAt ?? today,
          firstDate: today,
          lastDate: today.add(const Duration(days: 365 * 2)),
        );
        break;
    }

    if (selectedDate != null && context.mounted) {
      widget.onDateChanged?.call(selectedDate);
    }
  }

  Future<void> _updateTags(
    BuildContext context,
    WidgetRef ref,
    int taskId,
    String? contextTag,
    String? priorityTag,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(taskServiceProvider)
          .updateTags(taskId: taskId, contextTag: contextTag, priorityTag: priorityTag);
    } catch (error, stackTrace) {
      debugPrint('Failed to update tags: $error\n$stackTrace');
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('${l10n.inboxTagError}: $error')));
      }
    }
  }


  TaskSection _sectionForDate(DateTime date) {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final difference = normalizedDate.difference(normalizedNow).inDays;
    if (difference <= 0) {
      return TaskSection.today;
    }
    if (difference == 1) {
      return TaskSection.tomorrow;
    }
    return TaskSection.later;
  }

  /// 计算本周六的日期
  /// 如果今天是周六，则返回下周六
  DateTime _getThisWeekSaturday(DateTime now) {
    final daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
  }

  /// 计算本月最后一天的日期
  DateTime _getEndOfMonth(DateTime now) {
    return DateTime(now.year, now.month + 1, 0);
  }
}

/// 快速日期选择对话框
class _QuickDatePicker extends StatelessWidget {
  const _QuickDatePicker({
    required this.today,
    required this.tomorrow,
    required this.thisWeek,
    required this.thisMonth,
  });

  final DateTime today;
  final DateTime tomorrow;
  final DateTime thisWeek;
  final DateTime thisMonth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.datePickerTitle,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _QuickDateOption(
            icon: Icons.today,
            label: l10n.datePickerToday,
            date: today,
            onTap: () => Navigator.pop(context, today),
          ),
          _QuickDateOption(
            icon: Icons.calendar_today,
            label: l10n.datePickerTomorrow,
            date: tomorrow,
            onTap: () => Navigator.pop(context, tomorrow),
          ),
          _QuickDateOption(
            icon: Icons.calendar_view_week,
            label: l10n.datePickerThisWeek,
            date: thisWeek,
            onTap: () => Navigator.pop(context, thisWeek),
          ),
          _QuickDateOption(
            icon: Icons.calendar_month,
            label: l10n.datePickerThisMonth,
            date: thisMonth,
            onTap: () => Navigator.pop(context, thisMonth),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
        ],
      ),
    );
  }
}

class _QuickDateOption extends StatelessWidget {
  const _QuickDateOption({
    required this.icon,
    required this.label,
    required this.date,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(DateFormat.yMMMd().format(date)),
        onTap: onTap,
      ),
    );
  }
}
