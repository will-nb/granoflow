import '../../database/database_adapter.dart';
import '../seed_repository.dart';

class ObjectBoxSeedRepository implements SeedRepository {
  const ObjectBoxSeedRepository(this._adapter);

  final DatabaseAdapter _adapter;

  @override
  Future<void> importSeeds(SeedPayload payload) {
    throw UnimplementedError('ObjectBoxSeedRepository.importSeeds');
  }

  @override
  Future<String?> latestVersion() {
    throw UnimplementedError('ObjectBoxSeedRepository.latestVersion');
  }

  @override
  Future<void> recordVersion(String version) {
    throw UnimplementedError('ObjectBoxSeedRepository.recordVersion');
  }

  @override
  Future<bool> wasImported(String version) {
    throw UnimplementedError('ObjectBoxSeedRepository.wasImported');
  }
}
