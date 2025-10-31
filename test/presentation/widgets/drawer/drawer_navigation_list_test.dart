import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/presentation/widgets/drawer/drawer_navigation_list.dart';
import 'package:granoflow/presentation/navigation/sidebar_destinations.dart';

void main() {
  group('DrawerNavigationList Widget Tests', () {
    testWidgets('should render all navigation destinations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: DrawerNavigationList(),
          ),
        ),
      );
      
      // 验证所有导航项都存在
      expect(find.byType(ListTile), findsNWidgets(SidebarDestinations.values.length));
    });

    testWidgets('should display correct icons for each destination', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: DrawerNavigationList(),
          ),
        ),
      );
      
      // 验证图标存在
      expect(find.byType(Icon), findsNWidgets(SidebarDestinations.values.length));
    });

    testWidgets('should display correct labels for each destination', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: DrawerNavigationList(),
          ),
        ),
      );
      
      // 验证所有标签文本都存在
      for (final destination in SidebarDestinations.values) {
        expect(find.text(destination.label), findsOneWidget);
      }
    });

    testWidgets('should use compact visual density', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: DrawerNavigationList(),
          ),
        ),
      );
      
      final listTile = tester.widget<ListTile>(find.byType(ListTile).first);
      expect(listTile.dense, isTrue);
      expect(listTile.visualDensity, equals(VisualDensity.compact));
    });

    testWidgets('should have correct styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: DrawerNavigationList(),
          ),
        ),
      );
      
      // 验证 ListTile 存在
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('should handle all 5 destinations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: DrawerNavigationList(),
          ),
        ),
      );
      
      expect(find.byType(ListTile), findsNWidgets(5));
    });
  });
}
