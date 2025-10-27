import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

/// YAML 测试工具类
/// 
/// ⚠️ 重要警告：
/// 这些测试用于检测 YAML 文档与代码的不一致。
/// 
/// 如果测试失败，AI 应该：
/// 1. 明确报告哪些地方不一致
/// 2. 列出 YAML 中的定义 vs 代码中的实际情况
/// 3. 退出并等待人工判断
/// 
/// AI 不应该：
/// ❌ 直接修改代码使其符合 YAML
/// ❌ 直接修改 YAML 使其符合代码
/// ❌ 猜测哪一边是"正确"的
/// 
/// 原因：AI 很难确定是 YAML 过时了还是代码写错了，需要人工判断。
class YamlTestUtils {
  /// 项目根目录
  static final String projectRoot = _findProjectRoot();
  
  /// 查找项目根目录
  static String _findProjectRoot() {
    var current = Directory.current;
    while (current.path != current.parent.path) {
      if (File(path.join(current.path, 'pubspec.yaml')).existsSync()) {
        return current.path;
      }
      current = current.parent;
    }
    return Directory.current.path;
  }
  
  /// 加载 YAML 文件
  static YamlMap loadYamlFile(String relativePath) {
    final file = File(path.join(projectRoot, relativePath));
    
    if (!file.existsSync()) {
      fail('❌ YAML 文件不存在: $relativePath\n'
          '   这可能意味着:\n'
          '   1. 文件被意外删除\n'
          '   2. 文件路径错误\n'
          '   3. 还未创建此 YAML 文档\n'
          '   \n'
          '   👉 请人工检查并创建正确的 YAML 文档');
    }
    
    try {
      final content = file.readAsStringSync();
      final yaml = loadYaml(content);
      
      if (yaml is! YamlMap) {
        fail('❌ YAML 文件格式错误: $relativePath\n'
            '   期望: 顶层为 Map 结构\n'
            '   实际: ${yaml.runtimeType}\n'
            '   \n'
            '   👉 请人工检查 YAML 文件格式');
      }
      
      return yaml as YamlMap;
    } catch (e) {
      fail('❌ YAML 文件解析失败: $relativePath\n'
          '   错误: $e\n'
          '   \n'
          '   👉 请人工检查 YAML 语法是否正确');
    }
  }
  
  /// 查找所有指定类型的 YAML 文件
  static List<File> findYamlFiles(String category) {
    final dir = Directory(path.join(projectRoot, 'documents/architecture', category));
    
    if (!dir.existsSync()) {
      return [];
    }
    
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml'))
        .toList();
  }
  
  /// 检查 Dart 文件是否存在
  static bool dartFileExists(String relativePath) {
    final file = File(path.join(projectRoot, relativePath));
    return file.existsSync();
  }
  
  /// 检查 i18n 键是否存在于 .arb 文件中
  static bool i18nKeyExists(String key) {
    final arbDir = Directory(path.join(projectRoot, 'lib/l10n'));
    
    if (!arbDir.existsSync()) {
      return false;
    }
    
    for (final file in arbDir.listSync().whereType<File>()) {
      if (file.path.endsWith('.arb')) {
        try {
          final content = file.readAsStringSync();
          if (content.contains('"$key"')) {
            return true;
          }
        } catch (_) {
          continue;
        }
      }
    }
    
    return false;
  }
  
  /// 检查设计令牌是否存在于 theme 文件中
  static bool designTokenExists(String token) {
    final themeDir = Directory(path.join(projectRoot, 'lib/core/theme'));
    
    if (!themeDir.existsSync()) {
      return false;
    }
    
    // 从 "OceanBreezeColorSchemes.errorDark" 提取 "errorDark"
    // 或从 "AppConstants.defaultPadding" 提取 "defaultPadding"
    final tokenName = token.contains('.') ? token.split('.').last : token;
    
    // 查找定义模式：
    // - static const Color tokenName
    // - static const double tokenName
    // - static const EdgeInsets tokenName
    // - final tokenName (对于主题类成员)
    final definePattern = RegExp(
      r'(static\s+const\s+(Color|double|EdgeInsets|TextStyle|FontWeight|BorderRadius)\s+' +
      tokenName +
      r'\s*=|final\s+' +
      tokenName +
      r'\s*=)',
      multiLine: true
    );
    
    for (final file in themeDir.listSync().whereType<File>()) {
      if (file.path.endsWith('.dart')) {
        try {
          final content = file.readAsStringSync();
          if (definePattern.hasMatch(content)) {
            return true;
          }
        } catch (_) {
          continue;
        }
      }
    }
    
    return false;
  }
  
  /// 安全地从 YAML 中获取字符串
  static String? getString(YamlMap yaml, String key) {
    final value = yaml[key];
    return value?.toString();
  }
  
  /// 安全地从 YAML 中获取列表
  static List<dynamic> getList(YamlMap yaml, String key) {
    final value = yaml[key];
    if (value is YamlList) {
      return value.toList();
    } else if (value is List) {
      return value;
    }
    return [];
  }
  
  /// 安全地从 YAML 中获取 Map
  static Map<String, dynamic> getMap(YamlMap yaml, String key) {
    final value = yaml[key];
    if (value is YamlMap) {
      return Map<String, dynamic>.from(value);
    } else if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }
  
  /// 输出测试警告信息
  static void printTestWarning() {
    print('');
    print('═' * 70);
    print('⚠️  YAML 一致性测试');
    print('═' * 70);
    print('');
    print('📋 测试目的：检测 YAML 文档与代码的不一致');
    print('');
    print('🤖 AI 行为规范：');
    print('   如果测试失败，AI 应该：');
    print('   ✅ 明确报告哪些地方不一致');
    print('   ✅ 列出 YAML 定义 vs 代码实际情况');
    print('   ✅ 退出并等待人工判断');
    print('');
    print('   AI 不应该：');
    print('   ❌ 直接修改代码使其符合 YAML');
    print('   ❌ 直接修改 YAML 使其符合代码');
    print('   ❌ 猜测哪一边是"正确"的');
    print('');
    print('💡 原因：');
    print('   AI 很难确定是 YAML 过时了还是代码写错了');
    print('   需要人工判断正确的源头');
    print('');
    print('═' * 70);
    print('');
  }
}

