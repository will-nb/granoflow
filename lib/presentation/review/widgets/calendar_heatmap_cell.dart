import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/heatmap_color_service.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/theme/ocean_breeze_color_schemes.dart';
import '../../../data/models/calendar_review_data.dart';

/// 自定义日历单元格，显示热力图和统计数据
class CalendarHeatmapCell extends ConsumerWidget {
  const CalendarHeatmapCell({
    super.key,
    required this.date,
    this.data,
    this.isSelected = false,
    this.isToday = false,
    this.showFocusMinutes = false,
  });

  final DateTime date;
  final DayReviewData? data;
  final bool isSelected;
  final bool isToday;
  final bool showFocusMinutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;
    final heatmapColorServiceAsync = ref.watch(heatmapColorServiceProvider);
    
    final heatmapColorService = heatmapColorServiceAsync.value;
    if (heatmapColorService == null) {
      return _buildCell(context, colorScheme, Colors.transparent);
    }

    final focusMinutes = data?.focusMinutes ?? 0;
    final backgroundColor = heatmapColorService.getHeatmapColor(
      focusMinutes,
      brightness,
    );

    return _buildCell(context, colorScheme, backgroundColor);
  }

  Widget _buildCell(
    BuildContext context,
    ColorScheme colorScheme,
    Color backgroundColor,
  ) {
    final completedCount = data?.completedTaskCount ?? 0;
    final focusMinutes = data?.focusMinutes ?? 0;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: isSelected
            ? Border.all(
                color: OceanBreezeColorSchemes.lakeCyan,
                width: 2,
              )
            : isToday
                ? Border.all(
                    color: colorScheme.primary,
                    width: 1.5,
                  )
                : null,
      ),
      child: Stack(
        children: [
          // 日期数字
          Center(
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: _getTextColor(context, backgroundColor),
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // 完成任务数标记（右上角）
          if (completedCount > 0)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: OceanBreezeColorSchemes.lakeCyan,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          // 专注时长文本（日视图时显示）
          if (showFocusMinutes && focusMinutes > 0)
            Positioned(
              bottom: 2,
              left: 2,
              right: 2,
              child: Text(
                '${focusMinutes}m',
                style: TextStyle(
                  color: _getTextColor(context, backgroundColor),
                  fontSize: 8,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Color _getTextColor(BuildContext context, Color backgroundColor) {
    // 如果背景色很浅，使用深色文字；否则使用浅色文字
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5
        ? Colors.black87
        : Colors.white;
  }
}
