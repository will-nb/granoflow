import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/utils/tag_utils.dart';

void main() {
  group('getTagKindFromSlug', () {
    test('returns context for @ prefix', () {
      expect(getTagKindFromSlug('@home'), TagKind.context);
      expect(getTagKindFromSlug('@anywhere'), TagKind.context);
    });

    test('returns urgency for urgency tags', () {
      expect(getTagKindFromSlug('#urgent'), TagKind.urgency);
      expect(getTagKindFromSlug('#not_urgent'), TagKind.urgency);
    });

    test('returns importance for importance tags', () {
      expect(getTagKindFromSlug('#important'), TagKind.importance);
      expect(getTagKindFromSlug('#not_important'), TagKind.importance);
    });

    test('returns execution for execution tags', () {
      expect(getTagKindFromSlug('#timed'), TagKind.execution);
      expect(getTagKindFromSlug('#fragmented'), TagKind.execution);
      expect(getTagKindFromSlug('#waiting'), TagKind.execution);
    });

    test('returns special for wasted tag', () {
      expect(getTagKindFromSlug('wasted'), TagKind.special);
    });

    test('returns special for unknown tags', () {
      expect(getTagKindFromSlug('#unknown'), TagKind.special);
    });
  });

  group('getTagStyle', () {
    test('returns consistent style for context tags', () {
      final (color1, icon1, prefix1) = getTagStyle('@home', TagKind.context);
      final (color2, icon2, prefix2) = getTagStyle('@company', TagKind.context);
      
      expect(color1, color2); // All context tags same color
      expect(icon1, Icons.place_outlined);
      expect(icon2, Icons.place_outlined);
      expect(prefix1, isNull);
      expect(prefix2, isNull);
    });

    test('returns distinct styles for urgency tags', () {
      final (urgentColor, urgentIcon, _) = getTagStyle('#urgent', TagKind.urgency);
      final (notUrgentColor, notUrgentIcon, _) = getTagStyle('#not_urgent', TagKind.urgency);
      
      expect(urgentColor, isNot(notUrgentColor));
      expect(urgentIcon, Icons.priority_high);
      expect(notUrgentIcon, Icons.event_available);
    });

    test('returns distinct styles for importance tags', () {
      final (importantColor, importantIcon, _) = getTagStyle('#important', TagKind.importance);
      final (notImportantColor, notImportantIcon, _) = getTagStyle('#not_important', TagKind.importance);
      
      expect(importantColor, isNot(notImportantColor));
      expect(importantIcon, Icons.star);
      expect(notImportantIcon, Icons.star_outline);
    });

    test('returns distinct styles for execution tags', () {
      final (timedColor, timedIcon, _) = getTagStyle('#timed', TagKind.execution);
      final (fragmentedColor, fragmentedIcon, _) = getTagStyle('#fragmented', TagKind.execution);
      final (waitingColor, waitingIcon, _) = getTagStyle('#waiting', TagKind.execution);
      
      expect(timedIcon, Icons.schedule);
      expect(fragmentedIcon, Icons.flash_on_outlined);
      expect(waitingIcon, Icons.hourglass_empty);
    });

    test('returns default style for unknown tags', () {
      final (color, icon, prefix) = getTagStyle('#unknown', TagKind.special);
      
      expect(color, const Color(0xFF64B5F6));
      expect(icon, Icons.tag);
      expect(prefix, isNull);
    });
  });

  group('tagLabel', () {
    testWidgets('returns localized labels for all tags', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              
              // Context tags
              expect(tagLabel(l10n, '@home'), isNotEmpty);
              expect(tagLabel(l10n, '@company'), isNotEmpty);
              
              // Urgency tags
              expect(tagLabel(l10n, '#urgent'), isNotEmpty);
              expect(tagLabel(l10n, '#not_urgent'), isNotEmpty);
              
              // Importance tags
              expect(tagLabel(l10n, '#important'), isNotEmpty);
              expect(tagLabel(l10n, '#not_important'), isNotEmpty);
              
              // Execution tags
              expect(tagLabel(l10n, '#timed'), isNotEmpty);
              expect(tagLabel(l10n, '#fragmented'), isNotEmpty);
              expect(tagLabel(l10n, '#waiting'), isNotEmpty);
              
              // Unknown tags
              expect(tagLabel(l10n, '#unknown'), '#unknown');
              
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('tag constants', () {
    test('execution tags are correctly defined', () {
      expect(executionTags, {'#timed', '#fragmented', '#waiting'});
    });

    test('urgency tags are correctly defined', () {
      expect(urgencyTags, {'#urgent', '#not_urgent'});
    });

    test('importance tags are correctly defined', () {
      expect(importanceTags, {'#important', '#not_important'});
    });
  });
}

