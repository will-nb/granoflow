import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/milestone.dart';
import '../../../../data/models/task.dart';
import '../../../../generated/l10n/app_localizations.dart';

/// 里程碑操作确认结果
class MilestoneActionConfirmResult {
  const MilestoneActionConfirmResult({
    required this.includeSubItems,
  });

  /// 是否包含子项（任务）
  final bool includeSubItems;
}

/// 统一的两次确认弹窗
/// 
/// [milestone] 里程碑对象
/// 
/// 返回:
/// - `MilestoneActionConfirmResult`: 用户确认并选择包含子项
/// - `null`: 用户取消
Future<MilestoneActionConfirmResult?> confirmMilestoneDelete(
  BuildContext context,
  WidgetRef ref,
  Milestone milestone,
) async {
  final l10n = AppLocalizations.of(context);
  
  try {
    // 获取 TaskRepository
    final taskRepository = await ref.read(taskRepositoryProvider.future);
    
    // 使用 Future.timeout 包裹数据获取操作，超时时间 3 秒
    final tasks = await taskRepository
        .listTasksByMilestoneId(milestone.id)
        .timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            throw TimeoutException('获取任务列表超时');
          },
        );
    
    // 统计活跃任务（pending、doing、paused 状态）
    final activeTasks = tasks.where((t) =>
        t.status == TaskStatus.pending ||
        t.status == TaskStatus.doing ||
        t.status == TaskStatus.paused).length;
    
    // 如果没有活跃任务，跳过第一次确认，直接进入第二次确认
    if (activeTasks == 0) {
      final confirmed = await _showSecondConfirmDialog(
        context,
        l10n,
        milestone,
        includeSubItems: false,
      );
      
      if (confirmed == null) {
        // 用户取消
        return null;
      }
      
      return const MilestoneActionConfirmResult(includeSubItems: false);
    }
    
    // 如果有活跃任务，显示第一次确认弹窗
    final includeSubItems = await _showFirstConfirmDialog(
      context,
      l10n,
      milestone,
      activeTasks,
    );
    
    if (includeSubItems == null) {
      // 用户取消
      return null;
    }
    
    // 第二次确认：最终确认
    final confirmed = await _showSecondConfirmDialog(
      context,
      l10n,
      milestone,
      includeSubItems: includeSubItems,
    );
    
    if (confirmed == null) {
      // 用户取消
      return null;
    }
    
    return MilestoneActionConfirmResult(includeSubItems: includeSubItems);
  } on TimeoutException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.operationFailed}: ${e.message}')),
      );
    }
    return null;
  } catch (e, stackTrace) {
    debugPrint('Failed to get tasks for milestone: $e\n$stackTrace');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.operationFailed)),
      );
    }
    return null;
  }
}

/// 第一次确认弹窗
Future<bool?> _showFirstConfirmDialog(
  BuildContext context,
  AppLocalizations l10n,
  Milestone milestone,
  int activeTaskCount,
) async {
  // 构建富文本内容
  final richText = _buildRichText(
    context,
    milestone.title,
    activeTaskCount,
  );
  
  return await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.milestoneDeleteFirstConfirmTitle),
      content: richText,
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(null),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonNo),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.commonYes),
        ),
      ],
    ),
  );
}

/// 第二次确认弹窗
Future<bool?> _showSecondConfirmDialog(
  BuildContext context,
  AppLocalizations l10n,
  Milestone milestone, {
  required bool includeSubItems,
}) async {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  // 选择文案
  String message;
  if (includeSubItems) {
    message = l10n.milestoneDeleteSecondConfirmMessageWithTasks(milestone.title);
  } else {
    message = l10n.milestoneDeleteSecondConfirmMessageNoActiveTasks(milestone.title);
  }
  
  return await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图标容器
          _buildIconContainer(context),
          const SizedBox(height: 16),
          // 标题
          Text(
            l10n.milestoneDeleteSecondConfirmTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // 内容
          Text(message),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
          ),
          child: Text(l10n.milestoneDeleteConfirmButton),
        ),
      ],
    ),
  );
}

/// 构建图标容器
Widget _buildIconContainer(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  return TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0.0, end: 1.0),
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) {
      return Opacity(
        opacity: value,
        child: Transform.scale(
          scale: 0.8 + (value * 0.2), // 从 0.8 到 1.0
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.errorContainer,
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 40,
              color: colorScheme.onErrorContainer,
            ),
          ),
        ),
      );
    },
  );
}

/// 构建富文本内容
Widget _buildRichText(
  BuildContext context,
  String milestoneTitle,
  int taskCount,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  // 创建强调样式
  final emphasisStyle = TextStyle(
    color: colorScheme.primary,
    fontWeight: FontWeight.w600,
  );
  
  // 直接构建 TextSpan，不依赖已替换的文本
  return Text.rich(
    TextSpan(
      children: [
        const TextSpan(text: '里程碑「'),
        TextSpan(
          text: milestoneTitle,
          style: emphasisStyle,
        ),
        TextSpan(
          text: '」下还有 ',
        ),
        TextSpan(
          text: '$taskCount',
          style: emphasisStyle,
        ),
        const TextSpan(
          text: ' 个活跃任务。\n\n您想将它们一起删除吗？',
        ),
      ],
    ),
  );
}

