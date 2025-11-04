import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/project_service_helpers.dart';

void main() {
  group('ProjectServiceHelpers', () {
    late ProjectServiceHelpers helpers;

    setUp(() {
      helpers = ProjectServiceHelpers();
    });

    group('normalizeDueDate', () {
      test('将日期标准化为当天的 23:59:59.999', () {
        final input = DateTime(2025, 1, 15, 10, 30, 45, 123);
        final result = helpers.normalizeDueDate(input);

        expect(result.year, equals(2025));
        expect(result.month, equals(1));
        expect(result.day, equals(15));
        expect(result.hour, equals(23));
        expect(result.minute, equals(59));
        expect(result.second, equals(59));
        expect(result.millisecond, equals(999));
      });
    });

    group('addOneYear', () {
      test('普通年份增加一年', () {
        final input = DateTime(2025, 6, 15, 10, 30, 45, 123);
        final result = helpers.addOneYear(input);

        expect(result.year, equals(2026));
        expect(result.month, equals(6));
        expect(result.day, equals(15));
        expect(result.hour, equals(10));
        expect(result.minute, equals(30));
        expect(result.second, equals(45));
        expect(result.millisecond, equals(123));
      });

      test('闰年2月29日增加一年后变为平年2月28日', () {
        final input = DateTime(2024, 2, 29, 10, 30);
        final result = helpers.addOneYear(input);

        expect(result.year, equals(2025));
        expect(result.month, equals(2));
        expect(result.day, equals(28), reason: '2025不是闰年，2月29日应该变为2月28日');
        expect(result.hour, equals(10));
        expect(result.minute, equals(30));
      });

      test('平年2月28日增加一年后保持2月28日', () {
        final input = DateTime(2025, 2, 28, 10, 30);
        final result = helpers.addOneYear(input);

        expect(result.year, equals(2026));
        expect(result.month, equals(2));
        expect(result.day, equals(28));
      });

      test('闰年到闰年，2月29日保持不变', () {
        // 2024是闰年，2028也是闰年
        final helpers2028 = ProjectServiceHelpers();
        // 模拟2028年
        final input2028 = DateTime(2028, 2, 29, 10, 30);
        final result = helpers2028.addOneYear(input2028);

        expect(result.year, equals(2029));
        expect(result.month, equals(2));
        expect(result.day, equals(28), reason: '2029不是闰年，2月29日应该变为2月28日');
      });

      test('跨年边界日期（12月31日）', () {
        final input = DateTime(2025, 12, 31, 23, 59, 59, 999);
        final result = helpers.addOneYear(input);

        expect(result.year, equals(2026));
        expect(result.month, equals(12));
        expect(result.day, equals(31));
      });

      test('保持时间部分不变', () {
        final input = DateTime(2025, 6, 15, 15, 45, 30, 500);
        final result = helpers.addOneYear(input);

        expect(result.hour, equals(15));
        expect(result.minute, equals(45));
        expect(result.second, equals(30));
        expect(result.millisecond, equals(500));
      });
    });

    group('uniqueTags', () {
      test('去除重复标签', () {
        final input = ['tag1', 'tag2', 'tag1', 'tag3', 'tag2'];
        final result = helpers.uniqueTags(input);

        expect(result, equals(['tag1', 'tag2', 'tag3']));
      });

      test('去除空字符串', () {
        final input = ['tag1', '', 'tag2', '', 'tag3'];
        final result = helpers.uniqueTags(input);

        expect(result, equals(['tag1', 'tag2', 'tag3']));
      });

      test('保持顺序（首次出现的顺序）', () {
        final input = ['tag3', 'tag1', 'tag2', 'tag1'];
        final result = helpers.uniqueTags(input);

        expect(result, equals(['tag3', 'tag1', 'tag2']));
      });

      test('空列表返回空列表', () {
        final result = helpers.uniqueTags([]);
        expect(result, isEmpty);
      });

      test('只包含空字符串的列表返回空列表', () {
        final result = helpers.uniqueTags(['', '', '']);
        expect(result, isEmpty);
      });
    });
  });
}

