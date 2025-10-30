import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/task_service.dart'
    show ProjectBlueprint, ProjectMilestoneBlueprint;
import '../../../data/models/tag.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../utils/date_utils.dart';
import '../utils/tag_utils.dart';
import '../../widgets/tag_data.dart';
import '../../widgets/flexible_description_input.dart';
import '../../widgets/flexible_text_input.dart';
import '../../widgets/modern_tag.dart';
import '../../widgets/modern_tag_group.dart';

class ProjectCreationSheet extends ConsumerStatefulWidget {
  const ProjectCreationSheet({
    super.key,
  });

  @override
  ConsumerState<ProjectCreationSheet> createState() => _ProjectCreationSheetState();
}

class _ProjectCreationSheetState extends ConsumerState<ProjectCreationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<MilestoneDraft> _milestones = <MilestoneDraft>[];
  bool _submitting = false;
  String? _selectedUrgencyTag;
  String? _selectedImportanceTag;
  DateTime? _projectDeadline;
  String? _executionTag;
  String? _deadlineError;
  bool _suppressProjectShortcut = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onProjectTitleChanged);
    _descriptionController.addListener(_onProjectDescriptionChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onProjectTitleChanged);
    _descriptionController.removeListener(_onProjectDescriptionChanged);
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
                    Text(l10n.projectSheetTitle, style: Theme.of(context).textTheme.titleLarge),
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
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 12),
                _buildProjectTagsSection(context),
                const SizedBox(height: 16),
                FlexibleDescriptionInput(
                  controller: _descriptionController,
                  softLimit: 200,
                  hardLimit: 60000,
                  hintText: l10n.projectSheetDescriptionHint,
                  labelText: l10n.flexibleDescriptionLabel,
                  onChanged: (_) => setState(() {}),
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

  Widget _buildProjectTagsSection(BuildContext context) {
    final urgencyTagsAsync = ref.watch(urgencyTagOptionsProvider);
    final importanceTagsAsync = ref.watch(importanceTagOptionsProvider);
    final executionTagsAsync = ref.watch(executionTagOptionsProvider);

    return urgencyTagsAsync.when(
      data: (urgencyTags) => importanceTagsAsync.when(
        data: (importanceTags) => executionTagsAsync.when(
          data: (executionTags) {
            final allTags = [...urgencyTags, ...importanceTags, ...executionTags];
            final tagData = allTags
                .map((tag) => TagData.fromTagWithLocalization(tag, context))
                .toList(growable: false);
            final selectedTags = <String>{
              if (_selectedUrgencyTag != null) _selectedUrgencyTag!,
              if (_selectedImportanceTag != null) _selectedImportanceTag!,
              if (_executionTag != null) _executionTag!,
            };

            return ModernTagGroup(
              tags: tagData,
              selectedTags: selectedTags,
              multiSelect: false,
              variant: TagVariant.pill,
              size: TagSize.medium,
              onSelectionChanged: (selected) {
                if (selected.isEmpty) {
                  _selectedUrgencyTag = null;
                  _selectedImportanceTag = null;
                  _executionTag = null;
                } else {
                  final slug = selected.first;
                  if (urgencyTags.any((tag) => tag.slug == slug)) {
                    _selectedUrgencyTag = slug;
                    _selectedImportanceTag = null;
                    _executionTag = null;
                  } else if (importanceTags.any((tag) => tag.slug == slug)) {
                    _selectedImportanceTag = slug;
                    _selectedUrgencyTag = null;
                    _executionTag = null;
                  } else if (executionTags.any((tag) => tag.slug == slug)) {
                    _executionTag = slug;
                    _selectedUrgencyTag = null;
                    _selectedImportanceTag = null;
                  }
                }
                setState(() {});
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('加载标签失败'),
        ),
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => const Text('加载标签失败'),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('加载标签失败'),
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
            Text(l10n.projectSheetMilestonesTitle,
                style: Theme.of(context).textTheme.titleMedium),
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

  void _onProjectTitleChanged() {
    if (_suppressProjectShortcut) {
      return;
    }
    _handleShortcutInController(_titleController, includeExecution: true, onHashtagSelected: (slug) {
      setState(() {
        _assignProjectTag(slug);
      });
    });
  }

  void _onProjectDescriptionChanged() {
    if (_suppressProjectShortcut) {
      return;
    }
    _handleShortcutInController(_descriptionController, includeExecution: true,
        onHashtagSelected: (slug) {
      setState(() {
        _assignProjectTag(slug);
      });
    });
  }

  void _assignProjectTag(String slug) {
    if (urgencyTagNames.contains(slug)) {
      _selectedUrgencyTag = '#$slug';
      _selectedImportanceTag = null;
      _executionTag = null;
    } else if (importanceTagNames.contains(slug)) {
      _selectedImportanceTag = '#$slug';
      _selectedUrgencyTag = null;
      _executionTag = null;
    } else if (executionTagNames.contains(slug)) {
      _executionTag = '#$slug';
      _selectedUrgencyTag = null;
      _selectedImportanceTag = null;
    }
  }

  void _handleShortcutInController(
    TextEditingController controller, {
    required bool includeExecution,
    required void Function(String slug) onHashtagSelected,
  }) {
    final text = controller.text;
    final hashIndex = text.lastIndexOf('#');
    if (hashIndex == -1) {
      return;
    }
    final keyword = text.substring(hashIndex + 1).trim().toLowerCase();
    if (keyword.isEmpty) {
      return;
    }

    String? resolved;
    String prefix = '#';
    if (contextTagNames.contains(keyword)) {
      resolved = keyword;
      prefix = '@';
    } else if (urgencyTagNames.contains(keyword) ||
        importanceTagNames.contains(keyword) ||
        executionTagNames.contains(keyword)) {
      resolved = keyword;
      prefix = '#';
    }

    if (resolved == null) {
      return;
    }

    _suppressProjectShortcut = true;
    final replacement = '$prefix$resolved';
    controller.text =
        controller.text.replaceRange(hashIndex, controller.text.length, replacement);
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    _suppressProjectShortcut = false;
    onHashtagSelected(resolved);
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
    final tags = <String>[];
    if (_selectedUrgencyTag != null) {
      tags.add(_selectedUrgencyTag!);
    }
    if (_selectedImportanceTag != null) {
      tags.add(_selectedImportanceTag!);
    }
    if (_executionTag != null) {
      tags.add(_executionTag!);
    }
    return tags;
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
    final sanitizedDescription =
        description != null && description.isNotEmpty ? description : null;

    final blueprint = ProjectBlueprint(
      title: title,
      dueDate: _projectDeadline!,
      description: sanitizedDescription,
      tags: _collectProjectTags(),
      milestones: _collectMilestones(),
    );

    setState(() => _submitting = true);
    try {
      await ref.read(taskServiceProvider).createProject(blueprint);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Failed to create project: $error\n$stackTrace');
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

class MilestoneDraft {
  MilestoneDraft()
      : titleController = TextEditingController(),
        descriptionController = TextEditingController();

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  DateTime? deadline;
  String? urgencyTag;
  String? importanceTag;
  String? executionTag;
  VoidCallback? titleListener;
  bool suppressShortcut = false;

  void applyTag(String slug) {
    if (executionTags.contains(slug)) {
      executionTag = slug;
    } else if (urgencyTags.contains(slug)) {
      urgencyTag = slug;
    } else if (importanceTags.contains(slug)) {
      importanceTag = slug;
    }
  }

  List<String> buildTags() {
    final tags = <String>[];
    if (urgencyTag != null) tags.add(urgencyTag!);
    if (importanceTag != null) tags.add(importanceTag!);
    if (executionTag != null) tags.add(executionTag!);
    return tags;
  }

  void dispose() {
    if (titleListener != null) {
      titleController.removeListener(titleListener!);
    }
    titleController.dispose();
    descriptionController.dispose();
  }
}

class MilestoneDraftTile extends ConsumerStatefulWidget {
  const MilestoneDraftTile({
    super.key,
    required this.draft,
    required this.onRemove,
    required this.onPickDeadline,
    required this.onChanged,
  });

  final MilestoneDraft draft;
  final VoidCallback onRemove;
  final Future<void> Function() onPickDeadline;
  final VoidCallback onChanged;

  @override
  ConsumerState<MilestoneDraftTile> createState() => _MilestoneDraftTileState();
}

class _MilestoneDraftTileState extends ConsumerState<MilestoneDraftTile> {
  List<TagData> _tagsToTagData(BuildContext context, List<Tag> tags) {
    return tags.map((tag) => TagData.fromTagWithLocalization(tag, context)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FlexibleTextInput(
                    controller: widget.draft.titleController,
                    softLimit: 50,
                    hardLimit: 255,
                    hintText: l10n.projectSheetMilestoneTitleHint,
                    labelText: l10n.taskListInputLabel,
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.commonDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.draft.deadline != null
                        ? formatDeadline(context, widget.draft.deadline) ?? ''
                        : l10n.projectSheetSelectDeadlineHint,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onPickDeadline,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(l10n.projectSheetSelectDeadline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final urgencyTagsAsync = ref.watch(urgencyTagOptionsProvider);
                final importanceTagsAsync = ref.watch(importanceTagOptionsProvider);
                final executionTagsAsync = ref.watch(executionTagOptionsProvider);

                return urgencyTagsAsync.when(
                  data: (urgencyTags) => importanceTagsAsync.when(
                    data: (importanceTags) => executionTagsAsync.when(
                      data: (executionTags) {
                        final allTags = [...urgencyTags, ...importanceTags, ...executionTags];
                        final tagData = _tagsToTagData(context, allTags);
                        final selectedTags = <String>{
                          if (widget.draft.urgencyTag != null) widget.draft.urgencyTag!,
                          if (widget.draft.importanceTag != null) widget.draft.importanceTag!,
                          if (widget.draft.executionTag != null) widget.draft.executionTag!,
                        };

                        return ModernTagGroup(
                          tags: tagData,
                          selectedTags: selectedTags,
                          multiSelect: false,
                          variant: TagVariant.pill,
                          size: TagSize.medium,
                          onSelectionChanged: (selected) {
                            if (selected.isEmpty) {
                              widget.draft.urgencyTag = null;
                              widget.draft.importanceTag = null;
                              widget.draft.executionTag = null;
                            } else {
                              final slug = selected.first;
                              if (urgencyTags.contains(slug)) {
                                widget.draft.urgencyTag = slug;
                                widget.draft.importanceTag = null;
                                widget.draft.executionTag = null;
                              } else if (importanceTags.contains(slug)) {
                                widget.draft.importanceTag = slug;
                                widget.draft.urgencyTag = null;
                                widget.draft.executionTag = null;
                              } else if (executionTags.contains(slug)) {
                                widget.draft.executionTag = slug;
                                widget.draft.urgencyTag = null;
                                widget.draft.importanceTag = null;
                              }
                            }
                            widget.onChanged();
                          },
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('加载标签失败'),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('加载标签失败'),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('加载标签失败'),
                );
              },
            ),
            const SizedBox(height: 12),
            FlexibleDescriptionInput(
              controller: widget.draft.descriptionController,
              softLimit: 200,
              hardLimit: 60000,
              hintText: l10n.projectSheetDescriptionHint,
              labelText: l10n.flexibleDescriptionLabel,
              onChanged: (_) => widget.onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}
