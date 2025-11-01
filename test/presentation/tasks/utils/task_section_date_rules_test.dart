import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/tasks/utils/task_section_date_rules.dart';

void main() {
  group('TaskSectionDateRules', () {
    final base = DateTime(2025, 1, 31, 10, 20);

    test('startOfSection returns beginning of each section', () {
      expect(
        TaskSectionDateRules.startOfSection(TaskSection.today, now: base),
        DateTime(2025, 1, 31),
      );
      expect(
        TaskSectionDateRules.startOfSection(TaskSection.tomorrow, now: base),
        DateTime(2025, 2, 1),
      );
      expect(
        TaskSectionDateRules.startOfSection(TaskSection.thisWeek, now: base),
        DateTime(2025, 1, 31),
      );
      expect(
        TaskSectionDateRules.startOfSection(TaskSection.thisMonth, now: base),
        DateTime(2025, 1, 31),
      );
      expect(
        TaskSectionDateRules.startOfSection(TaskSection.later, now: base),
        DateTime(2025, 2, 1),
      );
    });

    test('fallbackDueDate delegates to startOfSection', () {
      expect(
        TaskSectionDateRules.fallbackDueDate(TaskSection.today, now: base),
        TaskSectionDateRules.startOfSection(TaskSection.today, now: base),
      );
    });

    test('resolveDueDateFromAnchor prefers anchor date', () {
      final anchor = DateTime(2025, 3, 10, 18, 30);
      expect(
        TaskSectionDateRules.resolveDueDateFromAnchor(
          TaskSection.thisMonth,
          anchor,
          now: base,
        ),
        anchor,
      );
    });

    test('resolveDueDateFromAnchor falls back when anchor missing', () {
      expect(
        TaskSectionDateRules.resolveDueDateFromAnchor(
          TaskSection.thisWeek,
          null,
          now: base,
        ),
        DateTime(2025, 1, 31),
      );
    });
  });
}
