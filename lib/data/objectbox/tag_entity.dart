import 'package:objectbox/objectbox.dart';

@Entity()
class TagEntity {
  TagEntity({
    this.obxId = 0,
    required this.id,
    required this.slug,
    required this.kindIndex,
    required this.localizedLabelsJson,
  });

  @Id()
  int obxId;

  @Unique()
  String id;

  String slug;

  int kindIndex;

  /// 存储 JSON 序列化后的本地化标签映射。
  String localizedLabelsJson;
}
