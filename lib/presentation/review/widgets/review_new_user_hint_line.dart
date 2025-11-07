import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import 'review_content_line.dart';

/// 新用户提示行组件
class ReviewNewUserHintLine extends StatelessWidget {
  const ReviewNewUserHintLine({
    super.key,
    this.visible = true,
  });

  /// 是否可见
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n.reviewNewUserHint;

    return ReviewContentLine(
      text: text,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      topSpacing: 0,
      bottomSpacing: 24,
      visible: visible,
    );
  }
}

