import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/error_banner.dart';

/// 回顾页面错误状态组件
class ReviewErrorState extends StatelessWidget {
  const ReviewErrorState({
    super.key,
    required this.error,
    this.onRetry,
  });

  /// 错误信息
  final String error;

  /// 重试回调
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ErrorBanner(message: error),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: Text(l10n.commonRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

