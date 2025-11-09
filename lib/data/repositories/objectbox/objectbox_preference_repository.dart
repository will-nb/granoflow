import '../../database/database_adapter.dart';
import '../models/preference.dart';
import '../preference_repository.dart';

class ObjectBoxPreferenceRepository implements PreferenceRepository {
  const ObjectBoxPreferenceRepository(this._adapter);

  final DatabaseAdapter _adapter;

  @override
  Future<Preference> load() {
    throw UnimplementedError('ObjectBoxPreferenceRepository.load');
  }

  @override
  Future<void> update(PreferenceUpdate payload) {
    throw UnimplementedError('ObjectBoxPreferenceRepository.update');
  }

  @override
  Stream<Preference> watch() {
    throw UnimplementedError('ObjectBoxPreferenceRepository.watch');
  }
}
