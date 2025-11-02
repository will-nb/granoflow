import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../quick_tasks/quick_tasks_section.dart';
import '../widgets/empty_placeholder.dart';
import '../widgets/error_banner.dart';
import '../widgets/section_header.dart';
import 'project_card.dart';
import 'project_creation_sheet.dart';

class ProjectsDashboard extends ConsumerWidget {
  const ProjectsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsDomainProvider);
    final quickTasksAsync = ref.watch(quickTasksProvider);
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _openCreationSheet(context, ref),
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.projectCreateButton),
          ),
        ),
        const SizedBox(height: 16),
        QuickTasksCollapsibleSection(asyncTasks: quickTasksAsync),
        const SizedBox(height: 24),
        SectionHeader(
          title: l10n.projectListTitle,
          subtitle: l10n.projectListSubtitle,
        ),
        const SizedBox(height: 12),
        projectsAsync.when(
          data: (projects) {
            if (projects.isEmpty) {
              return EmptyPlaceholder(message: l10n.projectListEmpty);
            }
            return Column(
              children: projects
                  .map((project) => ProjectCard(project: project))
                  .toList(growable: false),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => ErrorBanner(message: '$error'),
        ),
      ],
    );
  }

  Future<void> _openCreationSheet(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => const ProjectCreationSheet(),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).projectCreateSuccess),
        ),
      );
    }
  }
}
