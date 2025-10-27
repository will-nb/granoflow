import 'package:flutter_test/flutter_test.dart';

/// 测试辅助类，用于测试智能推迟逻辑
class SwipeActionHandlerTestHelper {
  /// 计算本周六的日期
  /// 如果今天是周六，则返回下周六
  static DateTime getThisWeekSaturday(DateTime now) {
    final daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
  }

  /// 计算本月最后一天的日期
  static DateTime getEndOfMonth(DateTime now) {
    return DateTime(now.year, now.month + 1, 0);
  }

  /// 根据任务当前状态计算下一个合适的推迟日期
  static DateTime getNextScheduledDate(DateTime? currentDueDate, {DateTime? testNow}) {
    final now = testNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final thisWeekSaturday = getThisWeekSaturday(today);
    final thisMonthEnd = getEndOfMonth(today);
    
    // 如果没有当前日期，默认为今天
    final dueDate = currentDueDate ?? today;
    final normalizedDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    // 获取下一个可用的日期选项
    final nextDates = [tomorrow, thisWeekSaturday, thisMonthEnd];
    
    // 找到第一个比当前日期晚的日期
    for (final nextDate in nextDates) {
      if (nextDate.isAfter(normalizedDueDate)) {
        return nextDate;
      }
    }
    
    // 如果都更早，则推迟到下个月
    return DateTime(today.year, today.month + 1, 1);
  }
}

void main() {
  group('SwipeActionHandler Smart Postpone Logic Tests', () {
    group('getNextScheduledDate', () {
      test('should postpone from today to tomorrow', () {
        final testNow = DateTime(2024, 1, 15); // Monday
        final today = DateTime(2024, 1, 15); // Monday
        final tomorrow = DateTime(2024, 1, 16);
        
        final result = SwipeActionHandlerTestHelper.getNextScheduledDate(today, testNow: testNow);
        
        expect(result, equals(tomorrow));
      });

      test('should postpone from tomorrow to this week Saturday', () {
        final testNow = DateTime(2024, 1, 15); // Monday
        final tomorrow = DateTime(2024, 1, 16); // Tuesday
        final thisWeekSaturday = DateTime(2024, 1, 20); // Saturday
        
        final result = SwipeActionHandlerTestHelper.getNextScheduledDate(tomorrow, testNow: testNow);
        
        expect(result, equals(thisWeekSaturday));
      });

      test('should postpone from this week Saturday to end of month', () {
        final testNow = DateTime(2024, 1, 15); // Monday
        final thisWeekSaturday = DateTime(2024, 1, 20); // Saturday
        final endOfMonth = DateTime(2024, 1, 31); // End of January
        
        final result = SwipeActionHandlerTestHelper.getNextScheduledDate(thisWeekSaturday, testNow: testNow);
        
        expect(result, equals(endOfMonth));
      });

      test('should postpone from end of month to next month', () {
        final testNow = DateTime(2024, 1, 15); // Monday
        final endOfMonth = DateTime(2024, 1, 31); // End of January
        final nextMonth = DateTime(2024, 2, 1); // February 1st
        
        final result = SwipeActionHandlerTestHelper.getNextScheduledDate(endOfMonth, testNow: testNow);
        
        expect(result, equals(nextMonth));
      });

      test('should handle null current due date', () {
        final testNow = DateTime(2024, 1, 15); // Monday
        final tomorrow = DateTime(2024, 1, 16);
        
        final result = SwipeActionHandlerTestHelper.getNextScheduledDate(null, testNow: testNow);
        
        expect(result, equals(tomorrow));
      });

      test('should handle past due date', () {
        final testNow = DateTime(2024, 1, 15); // Monday
        final pastDate = DateTime(2024, 1, 10); // Past date
        final tomorrow = DateTime(2024, 1, 16);
        
        final result = SwipeActionHandlerTestHelper.getNextScheduledDate(pastDate, testNow: testNow);
        
        expect(result, equals(tomorrow));
      });
    });

    group('getThisWeekSaturday', () {
      test('should return this week Saturday when today is Monday', () {
        final monday = DateTime(2024, 1, 15); // Monday
        final expectedSaturday = DateTime(2024, 1, 20); // Saturday
        
        final result = SwipeActionHandlerTestHelper.getThisWeekSaturday(monday);
        
        expect(result, equals(expectedSaturday));
      });

      test('should return next week Saturday when today is Saturday', () {
        final saturday = DateTime(2024, 1, 20); // Saturday
        final expectedNextSaturday = DateTime(2024, 1, 27); // Next Saturday
        
        final result = SwipeActionHandlerTestHelper.getThisWeekSaturday(saturday);
        
        expect(result, equals(expectedNextSaturday));
      });

      test('should return this week Saturday when today is Friday', () {
        final friday = DateTime(2024, 1, 19); // Friday
        final expectedSaturday = DateTime(2024, 1, 20); // Saturday
        
        final result = SwipeActionHandlerTestHelper.getThisWeekSaturday(friday);
        
        expect(result, equals(expectedSaturday));
      });
    });

    group('getEndOfMonth', () {
      test('should return correct end of month for January', () {
        final january = DateTime(2024, 1, 15);
        final expectedEnd = DateTime(2024, 1, 31);
        
        final result = SwipeActionHandlerTestHelper.getEndOfMonth(january);
        
        expect(result, equals(expectedEnd));
      });

      test('should return correct end of month for February (leap year)', () {
        final february = DateTime(2024, 2, 15); // 2024 is a leap year
        final expectedEnd = DateTime(2024, 2, 29);
        
        final result = SwipeActionHandlerTestHelper.getEndOfMonth(february);
        
        expect(result, equals(expectedEnd));
      });

      test('should return correct end of month for February (non-leap year)', () {
        final february = DateTime(2023, 2, 15); // 2023 is not a leap year
        final expectedEnd = DateTime(2023, 2, 28);
        
        final result = SwipeActionHandlerTestHelper.getEndOfMonth(february);
        
        expect(result, equals(expectedEnd));
      });

      test('should return correct end of month for April (30 days)', () {
        final april = DateTime(2024, 4, 15);
        final expectedEnd = DateTime(2024, 4, 30);
        
        final result = SwipeActionHandlerTestHelper.getEndOfMonth(april);
        
        expect(result, equals(expectedEnd));
      });
    });
  });
}
