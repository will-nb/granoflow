import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/service_providers.dart';
import '../../core/utils/task_section_utils.dart';
import '../../generated/l10n/app_localizations.dart';
import 'custom_date_picker.dart';

class CreateTaskDialog extends ConsumerStatefulWidget {
  const CreateTaskDialog({super.key});

  @override
  ConsumerState<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<CreateTaskDialog> {
  final _titleController = TextEditingController();
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateLabel = _selectedDate != null
        ? DateFormat.yMMMd().format(_selectedDate!)
        : l10n.datePickerTitle;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题输入框
          TextField(
            controller: _titleController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _createTask(),
            decoration: InputDecoration(
              labelText: l10n.taskListInputLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.title),
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // 日期选择按钮
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _pickDate,
            icon: Icon(
              _selectedDate != null ? Icons.calendar_today : Icons.calendar_month_outlined,
            ),
            label: Text(dateLabel),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: 24),

          // 按钮行
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.commonCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _createTask,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.commonAdd),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final l10n = AppLocalizations.of(context);

    // 显示快速日期选择菜单
    final quickSelection = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final tomorrow = today.add(const Duration(days: 1));
        final thisWeek = _getThisWeekSaturday(today);
        final thisMonth = _getEndOfMonth(today);
        
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.today),
              title: Text(l10n.datePickerToday),
              subtitle: Text(DateFormat.yMMMd().format(today)),
              onTap: () => Navigator.pop(context, 'today'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.datePickerTomorrow),
              subtitle: Text(DateFormat.yMMMd().format(tomorrow)),
              onTap: () => Navigator.pop(context, 'tomorrow'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_week),
              title: Text(l10n.datePickerThisWeek),
              subtitle: Text(DateFormat.yMMMd().format(thisWeek)),
              onTap: () => Navigator.pop(context, 'thisWeek'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(l10n.datePickerThisMonth),
              subtitle: Text(DateFormat.yMMMd().format(thisMonth)),
              onTap: () => Navigator.pop(context, 'thisMonth'),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(l10n.datePickerCustom),
              onTap: () => Navigator.pop(context, 'custom'),
            ),
            if (_selectedDate != null)
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('清除日期'),
                onTap: () => Navigator.pop(context, 'clear'),
              ),
          ],
        );
      },
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
        // 使用自定义日期选择器替代系统默认的
        selectedDate = await showCustomDatePicker(
          context: context,
          initialDate: _selectedDate ?? now,
          firstDate: today, // 不能选择今天之前的日期
          lastDate: now.add(const Duration(days: 365 * 2)),
          helpText: l10n.datePickerTitle,
        );
        break;
      case 'clear':
        selectedDate = null;
        break;
    }

    if (context.mounted) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  Future<void> _createTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).taskListInputValidation)),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final taskService = ref.read(taskServiceProvider);
    final l10n = AppLocalizations.of(context);

    try {
      if (_selectedDate == null) {
        // 未选择日期：放入收集箱
        await taskService.captureInboxTask(title: title);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.inboxAddedToast)),
        );
      } else {
        // 选择日期：创建任务并规划到对应 section
        final newTask = await taskService.captureInboxTask(title: title);
        final section = TaskSectionUtils.getSectionForDate(_selectedDate);
        await taskService.planTask(
          taskId: newTask.id,
          dueDateLocal: _selectedDate!,
          section: section,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.taskListAddedToast)),
        );
      }

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to create task: $error\n$stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.inboxAddError}: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
