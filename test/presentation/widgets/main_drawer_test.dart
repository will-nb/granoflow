import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/presentation/widgets/main_drawer.dart';
import 'package:granoflow/presentation/widgets/drawer/drawer_header.dart'
    as drawer;
import 'package:granoflow/presentation/widgets/drawer/drawer_navigation_list.dart';
import 'package:granoflow/presentation/widgets/drawer/drawer_projects_section.dart';
import 'package:granoflow/presentation/widgets/drawer/drawer_tags_section.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/tag_providers.dart';
import 'package:granoflow/data/models/project.dart';
import 'package:granoflow/data/models/tag.dart';

void main() {
  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        // Mock providers to avoid Isar dependency
        projectsDomainProvider.overrideWith(
          (ref) => Stream<List<Project>>.value(const <Project>[]),
        ),
        tagsByKindProvider.overrideWith((ref, kind) async => <Tag>[]),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('zh', 'CN'),
          Locale('zh', 'HK'),
        ],
        home: Scaffold(drawer: const MainDrawer(), body: Container()),
      ),
    );
  }

  group('MainDrawer Integration Tests', () {
    testWidgets('should render drawer with all sub-components', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // 打开 drawer
      final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // 验证所有子组件都存在
      expect(find.byType(drawer.DrawerHeader), findsOneWidget);
      expect(find.byType(DrawerNavigationList), findsOneWidget);
      expect(find.byType(DrawerProjectsSection), findsOneWidget);
      expect(find.byType(DrawerTagsSection), findsOneWidget);
    });

    testWidgets('should have correct drawer structure', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // 打开 drawer
      final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // 验证 Drawer widget 存在
      expect(find.byType(Drawer), findsOneWidget);

      // 验证 Column 和 ListView 结构
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should have dividers between sections', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // 打开 drawer
      final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // 验证 Divider 存在（项目区域和标签区域前各有一个）
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });
}
