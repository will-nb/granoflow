/// 拖拽相关视觉常量
/// 
/// 统一管理所有拖拽组件的视觉参数，确保 Tasks 和 Inbox 页面外观一致
class DragConstants {
  // 拖拽反馈效果
  static const double tiltAngle = 0.026; // ~1.5度
  static const double feedbackScale = 1.03; // 轻微放大
  static const double feedbackOpacity = 0.98; // 反馈透明度更实
  static const double draggingOpacity = 0.92; // 原位略透明
  static const double feedbackElevation = 8.0; // 中等阴影
  static const double feedbackWidth = 300.0; // 反馈宽度
  static const double feedbackPadding = 8.0; // 反馈内边距（文字和阴影边框的间距）
  
  // 动画时长
  static const Duration hoverAnimationDuration = Duration(milliseconds: 120);
  
  // 插入目标容错区间（用于移动让位动画）
  // 上下各 16 像素容错区间，确保用户可以轻松在两个任务之间插入
  static const double insertionToleranceZone = 16.0;
  
  // 插入目标标准高度（独立区域，不覆盖任务表面）
  // 设置为 8 像素，与任务卡片垂直 padding 一致，确保视觉间距协调
  // 注意：insertionToleranceZone 仍用于逻辑计算（拖拽位置检测），不影响视觉高度
  static const double insertionTargetHeight = 8.0;
  
  // 任务高度（用于让位动画和动态扩展插入目标）
  static const double taskHeight = 60.0; // 任务卡片高度（包括 padding）
  
  // 任务表面排除区（用于位置检测，上下各 16 像素）
  // 在任务边缘的16像素区域内，判定为插入排序而非移入任务
  static const double taskSurfaceExclusionZone = 16.0;
}
