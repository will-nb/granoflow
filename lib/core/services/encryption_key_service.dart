import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 加密密钥服务
/// 
/// 负责生成、保存、加载和验证加密密钥
class EncryptionKeyService {
  EncryptionKeyService();

  static const String _keyEncryptionKey = 'encryption_key';
  static const _uuid = Uuid();

  /// 检查密钥是否存在
  Future<bool> hasKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyEncryptionKey);
  }

  /// 生成新的 UUID v4 密钥
  /// 
  /// 返回格式：xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  String generateKey() {
    return _uuid.v4();
  }

  /// 保存密钥到 SharedPreferences
  Future<void> saveKey(String key) async {
    if (!isValidKey(key)) {
      throw ArgumentError('Invalid encryption key');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEncryptionKey, key);
  }

  /// 加载密钥
  /// 
  /// 如果密钥不存在，返回 null
  Future<String?> loadKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEncryptionKey);
  }

  /// 获取密钥，如果不存在则生成并保存
  /// 
  /// 用于首次启动时初始化密钥
  Future<String> getOrGenerateKey() async {
    final existingKey = await loadKey();
    if (existingKey != null && isValidKey(existingKey)) {
      return existingKey;
    }
    
    final newKey = generateKey();
    await saveKey(newKey);
    return newKey;
  }

  /// 验证密钥是否有效
  /// 
  /// 验证规则：
  /// - 密钥不能为空
  /// - 密钥长度必须恰好是 36 个字符（不能多一位或少一位）
  /// - 密钥不能全为零（即不能是 00000000-0000-0000-0000-000000000000）
  /// - 密钥必须是有效的 UUID v4 格式（32 个十六进制字符 + 4 个连字符）
  bool isValidKey(String? key) {
    if (key == null || key.isEmpty) {
      return false;
    }

    // 检查长度：UUID v4 格式必须是恰好 36 个字符
    // 格式：xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    // 8 + 1 + 4 + 1 + 4 + 1 + 4 + 1 + 12 = 36
    if (key.length != 36) {
      return false;
    }

    // 检查是否为全零（移除连字符和所有0后应该还有字符）
    final digitsOnly = key.replaceAll('-', '');
    if (digitsOnly.replaceAll('0', '').isEmpty) {
      return false;
    }

    // 检查 UUID v4 格式：xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    // 总共 36 个字符（32 个十六进制字符 + 4 个连字符）
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    
    return uuidRegex.hasMatch(key);
  }
}

