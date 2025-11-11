import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

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

          // 日期选择图标（只显示图标，点击直接弹出日历）
          InkWell(
            onTap: _isSubmitting ? null : _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: color,
              ),
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
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _selectedDate != null
        ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day)
        : today;

    // 直接弹出日历，与任务列表中的日期设置行为一致
    final pickedDate = await showCustomDatePicker(
      context: context,
      initialDate: initialDate.isBefore(today) ? today : initialDate,
      firstDate: today, // 不能选择今天之前的日期
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: l10n.datePickerTitle,
    );

    if (pickedDate != null && context.mounted) {
      setState(() {
        // 统一设置为当天的 23:59:59
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          23,
          59,
          59,
        );
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

    final taskService = await ref.read(taskServiceProvider.future);
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

}
