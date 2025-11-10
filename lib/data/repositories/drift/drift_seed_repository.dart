import 'dart:async';

import '../../database/database_adapter.dart';
import '../../drift/database.dart';
import '../../drift/tables/seed_import_logs.dart';
import '../../models/seed.dart';
import '../seed_repository.dart';

/// Drift 版本的 SeedRepository 实现
class DriftSeedRepository implements SeedRepository {
  DriftSeedRepository(this._adapter);

  final DatabaseAdapter _adapter;

  @override
  Future<bool> wasImported(String version) async {
    // TODO: 实现查询逻辑
    throw UnimplementedError('wasImported will be implemented');
  }

  @override
  Future<void> importSeeds(SeedPayload payload) async {
    // TODO: 实现导入逻辑
    throw UnimplementedError('importSeeds will be implemented');
  }

  @override
  Future<String?> latestVersion() async {
    // TODO: 实现查询逻辑
    throw UnimplementedError('latestVersion will be implemented');
  }

  @override
  Future<void> recordVersion(String version) async {
    // TODO: 实现记录逻辑
    throw UnimplementedError('recordVersion will be implemented');
  }

  @override
  Future<void> clearVersion(String version) async {
    // TODO: 实现清除逻辑
    throw UnimplementedError('clearVersion will be implemented');
  }
}
