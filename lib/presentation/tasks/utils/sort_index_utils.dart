import '../../../core/constants/task_constants.dart';

/// Calculates a sort index between two existing indices.
/// 
/// If both indices are provided and sufficiently different, returns the midpoint.
/// If they're too close, increments the after index.
/// If only one is provided, offsets by 1000 from that index.
/// If neither is provided, returns the default sort index.
double calculateSortIndex(double? before, double? after) {
  if (before != null && after != null) {
    if ((after - before).abs() > 0.0001) {
      return (before + after) / 2;
    }
    return after + 1;
  }
  if (before == null && after != null) {
    return after - 1000;
  }
  if (after == null && before != null) {
    return before + 1000;
  }
  return TaskConstants.DEFAULT_SORT_INDEX;
}

