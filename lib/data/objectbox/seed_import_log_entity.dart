import 'package:objectbox/objectbox.dart';

@Entity()
class SeedImportLogEntity {
  SeedImportLogEntity({
    this.obxId = 0,
    required this.id,
    required this.version,
    required this.importedAt,
  });

  @Id()
  int obxId;

  @Unique()
  String id;

  String version;

  DateTime importedAt;
}
