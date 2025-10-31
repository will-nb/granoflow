/// Utility functions for formatting and truncating project/milestone text

/// Truncates project and milestone names to fit within character limits
/// 
/// [projectName] - The project name
/// [milestoneName] - The milestone name (optional, null if only project)
/// [maxProjectChars] - Maximum characters for project name (default: 12)
/// [maxMilestoneChars] - Maximum characters for milestone name (default: 12)
/// 
/// Returns formatted text:
/// - If milestone is null: returns truncated project name
/// - If milestone is provided: returns "projectName > milestoneName" with truncation
String truncateProjectMilestoneText({
  required String projectName,
  String? milestoneName,
  int maxProjectChars = 12,
  int maxMilestoneChars = 12,
}) {
  final truncatedProject = _truncateText(projectName, maxProjectChars);
  
  if (milestoneName == null || milestoneName.isEmpty) {
    return truncatedProject;
  }
  
  final truncatedMilestone = _truncateText(milestoneName, maxMilestoneChars);
  return '$truncatedProject > $truncatedMilestone';
}

/// Truncates text to specified length with ellipsis if needed
String _truncateText(String text, int maxLength) {
  if (text.length <= maxLength) {
    return text;
  }
  return '${text.substring(0, maxLength)}…';
}

