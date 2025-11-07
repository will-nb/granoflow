import '../../../../data/models/review_data.dart';
import '../../../../generated/l10n/app_localizations.dart';
import 'review_date_formatter.dart';
import 'review_time_formatter.dart';

/// 回顾页面文本生成工具
/// 用于生成完整文章文本（纯文本和 Markdown 格式）
class ReviewTextGenerator {
  /// 生成纯文本格式的文章
  static String generatePlainText(ReviewData data, AppLocalizations l10n) {
    final buffer = StringBuffer();

    // 第一行：欢迎语
    buffer.writeln(l10n.reviewWelcomeMessage(data.welcome.dayCount));

    // 第二行：统计信息
    buffer.writeln(l10n.reviewStatsMessage(data.stats.projectCount, data.stats.taskCount));

    // 新用户提示（条件显示）
    if (_shouldShowNewUserHint(data)) {
      buffer.writeln(l10n.reviewNewUserHint);
    }

    // 项目相关行
    if (data.stats.projectCount == 0) {
      buffer.writeln(l10n.reviewNoProjectsMessage);
    } else {
      final activeProjectCount = data.projects.length;
      if (activeProjectCount > 0) {
        buffer.writeln(l10n.reviewActiveProjectsCountMessage(activeProjectCount));
        for (final project in data.projects) {
          buffer.writeln(l10n.reviewProjectItemFormat(project.name, project.taskCount));
        }
      }
    }

    // 独立任务统计
    if (data.standaloneTasks.totalCount > 0) {
      buffer.writeln(l10n.reviewStandaloneTasksMessage(
        data.standaloneTasks.totalCount,
        data.standaloneTasks.activeCount,
        data.standaloneTasks.completedCount,
        data.standaloneTasks.archivedCount,
      ));
    }

    // 最长已完成任务
    if (data.longestCompletedTask != null &&
        data.longestCompletedTask!.totalMinutes >= 120) {
      final task = data.longestCompletedTask!.task;
      final date = ReviewDateFormatter.formatReviewDate(task.createdAt);
      buffer.writeln(l10n.reviewLongestCompletedTaskMessage(
        date,
        task.title,
        data.longestCompletedTask!.totalMinutes,
      ));
      buffer.writeln(l10n.reviewLongestCompletedTaskCompletionMessage);

      // 任务分析
      if (task.description != null && task.description!.isNotEmpty) {
        buffer.writeln('任务分析：${task.description}');
      }

      // 子任务列表
      if (data.longestCompletedTask!.subtasks.isNotEmpty) {
        for (final subtask in data.longestCompletedTask!.subtasks) {
          final subtaskText = '子任务：${subtask.title}';
          final subtaskAnalysis = subtask.description != null &&
                  subtask.description!.isNotEmpty
              ? '：${subtask.description}'
              : '';
          buffer.writeln('$subtaskText$subtaskAnalysis');
        }
      }
    } else {
      buffer.writeln(l10n.reviewNoLongCompletedTaskMessage);
    }

    // 完成根任务最多的一天
    if (data.mostCompletedDay != null) {
      final date = ReviewDateFormatter.formatReviewDate(data.mostCompletedDay!.date);
      final totalHours = ReviewTimeFormatter.formatHours(data.mostCompletedDay!.totalHours);
      buffer.writeln(l10n.reviewMostCompletedRootTasksDayMessage(
        date,
        data.mostCompletedDay!.taskCount,
        totalHours,
      ));
    }

    // 最长归档任务
    if (data.longestArchivedTask != null &&
        data.longestArchivedTask!.totalMinutes > 0) {
      final task = data.longestArchivedTask!.task;
      final date = ReviewDateFormatter.formatReviewDate(task.createdAt);
      buffer.writeln(l10n.reviewLongestCompletedTaskMessage(
        date,
        task.title,
        data.longestArchivedTask!.totalMinutes,
      ));
      buffer.writeln(l10n.reviewLongestArchivedTaskMessage);
    }

    // 结束语
    buffer.writeln(l10n.reviewClosingMessage);

    return buffer.toString();
  }

