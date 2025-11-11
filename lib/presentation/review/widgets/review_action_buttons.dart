import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../utils/review_text_generator.dart';
import '../../../data/models/review_data.dart';

/// 回顾页面操作按钮组件
class ReviewActionButtons extends StatelessWidget {
  const ReviewActionButtons({
    super.key,
    required this.reviewData,
    this.onCopied,
    this.onExported,
  });

  /// 回顾数据
  final ReviewData reviewData;

  /// 复制成功回调
  final VoidCallback? onCopied;

  /// 导出成功回调
  final VoidCallback? onExported;

  /// 复制文章到剪贴板
  Future<void> _copyToClipboard(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final text = ReviewTextGenerator.generatePlainText(reviewData, l10n);
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.reviewCopiedMessage),
          duration: const Duration(seconds: 2),
        ),
      );
      onCopied?.call();
    }
  }

  /// 导出文章为文件
  Future<void> _exportToFile(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final text = ReviewTextGenerator.generateMarkdown(reviewData, l10n);
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final fileName = '回顾_$dateStr.md';

    try {
      // 创建临时文件
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(text, encoding: const SystemEncoding());

      // 分享文件
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: fileName,
      );

      if (context.mounted) {
        onExported?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reviewExportFailed(e.toString())),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 复制按钮
          ElevatedButton.icon(
            onPressed: () => _copyToClipboard(context),
            icon: const Icon(Icons.copy_outlined),
            label: Text(l10n.reviewCopyButton),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(width: 16),
          // 导出按钮
          OutlinedButton.icon(
            onPressed: () => _exportToFile(context),
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(l10n.reviewExportButton),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

