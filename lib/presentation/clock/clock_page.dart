import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/providers/clock_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/theme/clock_gradients.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'widgets/compact_timer_slider.dart';
import 'widgets/clock_subtask_section.dart';
import 'widgets/clock_task_analysis.dart';
import 'widgets/clock_task_info_card.dart';
import 'widgets/clock_control_strip.dart';
import 'widgets/clock_wave_background.dart';

/// 计时器主页面
///
/// 全屏沉浸式计时器页面，包含计时显示、任务管理、音频提醒等功能
class ClockPage extends ConsumerStatefulWidget {
  const ClockPage({super.key, required this.taskId});

  final int taskId;

  @override
  ConsumerState<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends ConsumerState<ClockPage>
    with WidgetsBindingObserver {
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 启用屏幕常亮（如果计时已开始且未暂停）
    final timerState = ref.read(clockTimerProvider);
    _wasPaused = timerState.isPaused;
    if (timerState.isStarted && !timerState.isPaused) {
      _enableWakeLock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 禁用屏幕常亮
    _disableWakeLock();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 切回前台时恢复状态
      _restoreState();
    }
  }

  /// 启用屏幕常亮
  Future<void> _enableWakeLock() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('Failed to enable wake lock: $e');
    }
  }

  /// 禁用屏幕常亮
  Future<void> _disableWakeLock() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('Failed to disable wake lock: $e');
    }
  }

  /// 恢复计时器状态
  Future<void> _restoreState() async {
    // 状态恢复已经在 ClockTimerNotifier 的 _loadState() 中处理
    // 这里主要是确保 UI 显示正确
    // 如果计时仍在进行中，状态会自动通过 _loadState() 恢复
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
    final timerState = ref.watch(clockTimerProvider);
    final taskAsync = ref.watch(clockTaskProvider(widget.taskId));

    // 监听计时器状态变化，管理屏幕常亮
    if (timerState.isStarted) {
      if (timerState.isPaused && !_wasPaused) {
        // 从运行变为暂停：禁用屏幕常亮
        _wasPaused = true;
        _disableWakeLock();
      } else if (!timerState.isPaused && _wasPaused) {
        // 从暂停变为运行：启用屏幕常亮
        _wasPaused = false;
        _enableWakeLock();
      }
    } else {
      // 计时未开始：确保屏幕常亮被禁用
      if (_wasPaused) {
        _wasPaused = false;
        _disableWakeLock();
      }
    }

    // 获取当前状态对应的渐变
    ClockState clockState;
    if (timerState.isPaused) {
      clockState = ClockState.paused;
    } else if (!timerState.isStarted) {
      clockState = ClockState.normal;
    } else {
      clockState = ClockState.normal;
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // 页面即将返回，重置计时器和声音，结束 FocusSession（不记录时间）
          final timerNotifier = ref.read(clockTimerProvider.notifier);
          await timerNotifier.reset();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: taskAsync.when(
            data: (task) {
              final l10n = AppLocalizations.of(context);
              final colorScheme = Theme.of(context).colorScheme;
              if (task == null) {
                return Center(
                  child: Text(
                    l10n.clockTaskNotFound,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                );
              }

              return _WaveLayout(
                state: clockState,
                timerState: timerState,
                task: task,
                onComplete: _handleComplete,
                onDescriptionChanged: _handleDescriptionChanged,
              );
            },
            loading: () {
              final colorScheme = Theme.of(context).colorScheme;
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              );
            },
            error: (error, stackTrace) {
              final l10n = AppLocalizations.of(context);
              final colorScheme = Theme.of(context).colorScheme;
              return Center(
                child: Text(
                  l10n.clockLoadFailed(error.toString()),
                  style: TextStyle(color: colorScheme.onSurface),
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

  final ClockState state;
  final ClockTimerState timerState;
  final Task task;
  final VoidCallback onComplete;
  final ValueChanged<String> onDescriptionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
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
        ClockWaveBackground(state: state),
        Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: colorScheme.onSurface,
                ),
                onPressed: () async {
                  final timerNotifier = ref.read(
                    clockTimerProvider.notifier,
                  );
                  await timerNotifier.reset();
                  if (context.mounted) {
                    context.pop();
                  }
                },
                tooltip: l10n.clockBack,
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

  final ClockState state;
  final ClockTimerState timerState;
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
          sliver: SliverToBoxAdapter(child: ClockTaskInfoCard(task: task)),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            sectionSpacing,
          ),
          sliver: SliverToBoxAdapter(
            child: ClockTaskAnalysis(
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
            child: ClockSubtaskSection(task: task, timerState: timerState),
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

  final ClockTimerState timerState;
  final int taskId;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 14 : 12,
          ),
          child: ClockControlStrip(taskId: taskId, onComplete: onComplete),
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

CompactTimerPalette _paletteForState(ClockTimerState state) {
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

  final ClockState state;
  final ClockTimerState timerState;
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
              ClockTaskInfoCard(task: task),
              const SizedBox(height: 24),
              ClockTaskAnalysis(
                task: task,
                onDescriptionChanged: onDescriptionChanged,
              ),
              const SizedBox(height: 24),
              ClockSubtaskSection(task: task, timerState: timerState),
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

  final ClockTimerState timerState;
  final int taskId;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _TimerCluster(timerState: timerState),
        const SizedBox(height: 28),
        ClockControlStrip(taskId: taskId, onComplete: onComplete),
      ],
    );
  }
}

class _TimerCluster extends StatelessWidget {
  const _TimerCluster({required this.timerState});

  final ClockTimerState timerState;

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
final clockTaskProvider = StreamProvider.family<Task?, int>((
  ref,
  taskId,
) async* {
  final taskRepository = ref.watch(taskRepositoryProvider);
  final taskStream = taskRepository.watchTaskById(taskId);

  await for (final task in taskStream) {
    yield task;
  }
});
