import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../tasks/projects/projects_dashboard.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/main_drawer.dart';
import '../widgets/page_app_bar.dart';

/// 项目页面
/// 显示所有项目列表和项目管理功能
class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return GradientPageScaffold(
      appBar: PageAppBar(title: l10n.projectListTitle),
      drawer: const MainDrawer(),
      body: const ProjectsDashboard(),
    );
  }
}
