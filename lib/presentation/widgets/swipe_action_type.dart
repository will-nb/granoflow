/// 滑动动作类型枚举
/// 
/// 定义了所有支持的滑动动作类型，用于配置不同页面的滑动行为
enum SwipeActionType {
  /// 快速规划到今日任务
  quickPlan,
  
  /// 智能推迟任务
  postpone,
  
  /// 完成任务
  complete,
  
  /// 归档任务
  archive,
  
  /// 删除任务到回收站
  delete,
  
  /// 提升为独立任务（将子任务提升为根任务）
  promoteToIndependent,
  
  /// 恢复任务（从回收站恢复到待办状态）
  restore,
  
  /// 永久删除任务（从回收站彻底删除）
  permanentDelete,
}
