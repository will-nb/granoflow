import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing_tokens.dart';
import '../../../generated/l10n/app_localizations.dart';

/// Inbox 快速添加任务弹窗
///
/// 用于在 Inbox 页面快速添加任务，不包含日期选择功能。
class InboxQuickAddSheet extends StatefulWidget {
  const InboxQuickAddSheet({super.key});

  @override
  State<InboxQuickAddSheet> createState() => _InboxQuickAddSheetState();
}

class _InboxQuickAddSheetState extends State<InboxQuickAddSheet> {
  final TextEditingController _titleController = TextEditingController();
  bool _submitting = false;

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

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).taskListInputValidation),
        ),
      );
      return;
    }
    setState(() {
      _submitting = true;
    });
    Navigator.of(context).pop(title);
  }
}
