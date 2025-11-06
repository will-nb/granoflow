import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/pomodoro_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/theme/pomodoro_gradients.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'widgets/compact_timer_slider.dart';
import 'widgets/pomodoro_subtask_section.dart';
import 'widgets/pomodoro_task_analysis.dart';
import 'widgets/pomodoro_task_info_card.dart';
import 'widgets/pomodoro_control_strip.dart';
import 'widgets/pomodoro_wave_background.dart';

/// 番茄时钟主页面
///
/// 全屏沉浸式番茄时钟页面，包含计时显示、任务管理、音频提醒等功能
class PomodoroPage extends ConsumerStatefulWidget {
  const PomodoroPage({super.key, required this.taskId});

  final int taskId;

  @override
  ConsumerState<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends ConsumerState<PomodoroPage> {
  @override
  void initState() {
    super.initState();
  }

  void _handleComplete() {
    // 完成后返回上一页
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _handleDescriptionChanged(String description) async {
    // 保存任务分析到 task.description
    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.updateDetails(
        taskId: widget.taskId,
        payload: TaskUpdate(description: description),
      );
    } catch (e) {
      debugPrint('Failed to update task description: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(pomodoroTimerProvider);
    final taskAsync = ref.watch(pomodoroTaskProvider(widget.taskId));

    // 获取当前状态对应的渐变
    PomodoroState pomodoroState;
    if (timerState.isPaused) {
      pomodoroState = PomodoroState.paused;
    } else if (!timerState.isStarted) {
      pomodoroState = PomodoroState.normal;
    } else {
      pomodoroState = PomodoroState.normal;
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // 页面即将返回，重置计时器和声音，结束 FocusSession（不记录时间）
          final timerNotifier = ref.read(pomodoroTimerProvider.notifier);
          await timerNotifier.reset();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: taskAsync.when(
            data: (task) {
              final l10n = AppLocalizations.of(context);
              if (task == null) {
                return Center(
                  child: Text(
                    l10n.pomodoroTaskNotFound,
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return _WaveLayout(
                state: pomodoroState,
                timerState: timerState,
                task: task,
                onComplete: _handleComplete,
                onDescriptionChanged: _handleDescriptionChanged,
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
            error: (error, stackTrace) {
              final l10n = AppLocalizations.of(context);
              return Center(
                child: Text(
                  l10n.pomodoroLoadFailed(error.toString()),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WaveLayout extends ConsumerWidget {
  const _WaveLayout({
    required this.state,
    required this.timerState,
    required this.task,
    required this.onComplete,
    required this.onDescriptionChanged,
  });

  final PomodoroState state;
  final PomodoroTimerState timerState;
  final Task task;
  final VoidCallback onComplete;
  final ValueChanged<String> onDescriptionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final bool isLandscape = size.width >= 800 && size.width > size.height;

    final content = isLandscape
        ? _LandscapeLayout(
            state: state,
            timerState: timerState,
            task: task,
            onComplete: onComplete,
            onDescriptionChanged: onDescriptionChanged,
          )
        : _PortraitLayout(
            state: state,
            timerState: timerState,
            task: task,
            onComplete: onComplete,
            onDescriptionChanged: onDescriptionChanged,
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        PomodoroWaveBackground(state: state),
        Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                ),
                onPressed: () async {
                  final timerNotifier = ref.read(
                    pomodoroTimerProvider.notifier,
                  );
                  await timerNotifier.reset();
                  if (context.mounted) {
                    context.pop();
                  }
                },
                tooltip: l10n.pomodoroBack,
              ),
            ),
            Expanded(child: content),
          ],
        ),
      ],
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout({
    required this.state,
    required this.timerState,
    required this.task,
    required this.onComplete,
    required this.onDescriptionChanged,
  });

  final PomodoroState state;
  final PomodoroTimerState timerState;
  final Task task;
  final VoidCallback onComplete;
  final ValueChanged<String> onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width >= 600;
    final double horizontalPadding = isTablet ? 28 : 20;
    final double topPadding = isTablet ? 24 : 16;
    final double sectionSpacing = isTablet ? 24 : 20;
    final double bottomPadding = isTablet ? 28 : 24;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            sectionSpacing,
          ),
          sliver: SliverToBoxAdapter(
            child: _HeroCluster(
              timerState: timerState,
              taskId: task.id,
              onComplete: onComplete,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            sectionSpacing,
          ),
          sliver: SliverToBoxAdapter(child: PomodoroTaskInfoCard(task: task)),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            sectionSpacing,
          ),
          sliver: SliverToBoxAdapter(
            child: PomodoroTaskAnalysis(
              task: task,
              onDescriptionChanged: onDescriptionChanged,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            bottomPadding,
          ),
          sliver: SliverToBoxAdapter(
            child: PomodoroSubtaskSection(task: task, timerState: timerState),
          ),
        ),
      ],
    );
  }
}

class _HeroCluster extends StatelessWidget {
  const _HeroCluster({
    required this.timerState,
    required this.taskId,
    required this.onComplete,
  });

  final PomodoroTimerState timerState;
  final int taskId;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width >= 600;
    final double diameter = _resolveDiameter(size.width, isTablet: isTablet);
    final double spacing = isTablet ? 20 : 16;

    final CompactTimerPalette palette = _paletteForState(timerState);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompactTimerSlider(
          elapsed: timerState.forwardElapsed,
          diameter: diameter,
          palette: palette,
        ),
        SizedBox(height: spacing),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: isTablet ? 0.22 : 0.2),
            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 14 : 12,
          ),
          child: PomodoroControlStrip(taskId: taskId, onComplete: onComplete),
        ),
      ],
    );
  }

