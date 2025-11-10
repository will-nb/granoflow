import 'package:objectbox/objectbox.dart';

@Entity()
class PreferenceEntity {
  PreferenceEntity({
    this.obxId = 0,
    required this.id,
    required this.localeCode,
    required this.themeModeIndex,
    required this.fontScaleLevel,
    required this.clockTickSoundEnabled,
    required this.updatedAt,
  });

  @Id()
  int obxId;

  @Unique()
  String id;

  String localeCode;

  int themeModeIndex;

  String fontScaleLevel;

  bool clockTickSoundEnabled;

  @Property(type: PropertyType.date)
  DateTime updatedAt;
}
