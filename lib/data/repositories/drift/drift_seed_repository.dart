import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../database/database_adapter.dart';
import '../../drift/database.dart';
import '../../drift/converters.dart';
import '../seed_repository.dart';

/// Drift 版本的 SeedRepository 实现
class DriftSeedRepository implements SeedRepository {
  DriftSeedRepository(this._adapter);

  final DatabaseAdapter _adapter;

  /// 获取 AppDatabase 实例
  AppDatabase get _db => AppDatabase.instance;

  @override
  Future<bool> wasImported(String version) async {
    debugPrint('🔵 DriftSeedRepository: Checking if version $version was imported...');
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.seedImportLogs)
        ..where((t) => t.version.equals(version));
      final result = await query.getSingleOrNull();
      final wasImported = result != null;
      debugPrint('🔵 DriftSeedRepository: Version $version wasImported: $wasImported');
      if (result != null) {
        debugPrint('🔵 DriftSeedRepository: Import record found - id: ${result.id}, importedAt: ${result.importedAt}');
      } else {
        // 检查是否有其他版本的记录
        final allLogs = await _db.select(_db.seedImportLogs).get();
        debugPrint('🔵 DriftSeedRepository: Total import logs in database: ${allLogs.length}');
        if (allLogs.isNotEmpty) {
          debugPrint('🔵 DriftSeedRepository: Existing import versions: ${allLogs.map((l) => l.version).join(", ")}');
        }
      }
      return wasImported;
    });
  }

  @override
  Future<void> importSeeds(SeedPayload payload) async {
    // 这个方法保留接口兼容性，但实际导入逻辑在 SeedImportService 中完成
    // 这里只需要记录导入日志即可
    await recordVersion(payload.version);
  }

  @override
  Future<String?> latestVersion() async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.seedImportLogs)
        ..orderBy([(t) => OrderingTerm(expression: t.importedAt, mode: OrderingMode.desc)])
        ..limit(1);
      final result = await query.getSingleOrNull();
      return result?.version;
    });
  }

  @override
  Future<void> recordVersion(String version) async {
    debugPrint('🔵 DriftSeedRepository: Recording version $version...');
    await _adapter.writeTransaction(() async {
      // 检查是否已存在该版本的记录
      final existingQuery = _db.select(_db.seedImportLogs)
        ..where((t) => t.version.equals(version));
      final existing = await existingQuery.getSingleOrNull();

      if (existing != null) {
        debugPrint('🔵 DriftSeedRepository: Updating existing import record for version $version');
        // 更新现有记录的导入时间
        await (_db.update(_db.seedImportLogs)..where((t) => t.id.equals(existing.id)))
            .write(SeedImportLogsCompanion(
          importedAt: Value(DateTime.now()),
        ));
        debugPrint('🔵 DriftSeedRepository: Import record updated successfully');
      } else {
        debugPrint('🔵 DriftSeedRepository: Creating new import record for version $version');
        // 创建新记录
        final logId = generateUuid();
        await _db.into(_db.seedImportLogs).insert(SeedImportLogsCompanion.insert(
          id: logId,
          version: version,
          importedAt: DateTime.now(),
        ));
        debugPrint('🔵 DriftSeedRepository: Import record created successfully (id: $logId)');
      }
    });
  }

  @override
  Future<void> clearVersion(String version) async {
    debugPrint('🔵 DriftSeedRepository: Clearing version $version...');
    await _adapter.writeTransaction(() async {
      final query = _db.select(_db.seedImportLogs)
        ..where((t) => t.version.equals(version));
      final entities = await query.get();
      debugPrint('🔵 DriftSeedRepository: Found ${entities.length} import log(s) for version $version');
      for (final entity in entities) {
        debugPrint('🔵 DriftSeedRepository: Deleting import log - id: ${entity.id}, version: ${entity.version}, importedAt: ${entity.importedAt}');
        await (_db.delete(_db.seedImportLogs)..where((t) => t.id.equals(entity.id))).go();
      }
      debugPrint('🔵 DriftSeedRepository: Version $version cleared successfully');
    });
  }
}
