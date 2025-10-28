/// 拖拽相关视觉常量
/// 
/// 统一管理所有拖拽组件的视觉参数，确保 Tasks 和 Inbox 页面外观一致
class DragConstants {
  // 拖拽反馈效果
  static const double tiltAngle = 0.26; // 15度倾斜
  static const double feedbackScale = 1.05; // 放大倍数
  static const double feedbackOpacity = 0.5; // 反馈透明度
  static const double draggingOpacity = 0.5; // 拖拽时原位置透明度
  static const double feedbackElevation = 12.0; // 反馈阴影高度
  static const double feedbackWidth = 300.0; // 反馈宽度
  
  // 动画时长
  static const Duration hoverAnimationDuration = Duration(milliseconds: 150);
  
  // 插入线样式
  static const double insertionLineHeight = 3.0; // 插入线高度
  static const double insertionLineBlurRadius = 8.0; // 插入线模糊半径
  static const double insertionLineSpreadRadius = 2.0; // 插入线扩散半径
}