  /// 生成 Markdown 格式的文章
  static String generateMarkdown(ReviewData data, AppLocalizations l10n) {
    final buffer = StringBuffer();

    // 第一行：欢迎语（作为标题）
    buffer.writeln('# ${l10n.reviewWelcomeMessage(data.welcome.dayCount)}\n');

    // 第二行：统计信息
    buffer.writeln('## ${l10n.reviewStatsMessage(data.stats.projectCount, data.stats.taskCount)}\n');

    // 新用户提示（条件显示）
    if (_shouldShowNewUserHint(data)) {
      buffer.writeln('> ${l10n.reviewNewUserHint}\n');
    }

    // 项目相关行
    if (data.stats.projectCount == 0) {
      buffer.writeln('### ${l10n.reviewNoProjectsMessage}\n');
    } else {
      final activeProjectCount = data.projects.length;
      if (activeProjectCount > 0) {
        buffer.writeln('### ${l10n.reviewActiveProjectsCountMessage(activeProjectCount)}\n');
        for (final project in data.projects) {
          buffer.writeln('- **${project.name}**：包含 ${project.taskCount} 个任务\n');
        }
      }
    }

    // 独立任务统计
    if (data.standaloneTasks.totalCount > 0) {
      buffer.writeln('### ${l10n.reviewStandaloneTasksMessage(
        data.standaloneTasks.totalCount,
        data.standaloneTasks.activeCount,
        data.standaloneTasks.completedCount,
        data.standaloneTasks.archivedCount,
      )}\n');
    }

    // 最长已完成任务
    if (data.longestCompletedTask != null &&
        data.longestCompletedTask!.totalMinutes >= 120) {
      buffer.writeln('### ${l10n.reviewLongestCompletedTaskMessage(
        ReviewDateFormatter.formatReviewDate(data.longestCompletedTask!.task.createdAt),
        data.longestCompletedTask!.task.title,
        data.longestCompletedTask!.totalMinutes,
      )}\n');
      buffer.writeln('${l10n.reviewLongestCompletedTaskCompletionMessage}\n');

      // 任务分析
      if (data.longestCompletedTask!.task.description != null &&
          data.longestCompletedTask!.task.description!.isNotEmpty) {
        buffer.writeln('**任务分析**:\n${data.longestCompletedTask!.task.description}\n');
      }

      // 子任务列表
      if (data.longestCompletedTask!.subtasks.isNotEmpty) {
        buffer.writeln('**子任务列表**:\n');
        for (final subtask in data.longestCompletedTask!.subtasks) {
          final subtaskAnalysis = subtask.description != null &&
                  subtask.description!.isNotEmpty
              ? '：${subtask.description}'
              : '';
          buffer.writeln('- ${subtask.title}$subtaskAnalysis\n');
        }
      }
    } else {
      buffer.writeln('### ${l10n.reviewNoLongCompletedTaskMessage}\n');
    }

    // 完成根任务最多的一天
    if (data.mostCompletedDay != null) {
      final date = ReviewDateFormatter.formatReviewDate(data.mostCompletedDay!.date);
      final totalHours = ReviewTimeFormatter.formatHours(data.mostCompletedDay!.totalHours);
      buffer.writeln('### ${l10n.reviewMostCompletedRootTasksDayMessage(
        date,
        data.mostCompletedDay!.taskCount,
        totalHours,
      )}\n');
    }

    // 最长归档任务
    if (data.longestArchivedTask != null &&
        data.longestArchivedTask!.totalMinutes > 0) {
      buffer.writeln('### ${l10n.reviewLongestArchivedTaskMessage}\n');
      buffer.writeln('${l10n.reviewLongestCompletedTaskMessage(
        ReviewDateFormatter.formatReviewDate(data.longestArchivedTask!.task.createdAt),
        data.longestArchivedTask!.task.title,
        data.longestArchivedTask!.totalMinutes,
      )}\n');
    }

    // 结束语
    buffer.writeln('---\n');
    buffer.writeln(l10n.reviewClosingMessage);

    return buffer.toString();
  }

  /// 判断是否应该显示新用户提示
  static bool _shouldShowNewUserHint(ReviewData data) {
    return data.stats.projectCount <= 3 ||
        data.stats.taskCount <= 300 ||
        data.welcome.dayCount <= 90;
  }
}

