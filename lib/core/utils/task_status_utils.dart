import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';

/// 任务状态映射工具函数
/// 
/// 提供 TaskStatus 到可读文本的映射功能

/// 获取任务状态的显示文本
/// 
/// [status] 任务状态
/// [l10n] 本地化对象
/// 
/// 返回状态的可读文本：
/// - inbox: 收集箱
/// - pending: 列入清单
/// - doing: 进行中
/// - paused: 已暂停
/// - completedActive: 已完成
/// - archived: 已归档
/// - trashed: 丢弃到回收站
/// - pseudoDeleted: （不显示，伪删除状态）
String getTaskStatusDisplayText(
  TaskStatus status,
  AppLocalizations l10n,
) {
  switch (status) {
    case TaskStatus.inbox:
      return '收集箱';
    case TaskStatus.pending:
      return '列入清单';
    case TaskStatus.doing:
      return '进行中';
    case TaskStatus.paused:
      return '已暂停';
    case TaskStatus.completedActive:
      return '已完成';
    case TaskStatus.archived:
      return '已归档';
    case TaskStatus.trashed:
      return '丢弃到回收站';
    case TaskStatus.pseudoDeleted:
      // 伪删除状态不显示
      return '';
  }
}

