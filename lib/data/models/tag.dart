import 'package:flutter/foundation.dart';

enum TagKind { context, priority, special, urgency, importance, execution }

@immutable
class Tag {
  const Tag({
    required this.id,
    required this.slug,
    required this.kind,
    required this.localizedLabels,
  });

  final String id;
  final String slug;
  final TagKind kind;
  final Map<String, String> localizedLabels;

  String labelForLocale(String localeCode) {
    return localizedLabels[localeCode] ??
        localizedLabels[localeCode.split('_').first] ??
        localizedLabels['en'] ??
        slug;
  }
}
