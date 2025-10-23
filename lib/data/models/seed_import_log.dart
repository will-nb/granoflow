import 'package:flutter/foundation.dart';

@immutable
class SeedImportLog {
  const SeedImportLog({
    required this.id,
    required this.version,
    required this.importedAt,
  });

  final int id;
  final String version;
  final DateTime importedAt;
}
