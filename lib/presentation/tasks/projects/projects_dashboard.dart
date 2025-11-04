import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../widgets/empty_placeholder.dart';
import '../widgets/error_banner.dart';
import 'project_card.dart';
import 'project_creation_sheet.dart';
import 'widgets/project_status_filter.dart';

class ProjectsDashboard extends ConsumerWidget {
  const ProjectsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsByStatusProvider);
    final l10n = AppLocalizations.of(context);

    return CustomScrollView(
      slivers: [
        // 新建项目按钮
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _openCreationSheet(context, ref),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(l10n.projectCreateButton),
              ),
            ),
          ),
        ),
        // 状态筛选器
        const SliverToBoxAdapter(
          child: ProjectStatusFilter(),
        ),
        // 项目列表
        projectsAsync.when(
          data: (projects) {
            if (projects.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyPlaceholder(message: l10n.projectListEmpty),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ProjectCard(project: projects[index]),
                  ),
                  childCount: projects.length,
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stackTrace) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ErrorBanner(message: '$error'),
            ),
          ),
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
