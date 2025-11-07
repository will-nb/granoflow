import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import 'review_content_line.dart';

/// 统计信息行组件
class ReviewStatsLine extends StatelessWidget {
  const ReviewStatsLine({
    super.key,
    required this.projectCount,
    required this.taskCount,
    this.visible = true,
  });

  /// 项目总数
  final int projectCount;

  /// 任务总数
  final int taskCount;

  /// 是否可见
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n.reviewStatsMessage(projectCount, taskCount);

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

