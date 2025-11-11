import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/database_adapter.dart';
import '../../data/database/drift_adapter.dart';

/// 数据库类型枚举
enum DatabaseType {
  drift,
}

/// 数据库配置管理（当前使用 Drift）
class DatabaseConfig {
  DatabaseConfig._();

  static DatabaseType? _cachedType;

  /// 获取当前数据库类型
  ///
  /// 优先级：
  /// 1. 环境变量 DATABASE_TYPE（开发环境）
  /// 2. SharedPreferences 存储的值（生产环境）
  /// 3. 默认值 drift
  static Future<DatabaseType> get current async {
    if (_cachedType != null) {
      return _cachedType!;
    }

    // 1. 优先从环境变量读取（开发环境）
    if (kDebugMode) {
      const envType = String.fromEnvironment('DATABASE_TYPE');
      if (envType.isNotEmpty && envType.toLowerCase() == 'drift') {
        _cachedType = DatabaseType.drift;
        return _cachedType!;
      }
    }

    // 2. 从 SharedPreferences 读取（生产环境）
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedType = prefs.getString('database_type');
      if (storedType != null && storedType.toLowerCase() == 'drift') {
        _cachedType = DatabaseType.drift;
        return _cachedType!;
      }
    } catch (e) {
      // 如果读取失败，使用默认值
      debugPrint('Failed to read database_type from SharedPreferences: $e');
    }

    // 3. 默认值 drift
    _cachedType = DatabaseType.drift;
    return _cachedType!;
  }

  /// 设置数据库类型（并保存到 SharedPreferences）
  static Future<void> setType(DatabaseType type) async {
    _cachedType = type;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('database_type', type.name);
    } catch (e) {
      debugPrint('Failed to save database_type to SharedPreferences: $e');
    }
  }

  /// 创建对应的 DatabaseAdapter
  ///
  /// 注意：Drift 数据库实例将在 DriftAdapter 中创建
  static Future<DatabaseAdapter> createAdapter() async {
    final type = await current;

    switch (type) {
      case DatabaseType.drift:
        return DriftAdapter();
    }
  }

  /// 清除缓存的数据库类型（用于测试）
  static void clearCache() {
    _cachedType = null;
  }
}
