// Web 平台数据库连接实现
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

/// Web 平台数据库连接
LazyDatabase createDatabase() {
  return LazyDatabase(() async {
    // 使用 WasmDatabase (IndexedDB)
    // 需要先初始化 sqlite3 wasm
    final sqlite3 = await WasmSqlite3.loadFromUrl(
      Uri.parse('sqlite3.wasm'),
    );
    return WasmDatabase(sqlite3: sqlite3, path: 'granoflow.db');
  });
}
