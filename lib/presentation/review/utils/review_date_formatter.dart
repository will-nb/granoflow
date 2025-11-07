import 'package:intl/intl.dart';

/// 回顾页面日期格式化工具
class ReviewDateFormatter {
  /// 格式化为回顾页面日期格式：x年x月x日
  /// 例如：2024年1月15日
  static String formatReviewDate(DateTime date) {
    final localDate = date.toLocal();
    return DateFormat('y年M月d日', 'zh_CN').format(localDate);
  }
}

