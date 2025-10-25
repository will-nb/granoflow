import 'package:isar/isar.dart';

part 'seed_import_log_entity.g.dart';

@collection
class SeedImportLogEntity {
  SeedImportLogEntity();

  Id id = 0;

  late String version;

  late DateTime importedAt;
}
