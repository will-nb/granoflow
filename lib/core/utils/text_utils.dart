/// 文本处理工具类
/// 
/// 提供通用的文本处理功能，如截断、格式化等
class TextUtils {
  const TextUtils._();

  /// 截断文本到指定长度，如果超过长度则添加省略号
  /// 
  /// [text] 要截断的文本
  /// [maxLength] 最大长度
  /// [ellipsis] 省略号字符串，默认为 '...'
  /// 
  /// 返回截断后的文本，如果原文本长度不超过 maxLength，则返回原文本
  static String truncate(
    String text,
    int maxLength, {
    String ellipsis = '...',
  }) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}$ellipsis';
  }
}

