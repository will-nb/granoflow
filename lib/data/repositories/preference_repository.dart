import '../models/preference.dart';

abstract class PreferenceRepository {
  Stream<Preference> watch();

  Future<Preference> load();

  Future<void> update(PreferenceUpdate payload);
}
