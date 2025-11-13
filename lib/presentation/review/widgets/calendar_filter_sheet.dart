import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/calendar_review_providers.dart';
import '../../../core/providers/tag_providers.dart';
import '../../../core/providers/task_query_providers.dart';
import '../../../data/models/calendar_review_data.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 筛选底部 Sheet，支持项目选择和标签选择
class CalendarFilterSheet extends ConsumerStatefulWidget {
  const CalendarFilterSheet({super.key});

  @override
  ConsumerState<CalendarFilterSheet> createState() => _CalendarFilterSheetState();
}

class _CalendarFilterSheetState extends ConsumerState<CalendarFilterSheet> {
  String? _selectedProjectId;
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    final state = ref.read(calendarReviewNotifierProvider);
    _selectedProjectId = state.filter.projectId;
    _selectedTags = List.from(state.filter.tags);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final projectsAsync = ref.watch(projectsDomainProvider);
    final tagsAsync = ref.watch(allTagsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题
          Text(
            l10n.calendarReviewFilter,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          // 项目筛选
          Text(
            l10n.calendarReviewFilterByProject,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          projectsAsync.when(
            data: (projects) => _buildProjectList(projects),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          // 标签筛选
          Text(
            l10n.calendarReviewFilterByTags,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          tagsAsync.when(
            data: (tags) => _buildTagChips(context, tags),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilter,
                  child: Text(l10n.calendarReviewFilterReset),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _applyFilter,
                  child: Text(l10n.calendarReviewFilterApply),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList(projects) {
    final l10n = AppLocalizations.of(context);
    return RadioGroup<String?>(
      groupValue: _selectedProjectId,
      onChanged: (value) {
        setState(() {
          _selectedProjectId = value;
        });
      },
      child: ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length + 1, // +1 for "No Project"
      itemBuilder: (context, index) {
        if (index == 0) {
          return RadioListTile<String?>(
            title: Text(l10n.calendarReviewFilterNoProject),
            value: null,
          );
        }
        final project = projects[index - 1];
        return RadioListTile<String?>(
          title: Text(project.title),
          value: project.id,
          );
          },
      ),
    );
  }

  Widget _buildTagChips(BuildContext context, List<dynamic> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map<Widget>((tag) {
        final isSelected = _selectedTags.contains(tag.slug);
        return FilterChip(
          label: Text(tag.slug),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTags.add(tag.slug);
              } else {
                _selectedTags.remove(tag.slug);
              }
            });
          },
        );
      }).toList(),
    );
  }

  void _resetFilter() {
    setState(() {
      _selectedProjectId = null;
      _selectedTags = [];
    });
  }

  void _applyFilter() {
    final notifier = ref.read(calendarReviewNotifierProvider.notifier);
    notifier.setFilter(
      CalendarFilter(
        projectId: _selectedProjectId,
        tags: _selectedTags,
      ),
    );
    Navigator.of(context).pop();
  }
}
