import 'package:flutter/foundation.dart';

import '../../data/models/milestone.dart';
import '../../data/models/project.dart';

@immutable
class ProjectMilestoneBlueprint {
  const ProjectMilestoneBlueprint({
    required this.title,
    this.dueDate,
    this.tags = const <String>[],
    this.description,
  });

  final String title;
  final DateTime? dueDate;
  final List<String> tags;
  final String? description;
}

@immutable
class ProjectBlueprint {
  const ProjectBlueprint({
    required this.title,
    required this.dueDate,
    this.description,
    this.tags = const <String>[],
    this.milestones = const <ProjectMilestoneBlueprint>[],
  });

  final String title;
  final DateTime dueDate;
  final String? description;
  final List<String> tags;
  final List<ProjectMilestoneBlueprint> milestones;
}

@immutable
class ProjectMilestoneSelection {
  const ProjectMilestoneSelection._(this.project, this.milestone);

  const ProjectMilestoneSelection.project(Project project)
    : this._(project, null);

  const ProjectMilestoneSelection.milestone({
    required Project project,
    required Milestone milestone,
  }) : this._(project, milestone);

  const ProjectMilestoneSelection.remove() : project = null, milestone = null;

  final Project? project;
  final Milestone? milestone;

  bool get isRemove => project == null && milestone == null;
  bool get hasMilestone => milestone != null;
}
