// Helper functions for YAML testing

// 辅助函数：安全地将 YamlMap 转换为 Map<String, dynamic>
Map<String, dynamic> yamlToMap(dynamic yaml) {
  if (yaml is Map) {
    return Map<String, dynamic>.from(yaml);
  }
  return <String, dynamic>{};
}

// 辅助函数：安全地将 YamlList 转换为 List<dynamic>
List<dynamic> yamlToList(dynamic yaml) {
  if (yaml is List) {
    return List<dynamic>.from(yaml);
  }
  return <dynamic>[];
}
