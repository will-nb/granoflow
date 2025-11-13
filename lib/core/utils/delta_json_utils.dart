import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

/// Delta JSON 工具类
/// 
/// 负责 Delta JSON 的解析、序列化和验证
/// 重要：parseDeltaJson 方法中，如果解析失败（包括旧格式的纯文本），
/// 直接返回 null，不进行任何转换。这是设计决策：不考虑数据迁移，老数据全部废弃。
class DeltaJsonUtils {
  DeltaJsonUtils._();

  /// 解析 Delta JSON 字符串
  /// 
  /// [jsonString] Delta JSON 字符串或 null
  /// 返回 Delta JSON 字符串（如果有效），如果解析失败（包括旧格式的纯文本）返回 null
  /// 不抛出异常，失败时返回 null（不进行任何转换）
  /// 注意：此方法主要用于验证，实际使用 jsonToDocument
  static String? parseDeltaJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    // 验证是否为有效的 Delta JSON
    if (isValidDeltaJson(jsonString)) {
      return jsonString;
    }
    
    // 解析失败（包括旧格式的纯文本），返回 null
    // 这是设计决策：不考虑数据迁移，老数据全部废弃
    return null;
  }

  /// 将 Delta 对象序列化为 JSON 字符串
  /// 
  /// [delta] Delta 对象（通过 Document.toDelta() 获得）
  /// 返回 JSON 字符串
  static String deltaToJson(dynamic delta) {
    // 将 Delta 转换为 Document，然后序列化
    final document = Document.fromDelta(delta);
    return documentToJson(document);
  }

  /// 将 Document 对象序列化为 JSON 字符串
  /// 
  /// [document] Document 对象
  /// 返回 JSON 字符串
  static String documentToJson(Document document) {
    // Document 的 JSON 表示是节点列表，通过 toPlainText 和 toDelta 来获取
    // 我们使用 toDelta() 获取 Delta，然后序列化
    final delta = document.toDelta();
    // Delta 的 toJson() 返回 List，我们将其序列化为 JSON 字符串
    return jsonEncode(delta.toJson());
  }

  /// 将 JSON 字符串解析为 Document 对象
  /// 
  /// [jsonString] Delta JSON 字符串或 null
  /// 返回 Document 对象，如果解析失败返回空 Document
  static Document jsonToDocument(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return Document();
    }

    try {
      final json = jsonDecode(jsonString);
      
      // Document.fromJson 接受 List
      if (json is List) {
        return Document.fromJson(json);
      } else if (json is Map && json.containsKey('ops') && json['ops'] is List) {
        // 如果是 {"ops": [...]} 格式，提取 ops 数组
        return Document.fromJson(json['ops'] as List);
      } else {
        // 无法解析，返回空 Document
        return Document();
      }
    } catch (e) {
      // 解析失败，返回空 Document
      return Document();
    }
  }

  /// 验证是否为有效的 Delta JSON
  /// 
  /// [jsonString] 要验证的字符串或 null
  /// 返回 true 如果是有效的 Delta JSON，否则返回 false
  static bool isValidDeltaJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return false;
    }

    try {
      final json = jsonDecode(jsonString);
      
      // 尝试解析为 Document
      if (json is List) {
        Document.fromJson(json);
        return true;
      } else if (json is Map && json.containsKey('ops') && json['ops'] is List) {
        Document.fromJson(json['ops'] as List);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
}

