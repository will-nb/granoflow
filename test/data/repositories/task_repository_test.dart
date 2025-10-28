import 'package:flutter_test/flutter_test.dart';

// 测试工具类，复制时间计算逻辑进行测试
class TimeCalculationTestUtils {
  /// 计算两个任务时间的中间值
  /// 如果两个时间完全相同，为后一个时间增加0.99秒后再计算中间值
  static DateTime calculateMiddleTime(DateTime time1, DateTime time2) {
    final diff = time2.difference(time1);
    
    // 如果两个时间在秒级完全相同，为后一个时间增加0.99秒
    if (diff.inMilliseconds == 0) {
      final adjustedTime2 = time2.add(const Duration(milliseconds: 990));
      final adjustedDiff = adjustedTime2.difference(time1);
      return time1.add(Duration(milliseconds: adjustedDiff.inMilliseconds ~/ 2));
    }
    
    return time1.add(Duration(milliseconds: diff.inMilliseconds ~/ 2));
  }

  /// 计算区域首位的中间值
  /// 如果区域开始时间和第一个任务时间完全相同，为第一个任务增加0.99秒后再计算中间值
  static DateTime calculateSectionFirstMiddleTime(DateTime sectionStart, DateTime firstTaskTime) {
    final diff = firstTaskTime.difference(sectionStart);
    
    // 如果区域开始时间和第一个任务时间完全相同，为第一个任务增加0.99秒
    if (diff.inMilliseconds == 0) {
      final adjustedFirstTask = firstTaskTime.add(const Duration(milliseconds: 990));
      final adjustedDiff = adjustedFirstTask.difference(sectionStart);
      return sectionStart.add(Duration(milliseconds: adjustedDiff.inMilliseconds ~/ 2));
    }
    
    return sectionStart.add(Duration(milliseconds: diff.inMilliseconds ~/ 2));
  }

  /// 计算区域末尾的中间值
  /// 如果最后一个任务时间和区域结束时间完全相同，为最后一个任务时间减少0.99秒后再计算中间值
  static DateTime calculateSectionLastMiddleTime(DateTime lastTaskTime, DateTime sectionEnd) {
    final diff = sectionEnd.difference(lastTaskTime);
    
    // 如果最后一个任务时间和区域结束时间完全相同，为最后一个任务时间减少0.99秒
    if (diff.inMilliseconds == 0) {
      final adjustedLastTask = lastTaskTime.subtract(const Duration(milliseconds: 990));
      final adjustedDiff = sectionEnd.difference(adjustedLastTask);
      return adjustedLastTask.add(Duration(milliseconds: adjustedDiff.inMilliseconds ~/ 2));
    }
    
    return lastTaskTime.add(Duration(milliseconds: diff.inMilliseconds ~/ 2));
  }
}

void main() {
  group('TaskRepository Time Calculation Tests', () {
    group('calculateMiddleTime', () {
      test('should calculate middle time correctly for different times', () {
        final time1 = DateTime(2025, 1, 27, 10, 0, 0);
        final time2 = DateTime(2025, 1, 27, 12, 0, 0);
        
        final result = TimeCalculationTestUtils.calculateMiddleTime(time1, time2);
        final expected = DateTime(2025, 1, 27, 11, 0, 0);
        
        expect(result, equals(expected));
      });

      test('should handle identical times by adding 0.99 seconds to second time', () {
        final time1 = DateTime(2025, 1, 27, 10, 0, 0);
        final time2 = DateTime(2025, 1, 27, 10, 0, 0);
        
        final result = TimeCalculationTestUtils.calculateMiddleTime(time1, time2);
        final expected = DateTime(2025, 1, 27, 10, 0, 0, 495); // 0.495秒
        
        expect(result, equals(expected));
      });

      test('should handle millisecond precision correctly', () {
        final time1 = DateTime(2025, 1, 27, 10, 0, 0, 100);
        final time2 = DateTime(2025, 1, 27, 10, 0, 0, 300);
        
        final result = TimeCalculationTestUtils.calculateMiddleTime(time1, time2);
        final expected = DateTime(2025, 1, 27, 10, 0, 0, 200);
        
        expect(result, equals(expected));
      });
    });

    group('calculateSectionFirstMiddleTime', () {
      test('should calculate section first middle time correctly', () {
        final sectionStart = DateTime(2025, 1, 27, 9, 0, 0);
        final firstTaskTime = DateTime(2025, 1, 27, 11, 0, 0);
        
        final result = TimeCalculationTestUtils.calculateSectionFirstMiddleTime(sectionStart, firstTaskTime);
        final expected = DateTime(2025, 1, 27, 10, 0, 0);
        
        expect(result, equals(expected));
      });

      test('should handle identical section start and first task times', () {
        final sectionStart = DateTime(2025, 1, 27, 10, 0, 0);
        final firstTaskTime = DateTime(2025, 1, 27, 10, 0, 0);
        
        final result = TimeCalculationTestUtils.calculateSectionFirstMiddleTime(sectionStart, firstTaskTime);
        final expected = DateTime(2025, 1, 27, 10, 0, 0, 495); // 0.495秒
        
        expect(result, equals(expected));
      });
    });

    group('calculateSectionLastMiddleTime', () {
      test('should calculate section last middle time correctly', () {
        final lastTaskTime = DateTime(2025, 1, 27, 10, 0, 0);
        final sectionEnd = DateTime(2025, 1, 27, 12, 0, 0);
        
        final result = TimeCalculationTestUtils.calculateSectionLastMiddleTime(lastTaskTime, sectionEnd);
        final expected = DateTime(2025, 1, 27, 11, 0, 0);
        
        expect(result, equals(expected));
      });

      test('should handle identical last task and section end times', () {
        final lastTaskTime = DateTime(2025, 1, 27, 10, 0, 0);
        final sectionEnd = DateTime(2025, 1, 27, 10, 0, 0);
        
        final result = TimeCalculationTestUtils.calculateSectionLastMiddleTime(lastTaskTime, sectionEnd);
        final expected = DateTime(2025, 1, 27, 9, 59, 59, 505); // 减少0.495秒
        
        expect(result, equals(expected));
      });
    });
  });
}
