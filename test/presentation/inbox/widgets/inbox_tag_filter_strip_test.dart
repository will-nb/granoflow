import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/inbox/widgets/inbox_tag_filter_strip.dart';
import 'package:granoflow/core/theme/app_theme.dart';

Tag buildTag(String slug, TagKind kind) {
  return Tag(
    id: slug.hashCode,
    slug: slug,
    kind: kind,
    localizedLabels: {'en': slug},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('InboxTagFilterStrip toggles filters', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contextTagOptionsProvider.overrideWith((ref) async => [buildTag('home', TagKind.context)]),
          urgencyTagOptionsProvider.overrideWith((ref) async => [buildTag('urgent', TagKind.urgency)]),
          importanceTagOptionsProvider.overrideWith((ref) async => [buildTag('important', TagKind.importance)]),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: InboxTagFilterStrip()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final stripContext = tester.element(find.byType(InboxTagFilterStrip));
    final container = ProviderScope.containerOf(stripContext);
    final l10n = AppLocalizations.of(stripContext);
    final homeLabel = l10n.tag_home;
    final urgentLabel = l10n.tag_urgent;

    await tester.tap(find.text(homeLabel));
    await tester.pump();

    expect(container.read(inboxFilterProvider).contextTag, 'home');

    await tester.tap(find.text(urgentLabel));
    await tester.pump();

    expect(container.read(inboxFilterProvider).urgencyTag, 'urgent');

    await tester.tap(find.text(l10n.inboxFilterReset));
    await tester.pump();

    final filterState = container.read(inboxFilterProvider);
    expect(filterState.contextTag, isNull);
    expect(filterState.urgencyTag, isNull);
  });
}

