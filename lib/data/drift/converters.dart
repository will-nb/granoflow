import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';

/// List<String> 类型转换器（用于 tags 字段）
class ListStringTypeConverter extends TypeConverter<List<String>, String> {
  const ListStringTypeConverter();

  @override
  List<String> fromSql(String fromDb) {
    return listStringFromJson(fromDb);
  }

  @override
  String toSql(List<String> value) {
    return listStringToJson(value);
  }
}

/// Map<String, String> 类型转换器（用于 localizedLabelsJson 字段）
class MapStringStringTypeConverter extends TypeConverter<Map<String, String>, String> {
  const MapStringStringTypeConverter();

  @override
  Map<String, String> fromSql(String fromDb) {
    return mapStringStringFromJson(fromDb);
  }

  @override
  String toSql(Map<String, String> value) {
    return mapStringStringToJson(value);
  }
}

/// UUID 生成器（统一使用 Uuid().v4()）
const _uuid = Uuid();

/// 生成 UUID v4
String generateUuid() => _uuid.v4();

/// TaskStatus 枚举转换器
int taskStatusToIndex(TaskStatus status) => status.index;

TaskStatus taskStatusFromIndex(int index) {
  if (index < 0 || index >= TaskStatus.values.length) {
    return TaskStatus.inbox;
  }
  return TaskStatus.values[index];
}

/// ProjectStatus 枚举转换器（使用 TaskStatus）
int projectStatusToIndex(TaskStatus status) => status.index;

TaskStatus projectStatusFromIndex(int index) {
  if (index < 0 || index >= TaskStatus.values.length) {
    return TaskStatus.inbox;
  }
  return TaskStatus.values[index];
}

/// List<String> 转换器（用于 tags 字段）
String listStringToJson(List<String> list) => jsonEncode(list);

List<String> listStringFromJson(String json) {
  try {
    final decoded = jsonDecode(json) as List;
    return decoded.map((e) => e.toString()).toList();
  } catch (e) {
    return [];
  }
}

/// Map<String, String> 转换器（用于 localizedLabelsJson 字段）
String mapStringStringToJson(Map<String, String> map) => jsonEncode(map);

Map<String, String> mapStringStringFromJson(String json) {
  try {
    final decoded = jsonDecode(json) as Map;
    return decoded.map((key, value) => MapEntry(key.toString(), value.toString()));
  } catch (e) {
    return {};
  }
}
