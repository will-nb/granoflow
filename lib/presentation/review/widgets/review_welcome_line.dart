import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import 'review_content_line.dart';

/// 欢迎语行组件
class ReviewWelcomeLine extends StatelessWidget {
  const ReviewWelcomeLine({
    super.key,
    required this.dayCount,
    this.visible = true,
  });

  /// 用户使用 app 的天数
  final int dayCount;

  /// 是否可见
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n.reviewWelcomeMessage(dayCount);

    return ReviewContentLine(
      text: text,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      topSpacing: 32,
      bottomSpacing: 24,
      visible: visible,
    );
  }
}

