import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/service_providers.dart';
import '../../../../data/models/milestone.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../utils/date_utils.dart';
import '../../../widgets/flexible_text_input.dart';
import '../../../widgets/rich_text_description_preview.dart';
import '../../../widgets/utils/rich_text_description_editor_helper.dart';

class MilestoneEditSheet extends ConsumerStatefulWidget {
  const MilestoneEditSheet({
    super.key,
    required this.projectId,
    this.milestone,
  });

  final String projectId;
  final Milestone? milestone;

  @override
  ConsumerState<MilestoneEditSheet> createState() => _MilestoneEditSheetState();
}

class _MilestoneEditSheetState extends ConsumerState<MilestoneEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  String? _description;
  bool _submitting = false;
  late DateTime? _deadline;
  String? _deadlineError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.milestone?.title ?? '',
    );
    _description = widget.milestone?.description;
    _deadline = widget.milestone?.dueAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sheetPadding = EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom);
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.milestone != null;

    return Padding(
      padding: sheetPadding,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? l10n.milestoneEditTitle : l10n.milestoneAddTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FlexibleTextInput(
                  controller: _titleController,
                  softLimit: 50,
                  hardLimit: 255,
                  hintText: l10n.projectSheetMilestoneTitleHint,
                  labelText: l10n.taskListInputLabel,
                  onChanged: (_) => setState(() {}),
                  showCounter: false,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _pickDeadline,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    _deadline != null
                        ? formatDeadline(context, _deadline) ?? ''
                        : l10n.projectSheetSelectDeadlineHint,
                  ),
                ),
                if (_deadlineError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _deadlineError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                RichTextDescriptionPreview(
                  description: _description,
                  onTap: () async {
                    await RichTextDescriptionEditorHelper
                        .showRichTextDescriptionEditor(
                      context,
                      initialDescription: _description,
                      onSave: (savedDescription) {
                        setState(() {
                          _description = savedDescription;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? l10n.commonSave : l10n.commonAdd),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (result != null) {
      setState(() {
        _deadline = result;
        _deadlineError = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }

    // 标准化截止日期到当天23:59:59
    DateTime? normalizedDeadline;
    if (_deadline != null) {
      normalizedDeadline = DateTime(
        _deadline!.year,
        _deadline!.month,
        _deadline!.day,
        23,
        59,
        59,
        999,
      );
    }

    final sanitizedDescription = _description;

    setState(() => _submitting = true);
    try {
      if (widget.milestone != null) {
        // 编辑现有里程碑
        final milestoneService = await ref.read(milestoneServiceProvider.future);
        await milestoneService.updateMilestone(
              id: widget.milestone!.id,
              title: title,
              dueAt: normalizedDeadline,
              description: sanitizedDescription,
            );
      } else {
        // 创建新里程碑
        final milestoneService = await ref.read(milestoneServiceProvider.future);
        await milestoneService.createMilestone(
              projectId: widget.projectId,
              title: title,
              dueAt: normalizedDeadline,
              description: sanitizedDescription,
            );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to ${widget.milestone != null ? 'update' : 'create'} milestone: $error\n$stackTrace',
      );
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.projectCreateError)));
      setState(() => _submitting = false);
    }
  }
}
