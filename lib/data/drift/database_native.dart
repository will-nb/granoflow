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
    final file = File(p.join(dbFolder.path, 'granoflow.db'));
    return NativeDatabase(file);
  });
}
