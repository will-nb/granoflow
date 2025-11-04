import 'dart:math';

/// ProjectService 辅助工具方法
/// 
/// 包含日期处理、ID生成等工具方法
class ProjectServiceHelpers {
  ProjectServiceHelpers({
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _random = Random();

  final DateTime Function() _clock;
  final Random _random;

  DateTime normalizeDueDate(DateTime localDate) {
    return DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      23,
      59,
      59,
      999,
    );
  }

  DateTime addOneYear(DateTime date) {
    final targetYear = date.year + 1;
    final isLeapTarget = _isLeapYear(targetYear);
    final isLeapDay = date.month == DateTime.february && date.day == 29;
    final adjustedDay = isLeapDay && !isLeapTarget ? 28 : date.day;
    return DateTime(
      targetYear,
      date.month,
      adjustedDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  bool _isLeapYear(int year) {
    if (year % 4 != 0) {
      return false;
    }
    if (year % 100 != 0) {
      return true;
    }
    return year % 400 == 0;
  }

  List<String> uniqueTags(Iterable<String> tags) {
    final result = <String>[];
    for (final tag in tags) {
      if (tag.isEmpty) continue;
      if (result.contains(tag)) continue;
      result.add(tag);
    }
    return result;
  }

  String generateProjectId(DateTime now) {
    final suffix = _random.nextInt(1 << 20).toRadixString(16).padLeft(5, '0');
    return 'prj-${now.millisecondsSinceEpoch}-$suffix';
  }

  String generateMilestoneId(DateTime now, int index) {
    final suffix = _random.nextInt(1 << 20).toRadixString(16).padLeft(5, '0');
    return 'mil-${now.millisecondsSinceEpoch}-$index-$suffix';
  }

  DateTime Function() get clock => _clock;
}

