import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import 'review_content_line.dart';

/// 结束语行组件
class ReviewClosingLine extends StatelessWidget {
  const ReviewClosingLine({
    super.key,
    this.visible = true,
  });

  /// 是否可见
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n.reviewClosingMessage;

    return ReviewContentLine(
      text: text,
      fontSize: 18,
      fontWeight: FontWeight.w400,
      topSpacing: 0,
      bottomSpacing: 32,
      visible: visible,
    );
  }
}

