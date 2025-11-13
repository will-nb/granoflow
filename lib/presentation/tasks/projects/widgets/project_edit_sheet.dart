import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/service_providers.dart';
import '../../../../data/models/project.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../utils/date_utils.dart';
import '../../../widgets/flexible_text_input.dart';
import '../../../widgets/rich_text_description_preview.dart';
import '../../../widgets/utils/rich_text_description_editor_helper.dart';

class ProjectEditSheet extends ConsumerStatefulWidget {
  const ProjectEditSheet({
    super.key,
    required this.project,
  });

  final Project project;

  @override
  ConsumerState<ProjectEditSheet> createState() => _ProjectEditSheetState();
}

class _ProjectEditSheetState extends ConsumerState<ProjectEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  String? _description;
  bool _submitting = false;
  late DateTime? _projectDeadline;
  String? _deadlineError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project.title);
    _description = widget.project.description;
    _projectDeadline = widget.project.dueAt;
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
                      l10n.projectEditTitle,
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
                  hintText: l10n.projectSheetTitleHint,
                  labelText: l10n.taskListInputLabel,
                  onChanged: (_) => setState(() {}),
                  showCounter: false,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _pickProjectDeadline,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    _projectDeadline != null
                        ? formatDeadline(context, _projectDeadline) ?? ''
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
                        : Text(l10n.commonSave),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickProjectDeadline() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _projectDeadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (result != null) {
      setState(() {
        _projectDeadline = result;
        _deadlineError = null;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    if (_projectDeadline == null) {
      setState(() {
        _deadlineError = l10n.projectSheetDeadlineRequired;
      });
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }

    // 标准化截止日期到当天23:59:59
    final normalizedDeadline = DateTime(
      _projectDeadline!.year,
      _projectDeadline!.month,
      _projectDeadline!.day,
      23,
      59,
      59,
      999,
    );

    final sanitizedDescription = _description;

    final update = ProjectUpdate(
      title: title,
      dueAt: normalizedDeadline,
      description: sanitizedDescription,
    );

    setState(() => _submitting = true);
    try {
      final projectService = await ref.read(projectServiceProvider.future);
      await projectService.updateProject(widget.project.id, update);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Failed to update project: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.projectCreateError)),
      );
      setState(() => _submitting = false);
    }
  }
}

