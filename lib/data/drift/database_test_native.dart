// Native 平台测试数据库实现
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// 创建测试用的内存数据库
QueryExecutor createTestDatabase() {
  return NativeDatabase.memory();
}

