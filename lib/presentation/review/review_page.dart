import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/review_providers.dart';
import '../../data/models/review_data.dart';
import '../../generated/l10n/app_localizations.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/main_drawer.dart';
import 'utils/review_date_formatter.dart';
import 'widgets/review_action_buttons.dart';
import 'widgets/review_closing_line.dart';
import 'widgets/review_content_line.dart';
import 'widgets/review_error_state.dart';
import 'widgets/review_loading_state.dart';
import 'widgets/review_longest_task_section.dart';
import 'widgets/review_most_completed_day_line.dart';
import 'widgets/review_new_user_hint_line.dart';
import 'widgets/review_opening_animation.dart';
import 'widgets/review_projects_section.dart';
import 'widgets/review_standalone_tasks_line.dart';
import 'widgets/review_stats_line.dart';
import 'widgets/review_welcome_line.dart';

/// 回顾页面
class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  Timer? _contentDisplayTimer;
  int _currentLineIndex = 0;

  @override
  void initState() {
    super.initState();
    // 加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewPageProvider.notifier).loadData();
    });
  }

  @override
  void dispose() {
    _contentDisplayTimer?.cancel();
    super.dispose();
  }

  void _startContentDisplaySequence(ReviewData data) {
    // 开场动画完成后，延迟300ms开始显示内容
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _displayNextLine(data);
    });
  }

  void _displayNextLine(ReviewData data) {
    if (!mounted) return;

    final totalLines = _calculateTotalLines(data);
    if (_currentLineIndex >= totalLines) {
      return;
    }

    setState(() {
      _currentLineIndex++;
    });

    // 每行之间延迟500ms
    if (_currentLineIndex < totalLines) {
      _contentDisplayTimer?.cancel();
      _contentDisplayTimer = Timer(const Duration(milliseconds: 500), () {
        _displayNextLine(data);
      });
    }
  }

  int _calculateTotalLines(ReviewData data) {
    int count = 0;
    
    // 欢迎语
    count++;
    
    // 统计信息
    count++;
    
    // 新用户提示（条件显示）
    if (data.stats.projectCount <= 3 || 
        data.stats.taskCount <= 300 || 
        data.welcome.dayCount <= 90) {
      count++;
    }
    
    // 项目区域
    if (data.stats.projectCount > 0) {
      if (data.projects.isNotEmpty) {
        count++; // 项目数量提示
        count += data.projects.length; // 项目列表
      } else {
        count++; // 无项目提示
      }
    } else {
      count++; // 无项目提示
    }
    
    // 独立任务统计
    if (data.standaloneTasks.totalCount > 0) {
      count++;
    }
    
    // 最长已完成任务
    if (data.longestCompletedTask != null && 
        data.longestCompletedTask!.totalMinutes >= 120) {
      count += 2; // 任务信息 + 完成消息
      if (data.longestCompletedTask!.task.description != null &&
          data.longestCompletedTask!.task.description!.isNotEmpty) {
        count++; // 任务分析
      }
      count += data.longestCompletedTask!.subtasks.length; // 子任务
    } else {
      count++; // 无长任务提示
    }
    
    // 最长归档任务
    if (data.longestArchivedTask != null && 
        data.longestArchivedTask!.totalMinutes > 0) {
      count += 2; // 任务信息 + 归档消息
    }
    
    // 最多完成日
    if (data.mostCompletedDay != null && data.mostCompletedDay!.taskCount > 0) {
      count++;
    }
    
    // 结束语
    count++;
    
    return count;
  }

  bool _isLineVisible(int lineIndex) {
    return lineIndex < _currentLineIndex;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewPageProvider);
    final l10n = AppLocalizations.of(context);

    return GradientPageScaffold(
      appBar: PageAppBar(
        title: l10n.appShellReview,
      ),
      drawer: const MainDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 开场动画
            ReviewOpeningAnimation(
              onAnimationComplete: () {
                if (state.data != null) {
                  _startContentDisplaySequence(state.data!);
                }
              },
            ),

            // 内容区域
            if (state.loading)
              const ReviewLoadingState()
            else if (state.error != null)
              ReviewErrorState(
                error: state.error!,
                onRetry: () {
                  ref.read(reviewPageProvider.notifier).loadData();
                },
              )
            else if (state.data != null)
              _buildContentArea(state.data!)
            else
              const SizedBox.shrink(),

            // 操作按钮（所有内容显示完成后显示）
            if (state.data != null && _currentLineIndex >= _calculateTotalLines(state.data!))
              ReviewActionButtons(
                reviewData: state.data!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea(ReviewData data) {
    int lineIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 欢迎语
        ReviewWelcomeLine(
          dayCount: data.welcome.dayCount,
          visible: _isLineVisible(lineIndex++),
        ),

        // 统计信息
        ReviewStatsLine(
          projectCount: data.stats.projectCount,
          taskCount: data.stats.taskCount,
          visible: _isLineVisible(lineIndex++),
        ),

        // 新用户提示
        if (data.stats.projectCount <= 3 || 
            data.stats.taskCount <= 300 || 
            data.welcome.dayCount <= 90)
          ReviewNewUserHintLine(
            visible: _isLineVisible(lineIndex++),
          ),

        // 项目区域
        if (data.stats.projectCount > 0)
          if (data.projects.isNotEmpty)
            _buildProjectsSection(data.projects, lineIndex)
          else
            ReviewNoProjectsLine(
              visible: _isLineVisible(lineIndex++),
            )
        else
          ReviewNoProjectsLine(
            visible: _isLineVisible(lineIndex++),
          ),

        // 独立任务统计
        if (data.standaloneTasks.totalCount > 0)
          ReviewStandaloneTasksLine(
            totalCount: data.standaloneTasks.totalCount,
            activeCount: data.standaloneTasks.activeCount,
            completedCount: data.standaloneTasks.completedCount,
            archivedCount: data.standaloneTasks.archivedCount,
            visible: _isLineVisible(lineIndex++),
          ),

        // 最长已完成任务
        if (data.longestCompletedTask != null && 
            data.longestCompletedTask!.totalMinutes >= 120)
          _buildLongestCompletedTaskSection(data.longestCompletedTask!, lineIndex)
        else
          ReviewNoLongCompletedTaskLine(
            visible: _isLineVisible(lineIndex++),
          ),

        // 最长归档任务
        if (data.longestArchivedTask != null && 
            data.longestArchivedTask!.totalMinutes > 0)
          _buildLongestArchivedTaskSection(data.longestArchivedTask!, lineIndex),

        // 最多完成日
        if (data.mostCompletedDay != null && data.mostCompletedDay!.taskCount > 0)
          ReviewMostCompletedDayLine(
            mostCompletedDay: data.mostCompletedDay!,
            visible: _isLineVisible(lineIndex++),
          ),

        // 结束语
        ReviewClosingLine(
          visible: _isLineVisible(lineIndex++),
        ),
      ],
    );
  }

  /// 构建项目区域（逐行显示）
  Widget _buildProjectsSection(List<ReviewProjectInfo> projects, int startLineIndex) {
    int lineIndex = startLineIndex;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 项目数量提示行
        ReviewContentLine(
          text: l10n.reviewActiveProjectsCountMessage(projects.length),
          fontSize: 20,
          fontWeight: FontWeight.w400,
          topSpacing: 24,
          bottomSpacing: 16,
          visible: _isLineVisible(lineIndex++),
        ),
        // 项目列表
        ...projects.map((project) {
          final text = l10n.reviewProjectItemFormat(project.name, project.taskCount);
          return ReviewContentLine(
            text: text,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            topSpacing: 0,
            bottomSpacing: 8,
            visible: _isLineVisible(lineIndex++),
          );
        }),
      ],
    );
  }

  /// 构建最长已完成任务区域（逐行显示）
  Widget _buildLongestCompletedTaskSection(ReviewLongestTaskInfo taskInfo, int startLineIndex) {
    int lineIndex = startLineIndex;
    final l10n = AppLocalizations.of(context);

    if (taskInfo.totalMinutes < 120) {
      return const SizedBox.shrink();
    }

    final date = ReviewDateFormatter.formatReviewDate(taskInfo.task.createdAt);
    final taskText = l10n.reviewLongestCompletedTaskMessage(
      date,
      taskInfo.task.title,
      taskInfo.totalMinutes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 任务信息行
        ReviewContentLine(
          text: taskText,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          topSpacing: 0,
          bottomSpacing: 16,
          visible: _isLineVisible(lineIndex++),
        ),
        // 完成消息行
        ReviewContentLine(
          text: l10n.reviewLongestCompletedTaskCompletionMessage,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          topSpacing: 0,
          bottomSpacing: 16,
          visible: _isLineVisible(lineIndex++),
        ),
        // 任务分析（如果有）
        if (taskInfo.task.description != null && taskInfo.task.description!.isNotEmpty)
          ReviewContentLine(
            text: '${l10n.reviewTaskAnalysis}${taskInfo.task.description}',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            topSpacing: 0,
            bottomSpacing: 16,
            visible: _isLineVisible(lineIndex++),
          ),
        // 子任务列表
        ...taskInfo.subtasks.map((subtask) {
          final subtaskText = '${l10n.reviewSubtask}${subtask.title}';
          final analysisText = subtask.description != null && subtask.description!.isNotEmpty
              ? '：${subtask.description}'
              : '';
          return ReviewContentLine(
            text: '$subtaskText$analysisText',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            topSpacing: 0,
            bottomSpacing: 8,
            visible: _isLineVisible(lineIndex++),
          );
        }),
      ],
    );
  }

  /// 构建最长归档任务区域（逐行显示）
  Widget _buildLongestArchivedTaskSection(ReviewLongestTaskInfo taskInfo, int startLineIndex) {
    int lineIndex = startLineIndex;
    final l10n = AppLocalizations.of(context);

    if (taskInfo.totalMinutes <= 0) {
      return const SizedBox.shrink();
    }

    final date = ReviewDateFormatter.formatReviewDate(taskInfo.task.createdAt);
    final taskText = l10n.reviewLongestCompletedTaskMessage(
      date,
      taskInfo.task.title,
      taskInfo.totalMinutes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 任务信息行
        ReviewContentLine(
          text: taskText,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          topSpacing: 0,
          bottomSpacing: 16,
          visible: _isLineVisible(lineIndex++),
        ),
        // 归档消息行
        ReviewContentLine(
          text: l10n.reviewLongestArchivedTaskMessage,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          topSpacing: 0,
          bottomSpacing: 24,
          visible: _isLineVisible(lineIndex++),
        ),
      ],
    );
  }
}

