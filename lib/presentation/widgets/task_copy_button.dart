import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../generated/l10n/app_localizations.dart';

/// 任务复制按钮组件
/// 风格与标签和截止日期编辑器一致，用于复制任务标题
class TaskCopyButton extends StatelessWidget {
  const TaskCopyButton({
    super.key,
    required this.taskTitle,
  });

  final String taskTitle;

  Future<void> _copyToClipboard(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: taskTitle));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.taskCopySuccess),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;

    return InkWell(
      onTap: () => _copyToClipboard(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.copy_outlined,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context).taskCopyTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

