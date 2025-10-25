import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/app.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import '../test_support/fakes.dart';

void main() {
  final taskRepository = StubTaskRepository();
  final focusRepository = StubFocusSessionRepository();
  final tagRepository = StubTagRepository();
  final preferenceRepository = StubPreferenceRepository();
  final templateRepository = StubTaskTemplateRepository();
  final seedRepository = StubSeedRepository();

  testWidgets('renders hello message', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(taskRepository),
          focusSessionRepositoryProvider.overrideWithValue(focusRepository),
          tagRepositoryProvider.overrideWithValue(tagRepository),
          preferenceRepositoryProvider.overrideWithValue(preferenceRepository),
          taskTemplateRepositoryProvider.overrideWithValue(templateRepository),
          seedRepositoryProvider.overrideWithValue(seedRepository),
        ],
        child: const GranoFlowApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Hello, GranoFlow'), findsOneWidget);
    expect(find.text('A focused workspace for every screen.'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_top_outlined), findsOneWidget);
  });

  // TODO: 修复本地化测试
  // testWidgets('renders Simplified Chinese copy when locale is zh-Hans', (
  //   tester,
  // ) async {
  //   await tester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         taskRepositoryProvider.overrideWithValue(taskRepository),
  //         focusSessionRepositoryProvider.overrideWithValue(focusRepository),
  //         tagRepositoryProvider.overrideWithValue(tagRepository),
  //         preferenceRepositoryProvider.overrideWithValue(preferenceRepository),
  //         taskTemplateRepositoryProvider.overrideWithValue(templateRepository),
  //         seedRepositoryProvider.overrideWithValue(seedRepository),
  //       ],
  //       child: const GranoFlowApp(
  //         locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  //       ),
  //     ),
  //   );
  //   await tester.pumpAndSettle();
  //   await tester.pump(const Duration(milliseconds: 200));

  //   expect(find.text('你好，GranoFlow'), findsOneWidget);
  //   expect(find.textContaining('专注空间'), findsOneWidget);
  // });
}
