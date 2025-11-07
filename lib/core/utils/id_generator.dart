import 'package:uuid/uuid.dart';

/// 统一的ID生成工具
/// 
/// 所有业务ID（projectId、milestoneId、taskId）都使用UUID v4生成
/// 确保跨设备唯一性，避免ID冲突
class IdGenerator {
  IdGenerator._();
  
  static const _uuid = Uuid();
  
  /// 生成UUID v4格式的业务ID
  /// 
  /// 返回格式：xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  /// 例如：550e8400-e29b-41d4-a716-446655440000
  static String generateId() {
    return _uuid.v4();
  }
}