  double _resolveDiameter(double width, {required bool isTablet}) {
    final double scaled = isTablet ? width * 0.55 : width * 0.72;
    if (isTablet) {
      return math.min(math.max(scaled, 240), 300);
    }
    return math.min(math.max(scaled, 200), 235);
  }
}

CompactTimerPalette _paletteForState(PomodoroTimerState state) {
  if (state.isPaused) {
    return CompactTimerPalette.paused();
  }
  if (state.isOvertime) {
    return CompactTimerPalette.complete();
  }
  return const CompactTimerPalette.normal();
}

class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout({
    required this.state,
    required this.timerState,
    required this.task,
    required this.onComplete,
    required this.onDescriptionChanged,
  });

  final PomodoroState state;
  final PomodoroTimerState timerState;
  final Task task;
  final VoidCallback onComplete;
  final ValueChanged<String> onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    final children = <Widget>[
      Flexible(
        flex: 42,
        child: SingleChildScrollView(
          padding: padding,
          child: _TimerColumn(
            timerState: timerState,
            taskId: task.id,
            onComplete: onComplete,
          ),
        ),
      ),
      Flexible(
        flex: 58,
        child: SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PomodoroTaskInfoCard(task: task),
              const SizedBox(height: 24),
              PomodoroTaskAnalysis(
                task: task,
                onDescriptionChanged: onDescriptionChanged,
              ),
              const SizedBox(height: 24),
              PomodoroSubtaskSection(task: task, timerState: timerState),
            ],
          ),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool twoColumn = constraints.maxWidth >= 1024;
        return twoColumn ? Row(children: children) : Column(children: children);
      },
    );
  }
}

class _TimerColumn extends StatelessWidget {
  const _TimerColumn({
    required this.timerState,
    required this.taskId,
    required this.onComplete,
  });

  final PomodoroTimerState timerState;
  final int taskId;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _TimerCluster(timerState: timerState),
        const SizedBox(height: 28),
        PomodoroControlStrip(taskId: taskId, onComplete: onComplete),
      ],
    );
  }
}

class _TimerCluster extends StatelessWidget {
  const _TimerCluster({required this.timerState});

  final PomodoroTimerState timerState;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double width = size.width;
    double diameter;
    if (width < 600) {
      diameter = (width * 0.72).clamp(220, 280);
    } else if (width < 1024) {
      diameter = (width * 0.4).clamp(280, 360);
    } else {
      diameter = (width * 0.32).clamp(320, 380);
    }

    final double spacing = diameter * 0.25;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: spacing),
        CompactTimerSlider(
          elapsed: timerState.forwardElapsed,
          diameter: diameter,
          palette: _paletteForState(timerState),
        ),
        SizedBox(height: spacing + 12),
      ],
    );
  }
}

/// Provider: 获取任务（实时监听）
final pomodoroTaskProvider = StreamProvider.family<Task?, int>((
  ref,
  taskId,
) async* {
  final taskRepository = ref.watch(taskRepositoryProvider);
  final taskStream = taskRepository.watchTaskById(taskId);

  await for (final task in taskStream) {
    yield task;
  }
});
