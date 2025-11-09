import '../models/milestone.dart';
import '../models/task.dart';

abstract class MilestoneRepository {
  Stream<List<Milestone>> watchByProjectId(String projectId);

  Future<List<Milestone>> listByProjectId(String projectId);

  Future<Milestone?> findById(String id);

  Future<Milestone> create(MilestoneDraft draft);

  /// 使用指定的 milestoneId 创建里程碑（用于导入）
  /// 
  /// [draft] 里程碑草稿，其中的 milestoneId 将被忽略
  /// [milestoneId] 要使用的业务ID
  /// [createdAt] 创建时间（从导入数据中获取）
  /// [updatedAt] 更新时间（从导入数据中获取）
  Future<Milestone> createMilestoneWithId(
    MilestoneDraft draft,
    String milestoneId,
    DateTime createdAt,
    DateTime updatedAt,
  );

  Future<void> update(String id, MilestoneUpdate update);

  Future<void> delete(String id);

  /// 列出所有里程碑（用于导出）
  Future<List<Milestone>> listAll();
}
