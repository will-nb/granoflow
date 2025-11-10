import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/theme/ocean_breeze_color_schemes.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/presentation/widgets/tag_data.dart';

void main() {
  group('TagData', () {
    test('fromTag creates TagData for context tag (normalizes slug)', () {
      // Arrange
      final tag = Tag(
        id: '1',
        slug: '@home', // 旧格式带前缀，会被规范化
        kind: TagKind.context,
        localizedLabels: {'en': 'Home', 'zh_CN': '家'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.slug, 'home'); // 规范化后的 slug（无前缀）
      expect(tagData.label, 'Home');
      expect(tagData.color, OceanBreezeColorSchemes.seaSaltBlue);
      expect(tagData.icon, Icons.home);
      expect(tagData.prefix, null); // 前缀已废弃，不再显示
      expect(tagData.kind, TagKind.context);
    });

    test('fromTag creates TagData for urgent tag (normalizes slug)', () {
      // Arrange
      final tag = Tag(
        id: '2',
        slug: '#urgent', // 旧格式带前缀，会被规范化
        kind: TagKind.urgency,
        localizedLabels: {'en': 'Urgent', 'zh_CN': '紧急'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'zh_CN');

      // Assert
      expect(tagData.slug, 'urgent'); // 规范化后的 slug（无前缀）
      expect(tagData.label, '紧急');
      expect(tagData.color, OceanBreezeColorSchemes.softPink);
      expect(tagData.icon, Icons.priority_high);
      expect(tagData.prefix, null); // 前缀已废弃，不再显示
      expect(tagData.kind, TagKind.urgency);
    });

    test('fromTag creates TagData for important tag (normalizes slug)', () {
      // Arrange
      final tag = Tag(
        id: '3',
        slug: '#important', // 旧格式带前缀，会被规范化
        kind: TagKind.importance,
        localizedLabels: {'en': 'Important'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.slug, 'important'); // 规范化后的 slug（无前缀）
      expect(tagData.label, 'Important');
      expect(tagData.color, OceanBreezeColorSchemes.warmYellow);
      expect(tagData.icon, Icons.star);
      expect(tagData.prefix, null); // 前缀已废弃，不再显示
    });

    test('fromTag creates TagData for not_urgent tag (normalizes slug)', () {
      // Arrange
      final tag = Tag(
        id: '4',
        slug: '#not_urgent', // 旧格式带前缀，会被规范化
        kind: TagKind.urgency,
        localizedLabels: {'en': 'Not Urgent'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.slug, 'not_urgent'); // 规范化后的 slug（无前缀）
      expect(tagData.color, OceanBreezeColorSchemes.lightBlueGray);
      expect(tagData.icon, Icons.event_available);
      expect(tagData.prefix, null); // 前缀已废弃，不再显示
    });

    test('fromTag creates TagData for not_important tag (normalizes slug)', () {
      // Arrange
      final tag = Tag(
        id: '5',
        slug: '#not_important', // 旧格式带前缀，会被规范化
        kind: TagKind.importance,
        localizedLabels: {'en': 'Not Important'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.slug, 'not_important'); // 规范化后的 slug（无前缀）
      expect(tagData.color, OceanBreezeColorSchemes.silverGray);
      expect(tagData.icon, Icons.star_outline);
      expect(tagData.prefix, null); // 前缀已废弃，不再显示
    });

    test('fromTag creates TagData for waiting tag (normalizes slug)', () {
      // Arrange
      final tag = Tag(
        id: '6',
        slug: '#waiting', // 旧格式带前缀，会被规范化
        kind: TagKind.execution, // 应该是 execution，不是 special
        localizedLabels: {'en': 'Waiting'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.slug, 'waiting'); // 规范化后的 slug（无前缀）
      expect(tagData.color, OceanBreezeColorSchemes.disabledGray);
      expect(tagData.icon, Icons.hourglass_empty);
      expect(tagData.prefix, null); // 前缀已废弃，不再显示
    });

    test('fromTag creates TagData for wasted tag', () {
      // Arrange
      final tag = Tag(
        id: '7',
        slug: 'wasted', // 特殊标签没有前缀
        kind: TagKind.special,
        localizedLabels: {'en': 'Wasted'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.slug, 'wasted'); // 无前缀的 slug 保持不变
      expect(tagData.color, OceanBreezeColorSchemes.secondaryText);
      expect(tagData.icon, Icons.delete_outline);
      expect(tagData.prefix, null); // 特殊标签没有前缀
    });

    test('fromTag handles unknown tag with default style', () {
      // Arrange
      final tag = Tag(
        id: '8',
        slug: 'custom', // 未知标签
        kind: TagKind.special,
        localizedLabels: {'en': 'Custom'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData.slug, 'custom'); // 规范化后的 slug
      expect(tagData.color, OceanBreezeColorSchemes.seaSaltBlue);
      expect(tagData.icon, Icons.tag);
      expect(tagData.prefix, null); // 特殊标签没有前缀
    });

    test('fromTag uses locale fallback (normalizes slug)', () {
      // Arrange
      final tag = Tag(
        id: '9',
        slug: '@home', // 旧格式带前缀，会被规范化
        kind: TagKind.context,
        localizedLabels: {'en': 'Home', 'zh': '家'},
      );

      // Act - 请求 zh_CN，但只有 zh 可用
      final tagData = TagData.fromTag(tag, 'zh_CN');

      // Assert - 应该回退到 zh，slug 被规范化
      expect(tagData.slug, 'home'); // 规范化后的 slug（无前缀）
      expect(tagData.label, '家');
    });

    test('TagData equality works correctly (normalizes slug)', () {
      // Arrange
      final tag = Tag(
        id: '1',
        slug: '@home', // 旧格式带前缀，会被规范化
        kind: TagKind.context,
        localizedLabels: {'en': 'Home'},
      );

      // Act
      final tagData1 = TagData.fromTag(tag, 'en');
      final tagData2 = TagData.fromTag(tag, 'en');

      // Assert
      expect(tagData1, equals(tagData2));
      expect(tagData1.hashCode, equals(tagData2.hashCode));
      expect(tagData1.slug, 'home'); // 规范化后的 slug
    });

    test('TagData toString works (normalizes slug)', () {
      // Arrange
      final tag = Tag(
        id: '1',
        slug: '@home', // 旧格式带前缀，会被规范化
        kind: TagKind.context,
        localizedLabels: {'en': 'Home'},
      );

      // Act
      final tagData = TagData.fromTag(tag, 'en');
      final stringRep = tagData.toString();

      // Assert
      expect(stringRep, contains('home')); // 规范化后的 slug（无前缀）
      expect(stringRep, contains('Home'));
      expect(stringRep, contains('TagKind.context'));
    });
  });
}
