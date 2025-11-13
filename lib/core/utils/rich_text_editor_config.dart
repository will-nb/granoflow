import 'dart:convert';
import 'package:flutter/services.dart';

/// 富文本编辑器配置数据模型
class RichTextEditorConfig {
  const RichTextEditorConfig({
    required this.toolbarMode,
    required this.previewMaxLines,
    required this.autoSaveDebounce,
  });

  /// 工具栏模式："basic" 或 "full"
  final String toolbarMode;

  /// 预览最大行数（1-10）
  final int previewMaxLines;

  /// 自动保存防抖延迟（毫秒，100-2000）
  final int autoSaveDebounce;

  /// 从 JSON 解析配置
  factory RichTextEditorConfig.fromJson(Map<String, dynamic> json) {
    return RichTextEditorConfig(
      toolbarMode: json['toolbarMode'] as String? ?? 'full',
      previewMaxLines: json['previewMaxLines'] as int? ?? 3,
      autoSaveDebounce: json['autoSaveDebounce'] as int? ?? 300,
    );
  }

  /// 默认配置
  factory RichTextEditorConfig.defaultConfig() {
    return const RichTextEditorConfig(
      toolbarMode: 'full',
      previewMaxLines: 3,
      autoSaveDebounce: 300,
    );
  }
}

/// 富文本编辑器配置加载服务
/// 
/// 单例模式，负责加载和解析配置文件
/// 参考 HeatmapColorService 的实现方式
class RichTextEditorConfigService {
  RichTextEditorConfigService._();

  static RichTextEditorConfigService? _instance;
  static RichTextEditorConfig? _config;

  /// 获取单例实例
  static Future<RichTextEditorConfigService> getInstance() async {
    _instance ??= RichTextEditorConfigService._();
    if (_config == null) {
      await _instance!._loadConfig();
    }
    return _instance!;
  }

  /// 加载配置文件
  Future<void> _loadConfig() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/config/rich_text_editor.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _config = RichTextEditorConfig.fromJson(json);
    } catch (e) {
      // 如果加载失败，使用默认配置
      _config = RichTextEditorConfig.defaultConfig();
    }
  }

  /// 获取配置
  /// 
  /// 如果配置未加载，会先加载配置
  Future<RichTextEditorConfig> getConfig() async {
    if (_config == null) {
      await _loadConfig();
    }
    return _config ?? RichTextEditorConfig.defaultConfig();
  }
}

