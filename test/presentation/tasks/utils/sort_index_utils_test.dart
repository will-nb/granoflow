import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/constants/task_constants.dart';
import 'package:granoflow/presentation/tasks/utils/sort_index_utils.dart';

void main() {
  group('calculateSortIndex', () {
    test('returns midpoint when both indices are sufficiently different', () {
      final result = calculateSortIndex(100, 200);
      expect(result, 150);
    });

    test('returns after + 1 when indices are too close', () {
      final result = calculateSortIndex(100, 100.00001);
      expect(result, 100.00001 + 1);
    });

    test('returns after - 1000 when only after is provided', () {
      final result = calculateSortIndex(null, 500);
      expect(result, -500);
    });

    test('returns before + 1000 when only before is provided', () {
      final result = calculateSortIndex(500, null);
      expect(result, 1500);
    });

    test('returns default sort index when neither is provided', () {
      final result = calculateSortIndex(null, null);
      expect(result, TaskConstants.DEFAULT_SORT_INDEX);
    });

    test('handles negative indices', () {
      final result = calculateSortIndex(-200, -100);
      expect(result, -150);
    });

    test('handles zero indices', () {
      final result = calculateSortIndex(0, 100);
      expect(result, 50);
    });
  });
}

