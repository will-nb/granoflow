import 'package:shared_preferences/shared_preferences.dart';

/// 置顶任务状态持久化服务
/// 
/// 使用 SharedPreferences 存储置顶任务ID，支持保存和恢复
class PinnedTaskPersistenceService {
  PinnedTaskPersistenceService();

  static const String _keyPinnedTaskId = 'pinned_task_id';
  static const String _keyLastUpdated = 'pinned_task_last_updated';

  /// 保存置顶任务ID
  Future<void> savePinnedTaskId(String? taskId) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (taskId != null) {
      await prefs.setString(_keyPinnedTaskId, taskId);
      await prefs.setString(_keyLastUpdated, DateTime.now().toIso8601String());
    } else {
      await prefs.remove(_keyPinnedTaskId);
      await prefs.remove(_keyLastUpdated);
    }
  }

  /// 恢复置顶任务ID
  /// 
  /// 返回恢复的任务ID，如果状态无效或不存在则返回 null
  Future<String?> loadPinnedTaskId() async {
    final prefs = await SharedPreferences.getInstance();
    final taskId = prefs.getString(_keyPinnedTaskId);
    final lastUpdatedStr = prefs.getString(_keyLastUpdated);
    
    // 检查状态是否过期（超过 24 小时）
    if (taskId != null && lastUpdatedStr != null) {
      try {
        final lastUpdated = DateTime.parse(lastUpdatedStr);
        final now = DateTime.now();
        if (now.difference(lastUpdated).inHours > 24) {
          // 状态过期，清除
          await clearPinnedTaskId();
          return null;
        }
      } catch (e) {
        // 解析失败，清除状态
        await clearPinnedTaskId();
        return null;
      }
    }
    
    return taskId;
  }

  /// 清除持久化状态
  Future<void> clearPinnedTaskId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPinnedTaskId);
    await prefs.remove(_keyLastUpdated);
  }
}

