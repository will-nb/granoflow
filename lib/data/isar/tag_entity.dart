import 'package:isar/isar.dart';

import '../models/tag.dart';

part 'tag_entity.g.dart';

@collection
class TagEntity {
  TagEntity();

  Id id = 0;

  late String slug;

  @enumerated
  late TagKind kind;

  List<TagLocalizationEntry> localizedLabels = <TagLocalizationEntry>[];
}

@embedded
class TagLocalizationEntry {
  late String locale;
  late String label;
}
