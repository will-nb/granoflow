import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

// 条件导入：Web 和移动端使用不同的数据库实现
import 'database_web.dart' if (dart.library.io) 'database_native.dart' as db_impl;

import 'tables/tasks.dart';
import 'tables/projects.dart';
import 'tables/milestones.dart';
import 'tables/task_logs.dart';
import 'tables/project_logs.dart';
import 'tables/milestone_logs.dart';
import 'tables/tags.dart';
import 'tables/task_templates.dart';
import 'tables/focus_sessions.dart';
import 'tables/preferences.dart';
import 'tables/seed_import_logs.dart';
import '../models/task.dart';
import 'converters.dart';

part 'database.g.dart';

/// Drift 数据库类
@DriftDatabase(
  tables: [
    Tasks,
    Projects,
    Milestones,
    TaskLogs,
    ProjectLogs,
    MilestoneLogs,
    Tags,
    TaskTemplates,
    FocusSessions,
    Preferences,
    SeedImportLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  /// 单例实例
  static AppDatabase? _instance;

  /// 获取数据库单例实例
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // 启用外键约束
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 未来版本升级逻辑
      },
    );
  }

  /// 关闭数据库连接
  Future<void> closeDatabase() async {
    await close();
    _instance = null;
  }
}

/// 创建数据库连接
LazyDatabase _openConnection() {
  // 使用条件导入，根据平台自动选择正确的实现
  if (kIsWeb) {
    return createWebDatabase();
  } else {
    return createNativeDatabase();
  }
}
