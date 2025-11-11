import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// 导出加密服务
/// 
/// 负责：
/// - 生成 128-bit salt（16个字符，从62个字符集中选择：26个小写字母 + 26个大写字母 + 10个数字）
/// - 使用 PBKDF2 从用户密钥和 salt 派生加密密钥
/// - 使用 AES-256-GCM 加密/解密 title 和 description 字段
class ExportEncryptionService {
  ExportEncryptionService();

  /// 字符集：26个小写字母 + 26个大写字母 + 10个数字 = 62个字符
  static const String _charset =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// PBKDF2 迭代次数（标准推荐值：100000）
  static const int _pbkdf2Iterations = 100000;

  /// 生成 128-bit salt（16个字符）
  /// 
  /// 从62个字符集中随机选择16个字符
  String generateSalt() {
    final random = Random.secure();
    final salt = StringBuffer();
    for (int i = 0; i < 16; i++) {
      salt.write(_charset[random.nextInt(_charset.length)]);
    }
    return salt.toString();
  }

  /// 使用 PBKDF2 从用户密钥和 salt 派生加密密钥
  /// 
  /// 参数：
  /// - [userKey]: 用户设置的加密密钥（36字符UUID格式）
  /// - [salt]: 128-bit salt（16个字符）
  /// 
  /// 返回：256-bit (32字节) 加密密钥
  Uint8List deriveKey(String userKey, String salt) {
    // 将用户密钥和 salt 转换为字节
    final userKeyBytes = utf8.encode(userKey);
    final saltBytes = utf8.encode(salt);

    // 使用 PBKDF2-SHA256 派生密钥
    // 输出长度：32字节 (256-bit)
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(saltBytes, _pbkdf2Iterations, 32));

    // 派生密钥
    final derivedKey = pbkdf2.process(userKeyBytes);

    return Uint8List.fromList(derivedKey);
  }

  /// 使用 AES-256-GCM 加密文本
  /// 
  /// 参数：
  /// - [plaintext]: 要加密的文本
  /// - [key]: 256-bit 加密密钥（32字节）
  /// 
  /// 返回：加密后的数据（包含密文、nonce 和 tag），Base64 编码
  EncryptedData encrypt(String plaintext, Uint8List key) {
    if (plaintext.isEmpty) {
      // 空字符串直接返回空结果
      return EncryptedData(
        ciphertext: '',
        nonce: '',
        tag: '',
      );
    }

    // 将明文转换为字节
    final plaintextBytes = utf8.encode(plaintext);

    // 生成 12 字节的随机 nonce（GCM 推荐使用 12 字节）
    final random = Random.secure();
    final nonce = Uint8List(12);
    for (int i = 0; i < 12; i++) {
      nonce[i] = random.nextInt(256);
    }

    // 创建 AES-GCM 加密器
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true, // true = 加密模式
        AEADParameters(
          KeyParameter(key),
          128, // MAC 长度（128 位）
          nonce,
          Uint8List(0), // 无关联数据
        ),
      );

    // 加密
    final ciphertext = cipher.process(plaintextBytes);

    // GCM 模式：密文 = 实际密文 + MAC tag（16 字节）
    // 分离密文和 tag
    final actualCiphertext = ciphertext.sublist(0, ciphertext.length - 16);
    final tag = ciphertext.sublist(ciphertext.length - 16);

    // 返回 Base64 编码的数据
    return EncryptedData(
      ciphertext: base64Encode(actualCiphertext),
      nonce: base64Encode(nonce),
      tag: base64Encode(tag),
    );
  }

  /// 使用 AES-256-GCM 解密文本
  /// 
  /// 参数：
  /// - [encryptedData]: 加密后的数据（包含密文、nonce 和 tag）
  /// - [key]: 256-bit 加密密钥（32字节）
  /// 
  /// 返回：解密后的原始文本
  /// 
  /// 抛出异常：如果解密失败（密钥错误、数据损坏等）
  String decrypt(EncryptedData encryptedData, Uint8List key) {
    if (encryptedData.ciphertext.isEmpty) {
      // 空字符串直接返回
      return '';
    }

    try {
      // 解码 Base64
      final ciphertextBytes = base64Decode(encryptedData.ciphertext);
      final nonce = base64Decode(encryptedData.nonce);
      final tag = base64Decode(encryptedData.tag);

      // 合并密文和 tag（GCM 需要）
      final ciphertextWithTag = Uint8List(ciphertextBytes.length + tag.length);
      ciphertextWithTag.setRange(0, ciphertextBytes.length, ciphertextBytes);
      ciphertextWithTag.setRange(
        ciphertextBytes.length,
        ciphertextWithTag.length,
        tag,
      );

      // 创建 AES-GCM 解密器
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false, // false = 解密模式
          AEADParameters(
            KeyParameter(key),
            128, // MAC 长度（128 位）
            nonce,
            Uint8List(0), // 无关联数据
          ),
        );

      // 解密
      final plaintextBytes = cipher.process(ciphertextWithTag);

      // 转换为字符串
      return utf8.decode(plaintextBytes);
    } catch (e) {
      throw ExportDecryptionException(
        'Failed to decrypt data: ${e.toString()}',
      );
    }
  }
}

/// 加密数据模型
/// 
/// 包含密文、nonce 和认证标签（tag）
class EncryptedData {
  const EncryptedData({
    required this.ciphertext,
    required this.nonce,
    required this.tag,
  });

  /// 密文（Base64 编码）
  final String ciphertext;

  /// 初始化向量/随机数（Base64 编码）
  final String nonce;

  /// 认证标签（Base64 编码）
  final String tag;

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
        'ciphertext': ciphertext,
        'nonce': nonce,
        'tag': tag,
      };

  /// 从 JSON 创建
  factory EncryptedData.fromJson(Map<String, dynamic> json) => EncryptedData(
        ciphertext: json['ciphertext'] as String,
        nonce: json['nonce'] as String,
        tag: json['tag'] as String,
      );
}

/// 解密异常
class ExportDecryptionException implements Exception {
  ExportDecryptionException(this.message);

  final String message;

  @override
  String toString() => 'ExportDecryptionException: $message';
}

