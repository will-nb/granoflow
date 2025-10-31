import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/utils/tag_utils.dart';

void main() {
  group('getTagKindFromSlug', () {
    test('returns context for context tags (compatible with old format)', () {
      // 新格式（无前缀）
      expect(getTagKindFromSlug('home'), TagKind.context);
      expect(getTagKindFromSlug('anywhere'), TagKind.context);
      // 兼容旧格式（带前缀）
      expect(getTagKindFromSlug('@home'), TagKind.context);
      expect(getTagKindFromSlug('@anywhere'), TagKind.context);
    });

    test('returns urgency for urgency tags (compatible with old format)', () {
      // 新格式（无前缀）
      expect(getTagKindFromSlug('urgent'), TagKind.urgency);
      expect(getTagKindFromSlug('not_urgent'), TagKind.urgency);
      // 兼容旧格式（带前缀）
      expect(getTagKindFromSlug('#urgent'), TagKind.urgency);
      expect(getTagKindFromSlug('#not_urgent'), TagKind.urgency);
    });

    test('returns importance for importance tags (compatible with old format)', () {
      // 新格式（无前缀）
      expect(getTagKindFromSlug('important'), TagKind.importance);
      expect(getTagKindFromSlug('not_important'), TagKind.importance);
      // 兼容旧格式（带前缀）
      expect(getTagKindFromSlug('#important'), TagKind.importance);
      expect(getTagKindFromSlug('#not_important'), TagKind.importance);
    });

    test('returns execution for execution tags (compatible with old format)', () {
      // 新格式（无前缀）
      expect(getTagKindFromSlug('timed'), TagKind.execution);
      expect(getTagKindFromSlug('fragmented'), TagKind.execution);
      expect(getTagKindFromSlug('waiting'), TagKind.execution);
      // 兼容旧格式（带前缀）
      expect(getTagKindFromSlug('#timed'), TagKind.execution);
      expect(getTagKindFromSlug('#fragmented'), TagKind.execution);
      expect(getTagKindFromSlug('#waiting'), TagKind.execution);
    });

    test('returns special for wasted tag', () {
      expect(getTagKindFromSlug('wasted'), TagKind.special);
    });

    test('returns special for unknown tags', () {
      expect(getTagKindFromSlug('unknown'), TagKind.special);
      expect(getTagKindFromSlug('#unknown'), TagKind.special);
    });
  });

  group('getTagStyle', () {
    test('returns consistent style for context tags', () {
      final (color1, icon1, prefix1) = getTagStyle('home', TagKind.context);
      final (color2, icon2, prefix2) = getTagStyle('company', TagKind.context);
      
      expect(icon1, Icons.home);
      expect(icon2, Icons.business);
      expect(prefix1, null); // 前缀已废弃，不再显示
      expect(prefix2, null);
    });

    test('returns distinct styles for urgency tags', () {
      final (urgentColor, urgentIcon, urgentPrefix) = getTagStyle('urgent', TagKind.urgency);
      final (notUrgentColor, notUrgentIcon, notUrgentPrefix) = getTagStyle('not_urgent', TagKind.urgency);
      
      expect(urgentColor, isNot(notUrgentColor));
      expect(urgentIcon, Icons.priority_high);
      expect(notUrgentIcon, Icons.event_available);
      expect(urgentPrefix, null); // 前缀已废弃，不再显示
      expect(notUrgentPrefix, null);
    });

    test('returns distinct styles for importance tags', () {
      final (importantColor, importantIcon, importantPrefix) = getTagStyle('important', TagKind.importance);
      final (notImportantColor, notImportantIcon, notImportantPrefix) = getTagStyle('not_important', TagKind.importance);
      
      expect(importantColor, isNot(notImportantColor));
      expect(importantIcon, Icons.star);
      expect(notImportantIcon, Icons.star_outline);
      expect(importantPrefix, null); // 前缀已废弃，不再显示
      expect(notImportantPrefix, null);
    });

    test('returns distinct styles for execution tags', () {
      final (timedColor, timedIcon, timedPrefix) = getTagStyle('timed', TagKind.execution);
      final (fragmentedColor, fragmentedIcon, fragmentedPrefix) = getTagStyle('fragmented', TagKind.execution);
      final (waitingColor, waitingIcon, waitingPrefix) = getTagStyle('waiting', TagKind.execution);
      
      expect(timedIcon, Icons.schedule);
      expect(fragmentedIcon, Icons.flash_on_outlined);
      expect(waitingIcon, Icons.hourglass_empty);
      expect(timedPrefix, null); // 前缀已废弃，不再显示
      expect(fragmentedPrefix, null);
      expect(waitingPrefix, null);
    });

    test('returns default style for unknown tags', () {
      final (color, icon, prefix) = getTagStyle('unknown', TagKind.special);
      
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
              
              // Context tags (new format, no prefix)
              expect(tagLabel(l10n, 'home'), isNotEmpty);
              expect(tagLabel(l10n, 'company'), isNotEmpty);
              // Compatible with old format
              expect(tagLabel(l10n, '@home'), isNotEmpty);
              expect(tagLabel(l10n, '@company'), isNotEmpty);
              
              // Urgency tags (new format, no prefix)
              expect(tagLabel(l10n, 'urgent'), isNotEmpty);
              expect(tagLabel(l10n, 'not_urgent'), isNotEmpty);
              // Compatible with old format
              expect(tagLabel(l10n, '#urgent'), isNotEmpty);
              expect(tagLabel(l10n, '#not_urgent'), isNotEmpty);
              
              // Importance tags (new format, no prefix)
              expect(tagLabel(l10n, 'important'), isNotEmpty);
              expect(tagLabel(l10n, 'not_important'), isNotEmpty);
              // Compatible with old format
              expect(tagLabel(l10n, '#important'), isNotEmpty);
              expect(tagLabel(l10n, '#not_important'), isNotEmpty);
              
              // Execution tags (new format, no prefix)
              expect(tagLabel(l10n, 'timed'), isNotEmpty);
              expect(tagLabel(l10n, 'fragmented'), isNotEmpty);
              expect(tagLabel(l10n, 'waiting'), isNotEmpty);
              // Compatible with old format
              expect(tagLabel(l10n, '#timed'), isNotEmpty);
              expect(tagLabel(l10n, '#fragmented'), isNotEmpty);
              expect(tagLabel(l10n, '#waiting'), isNotEmpty);
              
              // Unknown tags
              expect(tagLabel(l10n, 'unknown'), 'unknown');
              expect(tagLabel(l10n, '#unknown'), 'unknown'); // 规范化后
              
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('tag constants', () {
    test('execution tags are correctly defined (no prefix)', () {
      expect(executionTags, {'timed', 'fragmented', 'waiting'});
    });

    test('urgency tags are correctly defined (no prefix)', () {
      expect(urgencyTags, {'urgent', 'not_urgent'});
    });

    test('importance tags are correctly defined (no prefix)', () {
      expect(importanceTags, {'important', 'not_important'});
    });
  });
}

