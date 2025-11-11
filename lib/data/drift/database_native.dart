// 移动端数据库连接实现
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 移动端数据库连接
LazyDatabase createDatabase() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    
    // 确保目录存在
    if (!await dbFolder.exists()) {
      await dbFolder.create(recursive: true);
    }
    
    final file = File(p.join(dbFolder.path, 'granoflow.db'));
    
    // 如果文件已存在，确保文件可写
    // 在 macOS/Linux 上，设置文件权限为可读写
    if (await file.exists() && (Platform.isLinux || Platform.isMacOS)) {
      try {
        // 设置文件权限为 644 (rw-r--r--)
        final result = await Process.run('chmod', ['644', file.path]);
        if (result.exitCode != 0) {
          print('Warning: Failed to set file permissions: ${result.stderr}');
        }
      } catch (e) {
        // 忽略权限设置错误，继续尝试打开数据库
        print('Warning: Error setting file permissions: $e');
      }
    }
    
    // 创建数据库连接，使用 setup 参数配置数据库
    // NativeDatabase 会自动创建文件（如果不存在），并确保可写
    try {
      final database = NativeDatabase(
        file,
        setup: (database) {
          // 配置数据库模式
          database.execute('PRAGMA journal_mode = WAL');
          database.execute('PRAGMA foreign_keys = ON');
        },
      );
      return database;
    } catch (e) {
      // 如果打开失败，尝试删除文件并重新创建
      print('Error opening database: $e');
      if (await file.exists()) {
        try {
          await file.delete();
          print('Deleted existing database file, will recreate on next open');
        } catch (deleteError) {
          print('Error deleting database file: $deleteError');
        }
      }
      // 重新创建数据库连接
      return NativeDatabase(
        file,
        setup: (database) {
          database.execute('PRAGMA journal_mode = WAL');
          database.execute('PRAGMA foreign_keys = ON');
        },
      );
    }
  });
}
