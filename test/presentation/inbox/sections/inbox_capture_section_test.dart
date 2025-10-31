import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/data/models/task_template.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/inbox/sections/inbox_capture_section.dart';
import 'package:granoflow/core/theme/app_theme.dart';

Tag _contextTag(String slug) => Tag(
      id: slug.hashCode,
      slug: slug,
      kind: TagKind.context,
      localizedLabels: {'en': slug},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('InboxCaptureSection submits text and shows templates', (tester) async {
    String? submittedValue;
    TaskTemplate? appliedTemplate;

    final controller = TextEditingController();
    final focusNode = FocusNode();

    final template = TaskTemplate(
      id: 1,
      title: 'Daily Review',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          templateSuggestionsProvider.overrideWithProvider((query) {
            return FutureProvider((ref) async => <TaskTemplate>[template]);
          }),
          contextTagOptionsProvider.overrideWith((ref) async => [_contextTag('@home')]),
          urgencyTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
          importanceTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: InboxCaptureSection(
              controller: controller,
              focusNode: focusNode,
              isSubmitting: false,
              currentQuery: '',
              onChanged: (_) {},
              onSubmit: (value) async {
                submittedValue = value;
              },
              onTemplateApply: (tpl) async {
                appliedTemplate = tpl;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField), 'Capture idea');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(submittedValue, 'Capture idea');
    final captureSection = tester.widget<InboxCaptureSection>(find.byType(InboxCaptureSection));
    await captureSection.onTemplateApply(template);

    expect(appliedTemplate, equals(template));
  });
}

