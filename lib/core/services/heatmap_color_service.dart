import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 热力图阈值配置
class HeatmapThresholds {
  const HeatmapThresholds({
    required this.low,
    required this.mediumLow,
    required this.medium,
  });

  final int low;
  final int mediumLow;
  final int medium;

  factory HeatmapThresholds.fromJson(Map<String, dynamic> json) {
    return HeatmapThresholds(
      low: json['low'] as int,
      mediumLow: json['mediumLow'] as int,
      medium: json['medium'] as int,
    );
  }
}

/// 热力图颜色计算服务
class HeatmapColorService {
  HeatmapColorService._();

  static HeatmapColorService? _instance;
  static HeatmapThresholds? _thresholds;

  /// 获取单例实例
  static Future<HeatmapColorService> getInstance() async {
    _instance ??= HeatmapColorService._();
    if (_thresholds == null) {
      await _instance!._loadThresholds();
    }
    return _instance!;
  }

  /// 加载阈值配置
  Future<void> _loadThresholds() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/config/calendar_review_heatmap_thresholds.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _thresholds = HeatmapThresholds.fromJson(json);
    } catch (e) {
      // 如果加载失败，使用默认值
      _thresholds = const HeatmapThresholds(
        low: 30,
        mediumLow: 60,
        medium: 120,
      );
    }
  }

  /// 根据专注时长和主题模式返回对应的颜色
  /// 
  /// [minutes] 专注时长（分钟）
  /// [brightness] 主题亮度（Brightness.light 或 Brightness.dark）
  /// 返回颜色，无数据时返回浅灰色
  Color getHeatmapColor(int minutes, Brightness brightness) {
    final thresholds = _thresholds ?? const HeatmapThresholds(
      low: 30,
      mediumLow: 60,
      medium: 120,
    );

    // 无数据：浅灰色
    if (minutes == 0) {
      return brightness == Brightness.light
          ? Colors.grey.shade200
          : Colors.grey.shade800;
    }

    // 低强度：浅绿色
    if (minutes < thresholds.low) {
      return brightness == Brightness.light
          ? Colors.green.shade100.withValues(alpha: 0.6)
          : Colors.green.shade900.withValues(alpha: 0.6);
    }

    // 中低强度：中绿色
    if (minutes < thresholds.mediumLow) {
      return brightness == Brightness.light
          ? Colors.green.shade300.withValues(alpha: 0.7)
          : Colors.green.shade800.withValues(alpha: 0.7);
    }

    // 中强度：深绿色
    if (minutes < thresholds.medium) {
      return brightness == Brightness.light
          ? Colors.green.shade500.withValues(alpha: 0.8)
          : Colors.green.shade700.withValues(alpha: 0.8);
    }

    // 高强度：最深绿色
    return brightness == Brightness.light
        ? Colors.green.shade700.withValues(alpha: 0.9)
        : Colors.green.shade600.withValues(alpha: 0.9);
  }
}
