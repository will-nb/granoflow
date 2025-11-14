import 'package:flutter/material.dart';

/// 语言和本地化相关的工具函数
class LocaleUtils {
  LocaleUtils._();

  /// 获取系统语言并映射到应用支持的语言代码
  /// 
  /// 映射规则：
  /// - `zh_CN` → `zh_CN`（简体中文-中国大陆）
  /// - `zh_HK` → `zh_HK`（繁体中文-香港）
  /// - `zh_TW`, `zh_MO` 等繁体中文变体 → `zh`（让 Flutter 自动回退到 `app_zh.arb`）
  /// - `zh` → `zh`（通用中文）
  /// - `en_*` → `en`（英语）
  /// - 其他不支持的语言 → `en`（默认回退）
  /// 
  /// 返回应用支持的语言代码字符串，格式为 `languageCode` 或 `languageCode_countryCode`
  static String getSystemLocaleCode() {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = systemLocale.languageCode;
    final countryCode = systemLocale.countryCode;

    // 构造完整的 locale 代码（如 zh_CN, zh_HK, en_US）
    final localeCode = countryCode != null
        ? '${languageCode}_$countryCode'
        : languageCode;

    // 映射到应用支持的语言代码
    return switch (localeCode) {
      // 精确匹配支持的语言
      final code when code == 'zh_CN' => 'zh_CN',
      final code when code == 'zh_HK' => 'zh_HK',
      // 繁体中文变体（台湾、澳门等）回退到通用中文
      final code when code.startsWith('zh_TW') || code.startsWith('zh_MO') => 'zh',
      // 其他中文变体回退到通用中文
      final code when code.startsWith('zh') => 'zh',
      // 英语变体
      final code when code.startsWith('en') => 'en',
      // 默认回退到英语
      _ => 'en',
    };
  }
}

