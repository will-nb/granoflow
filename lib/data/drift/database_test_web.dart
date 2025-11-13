// Web 平台测试数据库实现
import 'package:drift/drift.dart';

/// 创建测试用的内存数据库
QueryExecutor createTestDatabase() {
  // Web 平台使用 WasmDatabase，但测试时可能需要特殊处理
  // 这里暂时返回一个占位实现，实际测试应该在 native 平台运行
  throw UnsupportedError('Test database not supported on Web platform');
}

