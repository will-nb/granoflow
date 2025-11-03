import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 时间显示格式
enum TimeDisplayFormat {
  /// 相对时间格式（如"2 天前"、"刚刚"）
  relative,
  
  /// 绝对时间格式（精确到分钟，如"2025年11月3日 14:30"）
  absolute,
}

/// 完成时间或归档时间显示组件
/// 
/// 显示任务的完成时间（endedAt）或归档时间（archivedAt）
/// 格式化为相对时间（如"2 天前"）或绝对时间（精确到分钟）
class CompletionTimeDisplay extends StatelessWidget {
  const CompletionTimeDisplay({
    super.key,
    required this.dateTime,
    this.style,
    this.format = TimeDisplayFormat.relative,
  });

  /// 要显示的时间（完成时间或归档时间）
  final DateTime? dateTime;

  /// 文本样式
  final TextStyle? style;

  /// 显示格式（相对时间或绝对时间）
  final TimeDisplayFormat format;

  @override
  Widget build(BuildContext context) {
    if (dateTime == null) {
      // 如果没有时间，显示占位文本
      return Text(
        AppLocalizations.of(context).noCompletionTime,
        style: style ?? Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final date = dateTime!;

    // 根据格式类型显示
    final String timeText;
    if (format == TimeDisplayFormat.absolute) {
      // 绝对时间格式：精确到分钟
      // 中文格式：2025年11月3日 14:30
      // 英文格式：Nov 3, 2025 14:30
      final dateFormat = DateFormat.yMMMd(locale.toString()).add_Hm();
      timeText = dateFormat.format(date);
    } else {
      // 相对时间格式（原有逻辑）
      final now = DateTime.now();
      final difference = now.difference(date);
      final daysDiff = difference.inDays;
      final hoursDiff = difference.inHours;
      final minutesDiff = difference.inMinutes;

      if (daysDiff == 0) {
        // 今天完成
        if (hoursDiff == 0) {
          if (minutesDiff == 0) {
            timeText = l10n.completedJustNow; // "刚刚"
          } else {
            timeText = l10n.completedMinutesAgo(minutesDiff); // "X 分钟前"
          }
        } else {
          timeText = l10n.completedHoursAgo(hoursDiff); // "X 小时前"
        }
      } else if (daysDiff == 1) {
        timeText = l10n.completedYesterday; // "昨天"
      } else if (daysDiff < 7) {
        timeText = l10n.completedDaysAgo(daysDiff); // "X 天前"
      } else if (daysDiff < 30) {
        final weeks = (daysDiff / 7).floor();
        timeText = l10n.completedWeeksAgo(weeks); // "X 周前"
      } else if (daysDiff < 365) {
        final months = (daysDiff / 30).floor();
        timeText = l10n.completedMonthsAgo(months); // "X 个月前"
      } else {
        // 超过一年，显示绝对日期
        if (date.year == now.year) {
          // 同一年，显示月日：如 "10月29日" 或 "Oct 29"
          final dateFormat = DateFormat.MMMd(locale.toString());
          timeText = dateFormat.format(date);
        } else {
          // 不同年，显示年月日：如 "2025年10月29日" 或 "Oct 29, 2025"
          final dateFormat = DateFormat.yMMMd(locale.toString());
          timeText = dateFormat.format(date);
        }
      }
    }

    return Text(
      timeText,
      style: style ?? Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
    );
  }
}

