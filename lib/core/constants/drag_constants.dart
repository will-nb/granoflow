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
  
  // 动画时长
  static const Duration hoverAnimationDuration = Duration(milliseconds: 120);
  
  // 插入线样式
  static const double insertionLineHeight = 2.0; // 更细
  static const double insertionLineBlurRadius = 0.0; // 无阴影
  static const double insertionLineSpreadRadius = 0.0; // 无扩散
  // 空闲命中区高度（透明，不改变视觉，但保证 DragTarget 可被命中）
  static const double insertionHitHeight = 1.0;
}
