import 'package:flutter/material.dart';

import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../utils/date_utils.dart';
import '../utils/section_label_utils.dart';

class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({
    super.key,
    required this.section,
  });

  final TaskSection section;

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
    _selectedDate = defaultDueDate(widget.section);
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
    final dateLabel = MaterialLocalizations.of(context)
        .formatMediumDate(_selectedDate ?? defaultDueDate(widget.section));
    final sectionLabel = labelForSection(l10n, widget.section);

    return Padding(
      padding: EdgeInsets.only(
        bottom: viewInsets,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.taskListQuickAddTitle(sectionLabel),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 12),
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
    final now = DateTime.now();
    final initialDate = _selectedDate ?? now;
    final result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (result != null) {
      setState(() {
        _selectedDate = result;
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
    Navigator.of(context).pop(
      QuickAddResult(
        title: title,
        dueDate: _selectedDate ?? defaultDueDate(widget.section),
      ),
    );
  }
}

class QuickAddResult {
  const QuickAddResult({
    required this.title,
    required this.dueDate,
  });

  final String title;
  final DateTime dueDate;
}
