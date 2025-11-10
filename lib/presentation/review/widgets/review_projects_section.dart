import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../data/models/review_data.dart';
import 'review_content_line.dart';

/// 项目列表区域组件
class ReviewProjectsSection extends StatelessWidget {
  const ReviewProjectsSection({
    super.key,
    required this.projects,
    this.visible = true,
  });

  /// 活跃项目列表
  final List<ReviewProjectInfo> projects;

  /// 是否可见
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 项目数量提示行
        ReviewContentLine(
          text: l10n.reviewActiveProjectsCountMessage(projects.length),
          fontSize: 20,
          fontWeight: FontWeight.w400,
          topSpacing: 24,
          bottomSpacing: 16,
          visible: visible,
        ),

        // 项目列表
        ...projects.map((project) {
          final text = l10n.reviewProjectItemFormat(
            project.name,
            project.taskCount,
          );
          return ReviewContentLine(
            text: text,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            topSpacing: 0,
            bottomSpacing: 8,
            visible: visible,
          );
        }),
      ],
    );
  }
}

/// 无项目提示组件
class ReviewNoProjectsLine extends StatelessWidget {
  const ReviewNoProjectsLine({
    super.key,
    this.visible = true,
  });

  /// 是否可见
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ReviewContentLine(
      text: l10n.reviewNoProjectsMessage,
      fontSize: 20,
      fontWeight: FontWeight.w400,
      topSpacing: 24,
      bottomSpacing: 24,
      visible: visible,
    );
  }
}

