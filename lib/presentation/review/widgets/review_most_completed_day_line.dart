import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../data/models/review_data.dart';
import '../utils/review_date_formatter.dart';
import '../utils/review_time_formatter.dart';
import 'review_content_line.dart';

/// 完成根任务最多的一天行组件
class ReviewMostCompletedDayLine extends StatelessWidget {
  const ReviewMostCompletedDayLine({
    super.key,
    required this.mostCompletedDay,
    this.visible = true,
  });

  /// 完成根任务最多的一天信息
  final ReviewMostCompletedDayInfo mostCompletedDay;

  /// 是否可见
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = ReviewDateFormatter.formatReviewDate(mostCompletedDay.date);
    final totalHours = ReviewTimeFormatter.formatHours(mostCompletedDay.totalHours);
    final text = l10n.reviewMostCompletedRootTasksDayMessage(
      date,
      mostCompletedDay.taskCount,
      totalHours,
    );

    return ReviewContentLine(
      text: text,
      fontSize: 18,
      fontWeight: FontWeight.w400,
      topSpacing: 0,
      bottomSpacing: 24,
      visible: visible,
    );
  }
}

