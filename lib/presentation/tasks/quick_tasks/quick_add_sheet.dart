import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing_tokens.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/custom_date_picker.dart';
import '../utils/date_utils.dart';

class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({
    super.key,
    this.section,
    this.defaultDate,
  });

  /// 任务分区，如果为 null 则表示不预设分区，日期需要用户选择
  final TaskSection? section;

  /// 默认日期，如果提供则优先使用此日期，否则使用 section 的默认日期
  final DateTime? defaultDate;

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // 优先使用 defaultDate，如果没有则使用 section 的默认日期，否则为 null
    if (widget.defaultDate != null) {
      _selectedDate = widget.defaultDate;
    } else if (widget.section != null) {
      _selectedDate = defaultDueDate(widget.section!);
    } else {
      _selectedDate = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets.bottom;
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacingTokens;
    
    // 日期标签：如果有选择日期则显示日期，否则显示默认日期或"选择日期"
    final dateLabel = _selectedDate != null
        ? MaterialLocalizations.of(context).formatMediumDate(_selectedDate!)
        : (widget.defaultDate != null
            ? MaterialLocalizations.of(context).formatMediumDate(widget.defaultDate!)
            : (widget.section != null
                ? MaterialLocalizations.of(context).formatMediumDate(defaultDueDate(widget.section!))
                : l10n.taskSetDeadline));

    return Padding(
      padding: EdgeInsets.only(
        bottom: viewInsets,
        left: spacing.cardHorizontalPadding,
        right: spacing.cardHorizontalPadding,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.taskListInputLabel,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(dateLabel),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.commonAdd),
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

    // 使用统一的日历弹窗，与 CreateTaskDialog 保持一致
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

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).taskListInputValidation)),
      );
      return;
    }
    setState(() {
      _submitting = true;
    });
    
    // 确定日期：优先使用用户选择的日期，然后使用 defaultDate，再使用 section 的默认日期，否则为 null
    final DateTime? finalDate;
    if (_selectedDate != null) {
      finalDate = _selectedDate;
    } else if (widget.defaultDate != null) {
      finalDate = widget.defaultDate;
    } else if (widget.section != null) {
      finalDate = defaultDueDate(widget.section!);
    } else {
      finalDate = null;
    }
    
    Navigator.of(context).pop(
      QuickAddResult(
        title: title,
        dueDate: finalDate,
      ),
    );
  }
}

class QuickAddResult {
  const QuickAddResult({
    required this.title,
    this.dueDate,
  });

  final String title;
  final DateTime? dueDate;
}
