import '../../data/models/node.dart';

/// 种子导入工具类
/// 提供种子数据解析相关的工具方法
class SeedImportUtils {
  /// 解析 dueAt 字段（支持相对天数或绝对日期）
  static DateTime? parseDueAt(dynamic dueAt) {
    if (dueAt == null) {
      // 无 dueAt：默认今天 23:59:59
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    if (dueAt is int) {
      // 相对天数：计算绝对日期（设置为目标日期的 23:59:59）
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final targetDay = today.add(Duration(days: dueAt));
      return DateTime(targetDay.year, targetDay.month, targetDay.day, 23, 59, 59);
    } else if (dueAt is DateTime) {
      // 绝对日期：直接使用
      return dueAt;
    }

    return null;
  }

  /// 解析节点状态字符串为 NodeStatus 枚举
  static NodeStatus? parseNodeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return NodeStatus.pending;
      case 'finished':
        return NodeStatus.finished;
      case 'deleted':
        return NodeStatus.deleted;
      default:
        return null;
    }
  }
}
