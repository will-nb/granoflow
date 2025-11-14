import 'package:flutter/material.dart';
import '../../../data/models/task.dart';
import '../../tasks/quick_tasks/quick_add_sheet.dart';

/// QuickAddSheet 显示助手
/// 
/// 统一处理 QuickAddSheet 的显示逻辑，封装 showModalBottomSheet 的调用
class QuickAddSheetHelper {
  const QuickAddSheetHelper._();

  /// 显示快速添加任务弹窗
  /// 
  /// [context] BuildContext
  /// [section] 任务分区（可选，如果为 null 则表示不预设分区，日期需要用户选择）
  /// [defaultDate] 默认日期（可选，如果提供则优先使用此日期）
  /// 
  /// 返回 QuickAddResult，如果用户取消则返回 null
  static Future<QuickAddResult?> showQuickAddSheet(
    BuildContext context, {
    TaskSection? section,
    DateTime? defaultDate,
  }) async {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final maxHeight = isLandscape 
        ? mediaQuery.size.height * 0.5  // 横屏时限制最大高度为屏幕高度的 50%
        : double.infinity;  // 竖屏时自适应内容高度

    // 弹出底部弹窗，让用户输入任务信息
    final result = await showModalBottomSheet<QuickAddResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // QuickAddSheet
              QuickAddSheet(
                section: section,
                defaultDate: defaultDate,
              ),
              // 底部安全区域
              SizedBox(height: mediaQuery.viewPadding.bottom + 20),
            ],
          ),
        ),
      ),
    );

    return result;
  }
}

