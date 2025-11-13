import 'package:flutter/foundation.dart';

/// 节点状态枚举
enum NodeStatus {
  pending,   // 待处理
  finished,  // 已完成
  deleted,   // 已删除
}

/// 节点数据模型
@immutable
class Node {
  const Node({
    required this.id,
    required this.taskId,
    required this.title,
    required this.status,
    required this.sortIndex,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
  });

  final String id;
  final String? parentId;
  final String taskId;
  final String title;
  final NodeStatus status;
  final double sortIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  Node copyWith({
    String? id,
    String? parentId,
    String? taskId,
    String? title,
    NodeStatus? status,
    double? sortIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Node(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      status: status ?? this.status,
      sortIndex: sortIndex ?? this.sortIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Node &&
        other.id == id &&
        other.parentId == parentId &&
        other.taskId == taskId &&
        other.title == title &&
        other.status == status &&
        other.sortIndex == sortIndex &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        parentId,
        taskId,
        title,
        status,
        sortIndex,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'Node(id: $id, title: $title, status: $status)';
}

