import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/task_crud_service_helpers.dart';

void main() {
  group('TaskCrudServiceHelpers', () {
    group('normalizeDueDate', () {
      test('将日期标准化为当天的 23:59:59.999', () {
        final input = DateTime(2025, 1, 15, 10, 30, 45, 123);
        final result = TaskCrudServiceHelpers.normalizeDueDate(input);

        expect(result.year, equals(2025));
        expect(result.month, equals(1));
        expect(result.day, equals(15));
        expect(result.hour, equals(23));
        expect(result.minute, equals(59));
        expect(result.second, equals(59));
        expect(result.millisecond, equals(999));
      });

      test('处理午夜时间', () {
        final input = DateTime(2025, 1, 15, 0, 0, 0, 0);
        final result = TaskCrudServiceHelpers.normalizeDueDate(input);

        expect(result.day, equals(15));
        expect(result.hour, equals(23));
        expect(result.minute, equals(59));
        expect(result.second, equals(59));
      });

      test('处理不同月份', () {
        final input = DateTime(2025, 12, 31, 15, 30);
        final result = TaskCrudServiceHelpers.normalizeDueDate(input);

        expect(result.month, equals(12));
        expect(result.day, equals(31));
        expect(result.hour, equals(23));
      });
    });

    group('isSameInstant', () {
      test('两个 null 返回 true', () {
        final result = TaskCrudServiceHelpers.isSameInstant(null, null);
        expect(result, isTrue);
      });

      test('一个 null 一个非 null 返回 false', () {
        final date = DateTime(2025, 1, 15);
        expect(
          TaskCrudServiceHelpers.isSameInstant(null, date),
          isFalse,
        );
        expect(
          TaskCrudServiceHelpers.isSameInstant(date, null),
          isFalse,
        );
      });

      test('相同的时间点返回 true', () {
        final date1 = DateTime(2025, 1, 15, 10, 30, 45, 123);
        final date2 = DateTime(2025, 1, 15, 10, 30, 45, 123);
        final result = TaskCrudServiceHelpers.isSameInstant(date1, date2);
        expect(result, isTrue);
      });

      test('不同的时间点返回 false', () {
        final date1 = DateTime(2025, 1, 15, 10, 30, 45, 123);
        final date2 = DateTime(2025, 1, 15, 10, 30, 45, 124);
        final result = TaskCrudServiceHelpers.isSameInstant(date1, date2);
        expect(result, isFalse);
      });

      test('忽略微秒，只比较毫秒', () {
        final date1 = DateTime(2025, 1, 15, 10, 30, 45, 123, 500);
        final date2 = DateTime(2025, 1, 15, 10, 30, 45, 123, 600);
        final result = TaskCrudServiceHelpers.isSameInstant(date1, date2);
        expect(result, isTrue, reason: '只比较到毫秒级别');
      });
    });

    group('areTagsEqual', () {
      test('完全相同的标签列表返回 true', () {
        final tags1 = ['tag1', 'tag2', 'tag3'];
        final tags2 = ['tag1', 'tag2', 'tag3'];
        final result =
            TaskCrudServiceHelpers.areTagsEqual(tags1, tags2);
        expect(result, isTrue);
      });

      test('顺序不同但内容相同返回 true', () {
        final tags1 = ['tag1', 'tag2', 'tag3'];
        final tags2 = ['tag3', 'tag1', 'tag2'];
        final result =
            TaskCrudServiceHelpers.areTagsEqual(tags1, tags2);
        expect(result, isTrue, reason: '标签顺序不影响相等性判断');
      });

      test('长度不同返回 false', () {
        final tags1 = ['tag1', 'tag2'];
        final tags2 = ['tag1', 'tag2', 'tag3'];
        final result =
            TaskCrudServiceHelpers.areTagsEqual(tags1, tags2);
        expect(result, isFalse);
      });

      test('内容不同返回 false', () {
        final tags1 = ['tag1', 'tag2'];
        final tags2 = ['tag1', 'tag3'];
        final result =
            TaskCrudServiceHelpers.areTagsEqual(tags1, tags2);
        expect(result, isFalse);
      });

      test('空列表返回 true', () {
        final tags1 = <String>[];
        final tags2 = <String>[];
        final result =
            TaskCrudServiceHelpers.areTagsEqual(tags1, tags2);
        expect(result, isTrue);
      });

      test('有重复标签时正确处理', () {
        final tags1 = ['tag1', 'tag1', 'tag2'];
        final tags2 = ['tag1', 'tag2', 'tag1'];
        final result =
            TaskCrudServiceHelpers.areTagsEqual(tags1, tags2);
        expect(result, isTrue, reason: '排序后比较，重复标签会被正确处理');
      });
    });
  });
}

