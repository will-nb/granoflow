import '../../../data/models/task.dart';

/// Checks if two task lists are equal based on id and sortIndex.
/// 
/// Returns true if lists are identical references, or if they have the same
/// length and each task at the same index has the same id and sortIndex.
bool listEquals(List<Task> a, List<Task> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id || a[i].sortIndex != b[i].sortIndex) {
      return false;
    }
  }
  return true;
}

/// Checks if two task tree lists are equal based on task id and sortIndex.
/// 
/// Returns true if lists are identical references, or if they have the same
/// length and each tree node at the same index has a task with the same id and sortIndex.
bool treeEquals(List<TaskTreeNode> a, List<TaskTreeNode> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i].task.id != b[i].task.id ||
        a[i].task.sortIndex != b[i].task.sortIndex) {
      return false;
    }
  }
  return true;
}

