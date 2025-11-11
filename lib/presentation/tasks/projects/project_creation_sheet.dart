import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/services/project_models.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../utils/date_utils.dart';
import '../../widgets/flexible_description_input.dart';
import '../../widgets/flexible_text_input.dart';
import 'models/milestone_draft.dart';
import 'widgets/milestone_draft_tile.dart';

class ProjectCreationSheet extends ConsumerStatefulWidget {
  const ProjectCreationSheet({super.key});

  @override
  ConsumerState<ProjectCreationSheet> createState() =>
      _ProjectCreationSheetState();
}

class _ProjectCreationSheetState extends ConsumerState<ProjectCreationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<MilestoneDraft> _milestones = <MilestoneDraft>[];
  bool _submitting = false;
  DateTime? _projectDeadline;
  String? _deadlineError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final milestone in _milestones) {
      milestone.dispose();
    }
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
                      l10n.projectSheetTitle,
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
                FlexibleDescriptionInput(
                  controller: _descriptionController,
                  softLimit: 200,
                  hardLimit: 60000,
                  hintText: l10n.projectSheetDescriptionHint,
                  labelText: l10n.flexibleDescriptionLabel,
                  onChanged: (_) => setState(() {}),
                  showCounter: false,
                ),
                const SizedBox(height: 24),
                _buildMilestoneSection(context),
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
                        : Text(l10n.projectCreateButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.projectSheetMilestonesTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: _addMilestone,
              icon: const Icon(Icons.add),
              label: Text(l10n.projectSheetAddMilestone),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_milestones.isEmpty)
          Text(
            l10n.projectSheetMilestonesEmpty,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Column(
            children: _milestones
                .map(
                  (draft) => MilestoneDraftTile(
                    key: ValueKey(draft),
                    draft: draft,
                    onRemove: () => _removeMilestone(draft),
                    onPickDeadline: () => _pickMilestoneDeadline(draft),
                    onChanged: () => setState(() {}),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }

  void _addMilestone() {
    setState(() {
      _milestones.add(MilestoneDraft());
    });
  }

  void _removeMilestone(MilestoneDraft draft) {
    setState(() {
      _milestones.remove(draft);
      draft.dispose();
    });
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

  Future<void> _pickMilestoneDeadline(MilestoneDraft draft) async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: draft.deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (result != null) {
      setState(() {
        draft.deadline = result;
      });
    }
  }

  List<String> _collectProjectTags() {
    return <String>[];
  }

  List<ProjectMilestoneBlueprint> _collectMilestones() {
    return _milestones
        .where((draft) => draft.titleController.text.trim().isNotEmpty)
        .map(
          (draft) => ProjectMilestoneBlueprint(
            title: draft.titleController.text.trim(),
            dueDate: draft.deadline,
            tags: draft.buildTags(),
            description: draft.descriptionController.text.trim().isEmpty
                ? null
                : draft.descriptionController.text.trim(),
          ),
        )
        .toList(growable: false);
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
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final sanitizedDescription = description != null && description.isNotEmpty
        ? description
        : null;

    final blueprint = ProjectBlueprint(
      title: title,
      dueDate: _projectDeadline!,
      description: sanitizedDescription,
      tags: _collectProjectTags(),
      milestones: _collectMilestones(),
    );

    setState(() => _submitting = true);
    try {
      final projectService = await ref.read(projectServiceProvider.future);
      await projectService.createProject(blueprint);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Failed to create project: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.projectCreateError)));
      setState(() => _submitting = false);
    }
  }
}

// MilestoneDraft 和 MilestoneDraftTile 已移至独立文件
