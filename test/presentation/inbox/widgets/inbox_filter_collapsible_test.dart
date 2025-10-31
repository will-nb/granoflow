import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/inbox/widgets/inbox_filter_collapsible.dart';

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

  testWidgets('InboxFilterCollapsible toggles expand/collapse and shows strip', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contextTagOptionsProvider.overrideWith((ref) async => [buildTag('@home', TagKind.context)]),
          urgencyTagOptionsProvider.overrideWith((ref) async => [buildTag('#urgent', TagKind.urgency)]),
          importanceTagOptionsProvider.overrideWith((ref) async => [buildTag('#important', TagKind.importance)]),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: InboxFilterCollapsible(),
            ),
          ),
        ),
      ),
    );

    // 默认收拢：找不到任意一个示例标签
    expect(find.text('@home'), findsNothing);

    // 点击折叠头（图标按钮行）
    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();

    // 展开后应能看到来自 provider 的标签（英文本地化回退为 slug）
    expect(find.text('@home'), findsOneWidget);

    // 再次点击收拢
    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();
    expect(find.text('@home'), findsNothing);
  });
}


