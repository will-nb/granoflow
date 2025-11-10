import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

import '../../database/database_adapter.dart';
import '../../database/objectbox_adapter.dart';
import '../../objectbox/seed_import_log_entity.dart';
import '../seed_repository.dart';

class ObjectBoxSeedRepository implements SeedRepository {
  const ObjectBoxSeedRepository(this._adapter);

  final DatabaseAdapter _adapter;
  static const _uuid = Uuid();

  ObjectBoxAdapter get _objectBoxAdapter {
    final adapter = _adapter;
    if (adapter is! ObjectBoxAdapter) {
      throw StateError('ObjectBoxSeedRepository requires ObjectBoxAdapter');
    }
    return adapter;
  }

  Box<SeedImportLogEntity> get _seedImportLogBox =>
      _objectBoxAdapter.store.box<SeedImportLogEntity>();

  @override
  Future<bool> wasImported(String version) async {
    return await _adapter.readTransaction(() async {
      final box = _seedImportLogBox;
      for (final entity in box.getAll()) {
        if (entity.version == version) {
          return true;
        }
      }
      return false;
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
      final box = _seedImportLogBox;
      final allLogs = box.getAll();
      if (allLogs.isEmpty) {
        return null;
      }
      // 找到最新的导入记录（按 importedAt 排序）
      SeedImportLogEntity? latest;
      for (final log in allLogs) {
        if (latest == null || log.importedAt.isAfter(latest.importedAt)) {
          latest = log;
        }
      }
      return latest?.version;
    });
  }

  @override
  Future<void> recordVersion(String version) async {
    await _adapter.writeTransaction(() async {
      final box = _seedImportLogBox;
      
      // 检查是否已存在该版本的记录
      SeedImportLogEntity? existing;
      for (final entity in box.getAll()) {
        if (entity.version == version) {
          existing = entity;
          break;
        }
      }
      
      if (existing != null) {
        // 更新现有记录的导入时间
        final updated = SeedImportLogEntity(
          obxId: existing.obxId,
          id: existing.id,
          version: version,
          importedAt: DateTime.now(),
        );
        box.put(updated);
      } else {
        // 创建新记录
        final logId = _uuid.v4();
        final entity = SeedImportLogEntity(
          id: logId,
          version: version,
          importedAt: DateTime.now(),
        );
        box.put(entity);
      }
    });
  }

  @override
  Future<void> clearVersion(String version) async {
    await _adapter.writeTransaction(() async {
      final box = _seedImportLogBox;
      final entitiesToRemove = <SeedImportLogEntity>[];
      for (final entity in box.getAll()) {
        if (entity.version == version) {
          entitiesToRemove.add(entity);
        }
      }
      for (final entity in entitiesToRemove) {
        box.remove(entity.obxId);
      }
    });
  }
}
