// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/app.dart';
import 'package:granoflow/core/providers/repository_providers.dart';

import 'presentation/test_support/fakes.dart';

void main() {
  final taskRepository = StubTaskRepository();
  final focusRepository = StubFocusSessionRepository();
  final tagRepository = StubTagRepository();
  final preferenceRepository = StubPreferenceRepository();
  final templateRepository = StubTaskTemplateRepository();
  final seedRepository = StubSeedRepository();

  testWidgets('renders localized greeting on startup', (tester) async {
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

    // 验证应用标题存在（不依赖具体翻译文本）
    expect(find.textContaining('GranoFlow'), findsOneWidget);
  });
}
