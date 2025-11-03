/// 字体大小级别枚举
///
/// 用于表示用户选择的字体大小级别，而非具体数值。
/// 具体数值会根据屏幕方向动态计算。
enum FontScaleLevel {
  /// 小
  small,

  /// 中（默认）
  medium,

  /// 大
  large,

  /// 超大
  xlarge;

  /// 从字符串转换为枚举值
  /// 
  /// 用于从数据库读取时转换。
  /// 如果字符串无效，返回默认值 medium。
  static FontScaleLevel fromString(String value) {
    return FontScaleLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FontScaleLevel.medium,
    );
  }
}
