/// 滑动动作类型枚举
/// 
/// 定义了所有支持的滑动动作类型，用于配置不同页面的滑动行为
enum SwipeActionType {
  /// 快速规划到今日任务
  quickPlan,
  
  /// 智能推迟任务
  postpone,
  
  /// 归档任务
  archive,
  
  /// 删除任务到回收站
  delete,
}
