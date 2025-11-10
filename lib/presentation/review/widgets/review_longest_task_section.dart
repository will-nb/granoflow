import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../data/models/review_data.dart';
import '../utils/review_date_formatter.dart';
import 'review_content_line.dart';

/// 最长已完成任务区域组件
class ReviewLongestCompletedTaskSection extends StatelessWidget {
  const ReviewLongestCompletedTaskSection({
    super.key,
    required this.taskInfo,
    this.visible = true,
  });

  /// 最长已完成任务信息
  final ReviewLongestTaskInfo taskInfo;

  /// 是否可见
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 只显示超过2小时的任务
    if (taskInfo.totalMinutes < 120) {
      return const SizedBox.shrink();
    }

    final date = ReviewDateFormatter.formatReviewDate(taskInfo.task.createdAt);
    final taskText = l10n.reviewLongestCompletedTaskMessage(
      date,
      taskInfo.task.title,
      taskInfo.totalMinutes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 任务信息行
        ReviewContentLine(
          text: taskText,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          topSpacing: 0,
          bottomSpacing: 16,
          visible: visible,
        ),

        // 完成消息行
        ReviewContentLine(
          text: l10n.reviewLongestCompletedTaskCompletionMessage,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          topSpacing: 0,
          bottomSpacing: 16,
          visible: visible,
        ),

        // 任务分析（如果有）
        if (taskInfo.task.description != null &&
            taskInfo.task.description!.isNotEmpty)
          ReviewContentLine(
            text: '任务分析：${taskInfo.task.description}',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            topSpacing: 0,
            bottomSpacing: 16,
            visible: visible,
          ),

        // 子任务列表
        if (taskInfo.subtasks.isNotEmpty) ...[
          ...taskInfo.subtasks.map((subtask) {
            final subtaskText = '子任务：${subtask.title}';
            final analysisText = subtask.description != null &&
                    subtask.description!.isNotEmpty
                ? '：${subtask.description}'
                : '';
            return ReviewContentLine(
              text: '$subtaskText$analysisText',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              topSpacing: 0,
              bottomSpacing: 8,
              visible: visible,
            );
          }),
        ],
      ],
    );
  }
}

/// 无长已完成任务提示组件
class ReviewNoLongCompletedTaskLine extends StatelessWidget {
  const ReviewNoLongCompletedTaskLine({
    super.key,
    this.visible = true,
  });

  /// 是否可见
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ReviewContentLine(
      text: l10n.reviewNoLongCompletedTaskMessage,
      fontSize: 18,
      fontWeight: FontWeight.w400,
      topSpacing: 0,
      bottomSpacing: 24,
      visible: visible,
    );
  }
}

/// 最长归档任务区域组件
class ReviewLongestArchivedTaskSection extends StatelessWidget {
  const ReviewLongestArchivedTaskSection({
    super.key,
    required this.taskInfo,
    this.visible = true,
  });

  /// 最长归档任务信息
  final ReviewLongestTaskInfo taskInfo;

  /// 是否可见
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 只显示有时间的任务
    if (taskInfo.totalMinutes <= 0) {
      return const SizedBox.shrink();
    }

    final date = ReviewDateFormatter.formatReviewDate(taskInfo.task.createdAt);
    final taskText = l10n.reviewLongestCompletedTaskMessage(
      date,
      taskInfo.task.title,
      taskInfo.totalMinutes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 任务信息行
        ReviewContentLine(
          text: taskText,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          topSpacing: 0,
          bottomSpacing: 16,
          visible: visible,
        ),

        // 归档消息行
        ReviewContentLine(
          text: l10n.reviewLongestArchivedTaskMessage,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          topSpacing: 0,
          bottomSpacing: 24,
          visible: visible,
        ),
      ],
    );
  }
}

