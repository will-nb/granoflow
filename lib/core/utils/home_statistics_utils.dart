import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 首页统计相关的工具函数
class HomeStatisticsUtils {
  HomeStatisticsUtils._();

  /// 格式化专注时间
  /// 
  /// - 小于60分钟：返回 'X分钟'（如：'45分钟'）
  /// - 大于等于60分钟：返回 'X小时Y分钟'（如：'2小时30分钟'）
  /// - 如果分钟为0：省略分钟部分，返回 'X小时'（如：'2小时'）
  static String formatFocusMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes分钟';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours小时';
    }
    return '$hours小时$remainingMinutes分钟';
  }

  /// 格式化最佳日期
  /// 
  /// - 如果是本月：返回简短格式（如：'1月15日'）
  /// - 如果是其他月份：返回完整格式（如：'2023年12月25日'）
  /// - 使用 intl 包的 DateFormat 和本地化支持
  static String formatTopDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();

    // 如果是本月，显示简短格式
    if (date.year == now.year && date.month == now.month) {
      // 使用 MMMd 格式（如：'1月15日' 或 'Jan 15'）
      final formatter = DateFormat.MMMd(locale.toString());
      return formatter.format(date);
    } else {
      // 其他月份，显示完整格式（如：'2023年12月25日' 或 'Dec 25, 2023'）
      final formatter = DateFormat.yMMMd(locale.toString());
      return formatter.format(date);
    }
  }
}

