import '../config/app_config.dart';

/// 功能开关管理器
/// 
/// 根据应用版本类型（Lite/Pro）管理功能开关
class FeatureManager {
  final AppConfig config;

  FeatureManager(this.config);

  /// Lite版本支持的功能
  static const Set<String> liteFeatures = {
    'tasks', // 任务管理
    'timer', // 番茄钟
    'projects', // 项目管理
    'milestones', // 里程碑
    'tags', // 标签
    'calendar_review', // 日历回顾
    'export', // 导出
    'import', // 导入
    'focus_flow', // 专注流程
  };

  /// Pro版本专有功能
  static const Set<String> proOnlyFeatures = {
    'advanced_analytics', // 高级分析
    'cloud_sync', // 云同步
    'in_app_purchase', // 内购订阅
    // 未来可以添加更多Pro功能
  };

  /// 检查功能是否启用
  /// 
  /// [feature] - 功能名称
  /// 返回 true 如果功能启用，否则返回 false
  bool isFeatureEnabled(String feature) {
    if (config.isLite) {
      return liteFeatures.contains(feature);
    }
    // Pro版本默认启用所有功能
    return true;
  }

  /// 检查是否为Pro专有功能
  bool isProOnlyFeature(String feature) {
    return proOnlyFeatures.contains(feature);
  }

  /// 获取所有启用的功能列表
  Set<String> get enabledFeatures {
    if (config.isLite) {
      return liteFeatures;
    }
    // Pro版本包含所有功能
    return {...liteFeatures, ...proOnlyFeatures};
  }
}

