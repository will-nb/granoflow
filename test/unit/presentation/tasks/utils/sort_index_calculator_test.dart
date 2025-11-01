import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/constants/task_constants.dart';
import 'package:granoflow/presentation/tasks/utils/sort_index_calculator.dart';

void main() {
  group('SortIndexCalculator', () {
    group('insertAtFirst', () {
      test('should return DEFAULT_SORT_INDEX when firstTaskSortIndex is null', () {
        expect(
          SortIndexCalculator.insertAtFirst(null),
          equals(TaskConstants.DEFAULT_SORT_INDEX),
        );
      });

      test('should subtract defaultInterval when firstTaskSortIndex is provided', () {
        expect(SortIndexCalculator.insertAtFirst(1000.0), equals(0.0));
        expect(SortIndexCalculator.insertAtFirst(500.0), equals(-500.0));
        expect(SortIndexCalculator.insertAtFirst(0.0), equals(-1000.0));
      });

      test('should handle negative values', () {
        expect(SortIndexCalculator.insertAtFirst(-500.0), equals(-1500.0));
      });
    });

    group('insertAtLast', () {
      test('should return DEFAULT_SORT_INDEX when lastTaskSortIndex is null', () {
        expect(
          SortIndexCalculator.insertAtLast(null),
          equals(TaskConstants.DEFAULT_SORT_INDEX),
        );
      });

      test('should add defaultInterval when lastTaskSortIndex is provided', () {
        expect(SortIndexCalculator.insertAtLast(1000.0), equals(2000.0));
        expect(SortIndexCalculator.insertAtLast(500.0), equals(1500.0));
        expect(SortIndexCalculator.insertAtLast(0.0), equals(1000.0));
      });

      test('should handle negative values', () {
        expect(SortIndexCalculator.insertAtLast(-500.0), equals(500.0));
      });
    });

    group('insertBetween', () {
      test('should return average of two sortIndexes', () {
        expect(
          SortIndexCalculator.insertBetween(1000.0, 2000.0),
          equals(1500.0),
        );
        expect(
          SortIndexCalculator.insertBetween(0.0, 1000.0),
          equals(500.0),
        );
        expect(
          SortIndexCalculator.insertBetween(500.0, 1000.0),
          equals(750.0),
        );
      });

      test('should handle same values', () {
        expect(
          SortIndexCalculator.insertBetween(1000.0, 1000.0),
          equals(1000.0),
        );
      });

      test('should handle negative values', () {
        expect(
          SortIndexCalculator.insertBetween(-1000.0, 0.0),
          equals(-500.0),
        );
        expect(
          SortIndexCalculator.insertBetween(-500.0, 500.0),
          equals(0.0),
        );
      });

      test('should handle large values', () {
        expect(
          SortIndexCalculator.insertBetween(1000000.0, 2000000.0),
          equals(1500000.0),
        );
      });
    });

    group('insertAfter', () {
      test('should add defaultInterval to taskSortIndex', () {
        expect(SortIndexCalculator.insertAfter(1000.0), equals(2000.0));
        expect(SortIndexCalculator.insertAfter(500.0), equals(1500.0));
        expect(SortIndexCalculator.insertAfter(0.0), equals(1000.0));
      });

      test('should handle negative values', () {
        expect(SortIndexCalculator.insertAfter(-500.0), equals(500.0));
        expect(SortIndexCalculator.insertAfter(-1000.0), equals(0.0));
      });
    });

    group('insertBefore', () {
      test('should subtract defaultInterval from taskSortIndex', () {
        expect(SortIndexCalculator.insertBefore(1000.0), equals(0.0));
        expect(SortIndexCalculator.insertBefore(500.0), equals(-500.0));
        expect(SortIndexCalculator.insertBefore(2000.0), equals(1000.0));
      });

      test('should handle negative values', () {
        expect(SortIndexCalculator.insertBefore(-500.0), equals(-1500.0));
        expect(SortIndexCalculator.insertBefore(0.0), equals(-1000.0));
      });
    });
  });
}
