import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/theme/ocean_breeze_color_schemes.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/presentation/widgets/tag_data.dart';

void main() {
  group('TagData', () {
    test('fromTag creates TagData for context tag', () {
      // Arrange
      final tag = Tag(
        id: 1,
        slug: '@home',
        kind: TagKind.context,
        localizedLabels: {
          'en': 'Home',
          'zh_CN': '家',
        },
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.slug, '@home');
      expect(tagData.label, 'Home');
      expect(tagData.color, OceanBreezeColorSchemes.lakeCyan);
      expect(tagData.icon, Icons.place_outlined);
      expect(tagData.prefix, isNull); // ARB 文件中已包含前缀，不再单独返回
      expect(tagData.kind, TagKind.context);
    });

    test('fromTag creates TagData for urgent tag', () {
      // Arrange
      final tag = Tag(
        id: 2,
        slug: '#urgent',
        kind: TagKind.urgency,
        localizedLabels: {
          'en': 'Urgent',
          'zh_CN': '紧急',
        },
      );

      // Act
      final tagData = TagData.fromTag(tag, 'zh_CN');

      // Assert
      expect(tagData.slug, '#urgent');
      expect(tagData.label, '紧急');
      expect(tagData.color, OceanBreezeColorSchemes.softPink);
      expect(tagData.icon, Icons.priority_high);
      expect(tagData.prefix, isNull); // ARB 文件中已包含前缀，不再单独返回
      expect(tagData.kind, TagKind.urgency);
    });

    test('fromTag creates TagData for important tag', () {
      // Arrange
      final tag = Tag(
        id: 3,
        slug: '#important',
        kind: TagKind.importance,
        localizedLabels: {
          'en': 'Important',
        },
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.slug, '#important');
      expect(tagData.label, 'Important');
      expect(tagData.color, OceanBreezeColorSchemes.warmYellow);
      expect(tagData.icon, Icons.star);
      expect(tagData.prefix, isNull); // ARB 文件中已包含前缀，不再单独返回
    });

    test('fromTag creates TagData for not_urgent tag', () {
      // Arrange
      final tag = Tag(
        id: 4,
        slug: '#not_urgent',
        kind: TagKind.urgency,
        localizedLabels: {'en': 'Not Urgent'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.color, OceanBreezeColorSchemes.lightBlueGray);
      expect(tagData.icon, Icons.event_available);
    });

    test('fromTag creates TagData for not_important tag', () {
      // Arrange
      final tag = Tag(
        id: 5,
        slug: '#not_important',
        kind: TagKind.importance,
        localizedLabels: {'en': 'Not Important'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.color, OceanBreezeColorSchemes.silverGray);
      expect(tagData.icon, Icons.star_outline);
    });

    test('fromTag creates TagData for waiting tag', () {
      // Arrange
      final tag = Tag(
        id: 6,
        slug: '#waiting',
        kind: TagKind.special,
        localizedLabels: {'en': 'Waiting'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.color, OceanBreezeColorSchemes.disabledGray);
      expect(tagData.icon, Icons.hourglass_empty);
    });

    test('fromTag creates TagData for wasted tag', () {
      // Arrange
      final tag = Tag(
        id: 7,
        slug: 'wasted',
        kind: TagKind.special,
        localizedLabels: {'en': 'Wasted'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.color, OceanBreezeColorSchemes.secondaryText);
      expect(tagData.icon, Icons.delete_outline);
      expect(tagData.prefix, null);
    });

    test('fromTag handles unknown priority tag with default style', () {
      // Arrange
      final tag = Tag(
        id: 8,
        slug: '#custom',
        kind: TagKind.priority,
        localizedLabels: {'en': 'Custom'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.color, OceanBreezeColorSchemes.seaSaltBlue);
      expect(tagData.icon, Icons.tag);
      expect(tagData.prefix, isNull); // ARB 文件中已包含前缀，不再单独返回
    });

    test('fromTag uses locale fallback', () {
      // Arrange
      final tag = Tag(
        id: 9,
        slug: '@home',
        kind: TagKind.context,
        localizedLabels: {
          'en': 'Home',
          'zh': '家',
        },
      );

      // Act - 请求 zh_CN，但只有 zh 可用
      final tagData = TagData.fromTag(tag, 'zh_CN');

      // Assert - 应该回退到 zh
      expect(tagData.label, '家');
    });

    test('TagData equality works correctly', () {
      // Arrange
      final tag = Tag(
        id: 1,
        slug: '@home',
        kind: TagKind.context,
        localizedLabels: {'en': 'Home'},
      );

      // Act
      final tagData1 = TagData.fromTag(tag, 'en');
      final tagData2 = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData1, equals(tagData2));
      expect(tagData1.hashCode, equals(tagData2.hashCode));
    });

    test('TagData toString works', () {
      // Arrange
      final tag = Tag(
        id: 1,
        slug: '@home',
        kind: TagKind.context,
        localizedLabels: {'en': 'Home'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');
      final stringRep = tagData.toString();

      // Assert
      expect(stringRep, contains('@home'));
      expect(stringRep, contains('Home'));
      expect(stringRep, contains('TagKind.context'));
    });
  });
}

