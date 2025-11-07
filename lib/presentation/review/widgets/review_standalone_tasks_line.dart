import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import 'review_content_line.dart';

/// 独立任务统计行组件
class ReviewStandaloneTasksLine extends StatelessWidget {
  const ReviewStandaloneTasksLine({
    super.key,
    required this.totalCount,
    required this.activeCount,
    required this.completedCount,
    required this.archivedCount,
    this.visible = true,
  });

  /// 独立任务总数
  final int totalCount;

  /// 正在进行的独立任务数量
  final int activeCount;

  /// 已完成的独立任务数量
  final int completedCount;

  /// 归档的独立任务数量
  final int archivedCount;

  /// 是否可见
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n.reviewStandaloneTasksMessage(
      totalCount,
      activeCount,
      completedCount,
      archivedCount,
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

