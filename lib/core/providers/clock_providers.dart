import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/focus_flow_service.dart';
import '../services/clock_audio_service.dart';
import '../services/timer_background_service.dart';
import '../services/timer_persistence_service.dart';
import '../../data/repositories/focus_session_repository.dart';
import 'repository_providers.dart';
import 'service_providers.dart';
import 'timer_background_service_provider.dart';
import 'timer_persistence_service_provider.dart';

/// 计时器状态
class ClockTimerState {
  const ClockTimerState({
    required this.isStarted,
    required this.isPaused,
    required this.forwardElapsed,
    required this.countdownRemaining,
    required this.startTime,
    required this.pausePeriods,
    required this.countdownDuration,
    required this.originalCountdownDuration,
    this.focusSessionId,
  });

  /// 是否已开始
  final bool isStarted;
  
  /// 是否暂停
  final bool isPaused;
  
  /// 正向计时已过时间
  final Duration forwardElapsed;
  
  /// 倒计时剩余时间（可能为负数表示超时）
  final Duration countdownRemaining;
  
  /// 开始时间
  final DateTime? startTime;
  
  /// 暂停时间段列表
  final List<({DateTime start, DateTime end})> pausePeriods;
  
  /// 当前倒计时时长（秒）
  final int countdownDuration;
  
  /// 原始倒计时时长（秒），用于计算超时百分比
  final int originalCountdownDuration;
  
    /// FocusSession ID（如果已开始）
    final String? focusSessionId;

  ClockTimerState copyWith({
    bool? isStarted,
    bool? isPaused,
    Duration? forwardElapsed,
    Duration? countdownRemaining,
    DateTime? startTime,
    List<({DateTime start, DateTime end})>? pausePeriods,
    int? countdownDuration,
    int? originalCountdownDuration,
      String? focusSessionId,
  }) {
    return ClockTimerState(
      isStarted: isStarted ?? this.isStarted,
      isPaused: isPaused ?? this.isPaused,
      forwardElapsed: forwardElapsed ?? this.forwardElapsed,
      countdownRemaining: countdownRemaining ?? this.countdownRemaining,
      startTime: startTime ?? this.startTime,
      pausePeriods: pausePeriods ?? this.pausePeriods,
      countdownDuration: countdownDuration ?? this.countdownDuration,
      originalCountdownDuration: originalCountdownDuration ?? this.originalCountdownDuration,
      focusSessionId: focusSessionId ?? this.focusSessionId,
    );
  }

  /// 是否超时
  bool get isOvertime => countdownRemaining.isNegative;

  /// 超时百分比（0.0 - 1.0）
  double get overtimePercentage {
    if (!isOvertime || originalCountdownDuration <= 0) {
      return 0.0;
    }
    final absOvertime = countdownRemaining.abs().inSeconds;
    final percentage = absOvertime / originalCountdownDuration;
    return percentage > 1.0 ? 1.0 : percentage;
  }

  /// 实际运行时间（排除暂停时间）
  Duration get actualRunningTime {
    if (startTime == null) {
      return Duration.zero;
    }
    
    final endTime = DateTime.now();
    final totalDuration = endTime.difference(startTime!);
    
    final pauseDuration = pausePeriods.fold<Duration>(
      Duration.zero,
      (sum, period) => sum + period.end.difference(period.start),
    );
    
    final actualRunningTime = totalDuration - pauseDuration;
    return actualRunningTime.isNegative ? Duration.zero : actualRunningTime;
  }
}

/// 计时器状态管理 Notifier
class ClockTimerNotifier extends StateNotifier<ClockTimerState> {
  /// 私有构造函数，用于从 Provider 创建（异步初始化依赖）
  ClockTimerNotifier._(this._ref)
      : _focusFlowService = null,
        _audioService = null,
        _focusSessionRepository = null,
        _backgroundService = null,
        _persistenceService = null,
        super(const ClockTimerState(
          isStarted: false,
          isPaused: false,
          forwardElapsed: Duration.zero,
          countdownRemaining: Duration(minutes: 25),
          startTime: null,
          pausePeriods: [],
          countdownDuration: 25 * 60, // 默认25分钟（在15-60分钟范围内）
          originalCountdownDuration: 25 * 60,
        )) {
    _initAsync();
  }

  /// 公共构造函数（用于测试或直接创建）
  ClockTimerNotifier({
    required FocusFlowService focusFlowService,
    required ClockAudioService audioService,
    required FocusSessionRepository focusSessionRepository,
    TimerBackgroundService? backgroundService,
    TimerPersistenceService? persistenceService,
  }) : _ref = null,
       _focusFlowService = focusFlowService,
       _audioService = audioService,
       _focusSessionRepository = focusSessionRepository,
       _backgroundService = backgroundService,
       _persistenceService = persistenceService,
       super(const ClockTimerState(
         isStarted: false,
         isPaused: false,
         forwardElapsed: Duration.zero,
         countdownRemaining: Duration(minutes: 25),
         startTime: null,
         pausePeriods: [],
         countdownDuration: 25 * 60, // 默认25分钟（在15-60分钟范围内）
         originalCountdownDuration: 25 * 60,
       )) {
    _initTimer();
    // 可选：尝试从持久化存储恢复状态
    _loadState();
  }

  final Ref? _ref;
  FocusFlowService? _focusFlowService;
  ClockAudioService? _audioService;
  FocusSessionRepository? _focusSessionRepository;
  TimerBackgroundService? _backgroundService;
  TimerPersistenceService? _persistenceService;

  /// 异步初始化依赖
  Future<void> _initAsync() async {
    if (_ref == null) return;
    
    _focusFlowService = await _ref!.read(focusFlowServiceProvider.future);
    _audioService = await _ref!.read(clockAudioServiceProvider.future);
    _focusSessionRepository = await _ref!.read(focusSessionRepositoryProvider.future);
    _backgroundService = _ref!.read(timerBackgroundServiceProvider);
    _persistenceService = _ref!.read(timerPersistenceServiceProvider);
    
    _initTimer();
    // 可选：尝试从持久化存储恢复状态
    _loadState();
  }

  /// 获取 FocusFlowService（延迟初始化）
  FocusFlowService get _focusFlowServiceOrThrow {
    if (_focusFlowService == null) {
      throw StateError('ClockTimerNotifier not initialized. Call _initAsync() first.');
    }
    return _focusFlowService!;
  }

  /// 获取 ClockAudioService（延迟初始化）
  ClockAudioService get _audioServiceOrThrow {
    if (_audioService == null) {
      throw StateError('ClockTimerNotifier not initialized. Call _initAsync() first.');
    }
    return _audioService!;
  }

  /// 获取 FocusSessionRepository（延迟初始化）
  FocusSessionRepository get _focusSessionRepositoryOrThrow {
    if (_focusSessionRepository == null) {
      throw StateError('ClockTimerNotifier not initialized. Call _initAsync() first.');
    }
    return _focusSessionRepository!;
  }
  
  /// 获取 TimerBackgroundService（延迟初始化）
  TimerBackgroundService get _backgroundServiceOrThrow {
    if (_backgroundService == null) {
      throw StateError('ClockTimerNotifier not initialized. Call _initAsync() first.');
    }
    return _backgroundService!;
  }
  
  /// 获取 TimerPersistenceService（延迟初始化）
  TimerPersistenceService get _persistenceServiceOrThrow {
    if (_persistenceService == null) {
      throw StateError('ClockTimerNotifier not initialized. Call _initAsync() first.');
    }
    return _persistenceService!;
  }
  
  Timer? _timer;
  DateTime? _currentPauseStart;

  void _initTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isStarted && !state.isPaused) {
        _updateTimers();
      }
    });
  }

  /// 更新计时器
  void _updateTimers() {
    if (state.startTime == null) {
      return;
    }
    
    // 计算正向计时
    final forwardElapsed = state.actualRunningTime;
    
    // 计算倒计时
    final elapsedSeconds = forwardElapsed.inSeconds;
    final remainingSeconds = state.countdownDuration - elapsedSeconds;
    final countdownRemaining = Duration(seconds: remainingSeconds);
    
    state = state.copyWith(
      forwardElapsed: forwardElapsed,
      countdownRemaining: countdownRemaining,
    );
  }


  /// 开始计时
  Future<void> start(String taskId) async {
    if (state.isStarted) {
      return;
    }
    
    // 创建 FocusSession
    final session = await _focusFlowServiceOrThrow.startFocus(
      taskId: taskId,
      estimateMinutes: state.countdownDuration ~/ 60,
    );
    
    final now = DateTime.now();
    final endTime = now.add(Duration(seconds: state.countdownDuration));
    
    state = state.copyWith(
      isStarted: true,
      isPaused: false,
      startTime: now,
      forwardElapsed: Duration.zero,
      countdownRemaining: Duration(seconds: state.countdownDuration),
      pausePeriods: [],
      focusSessionId: session.id,
    );
    
    // 启动后台服务
    if (_backgroundService != null) {
      await _backgroundServiceOrThrow.startTimer(
        endTime: endTime,
        duration: Duration(seconds: state.countdownDuration),
      );
    }
    
    // 保存状态到持久化存储
    await _saveState();
    
    // 开始播放滴答声
    _audioServiceOrThrow.resetAlertFlags();
    _audioServiceOrThrow.startTickSound();
  }

  /// 暂停计时
  Future<void> pause() async {
    if (!state.isStarted || state.isPaused) {
      return;
    }
    
    final now = DateTime.now();
    _currentPauseStart = now;
    
    state = state.copyWith(
      isPaused: true,
    );
    
    // 暂停后台服务
    if (_backgroundService != null) {
      await _backgroundServiceOrThrow.pauseTimer();
    }
    
    // 保存状态到持久化存储
    await _saveState();
    
    // 停止播放滴答声
    _audioServiceOrThrow.stopTickSound();
  }

  /// 继续计时
  Future<void> resume() async {
    if (!state.isStarted || !state.isPaused) {
      return;
    }
    
    final now = DateTime.now();
    
    // 记录暂停时间段
    if (_currentPauseStart != null) {
      final pausePeriod = (
        start: _currentPauseStart!,
        end: now,
      );
      final updatedPausePeriods = [...state.pausePeriods, pausePeriod];
      
      state = state.copyWith(
        isPaused: false,
        pausePeriods: updatedPausePeriods,
      );
    } else {
      state = state.copyWith(
        isPaused: false,
      );
    }
    
    _currentPauseStart = null;
    
    // 计算新的结束时间（基于剩余时间）
    final remainingSeconds = state.countdownRemaining.inSeconds;
    if (remainingSeconds > 0 && state.startTime != null) {
      final newEndTime = now.add(Duration(seconds: remainingSeconds));
      
      // 恢复后台服务
      if (_backgroundService != null) {
        await _backgroundServiceOrThrow.resumeTimer();
        // 如果 resumeTimer 不支持，重新启动
        final isRunning = await _backgroundServiceOrThrow.isRunning();
        if (!isRunning) {
          await _backgroundServiceOrThrow.startTimer(
            endTime: newEndTime,
            duration: Duration(seconds: remainingSeconds),
          );
        }
      }
    }
    
    // 保存状态到持久化存储
    await _saveState();
    
    // 继续播放滴答声
    _audioServiceOrThrow.startTickSound();
  }

  /// 设置倒计时时长（只能在开始前设置）
  /// 
  /// 限制范围：15-60分钟（900-3600秒）
  void setCountdownDuration(int seconds) {
    if (state.isStarted) {
      return;
    }
    
    // 限制范围：15-60分钟
    final minSeconds = 15 * 60; // 15分钟
    final maxSeconds = 60 * 60; // 60分钟
    final clampedSeconds = seconds.clamp(minSeconds, maxSeconds);
    
    state = state.copyWith(
      countdownDuration: clampedSeconds,
      originalCountdownDuration: clampedSeconds,
      countdownRemaining: Duration(seconds: clampedSeconds),
    );
  }

  /// 重置计时器
  /// 
  /// 将所有状态重置为初始状态，停止声音，结束 FocusSession（如果存在）但不记录时间
  Future<void> reset() async {
    _timer?.cancel();
    _audioServiceOrThrow.stopTickSound();
    _audioServiceOrThrow.resetAlertFlags();
    
    // 停止后台服务
    if (_backgroundService != null) {
      await _backgroundServiceOrThrow.stopTimer();
    }
    
    // 清除持久化状态
    if (_persistenceService != null) {
      await _persistenceServiceOrThrow.clearState();
    }
    
    // 如果有正在进行的 FocusSession，结束它但不记录时间（actualMinutes = 0）
    if (state.focusSessionId != null) {
      try {
        await _focusSessionRepositoryOrThrow.endSession(
          sessionId: state.focusSessionId!,
          actualMinutes: 0, // 不记录时间
          transferToTaskId: null,
          reflectionNote: null,
        );
      } catch (e) {
        // 忽略错误，继续重置状态
      }
    }
    
    // 重置状态
    state = const ClockTimerState(
      isStarted: false,
      isPaused: false,
      forwardElapsed: Duration.zero,
      countdownRemaining: Duration(minutes: 25),
      startTime: null,
      pausePeriods: [],
      countdownDuration: 25 * 60,
      originalCountdownDuration: 25 * 60,
    );
    _currentPauseStart = null;
  }
  
  /// 保存状态到持久化存储
  Future<void> _saveState() async {
    if (_persistenceService != null) {
      try {
        await _persistenceServiceOrThrow.saveState(state);
      } catch (e) {
        // 持久化失败不应该影响计时功能，只记录错误
        // ignore: avoid_print
        print('Failed to save timer state: $e');
      }
    }
  }
  
  /// 从持久化存储恢复状态
  Future<void> _loadState() async {
    if (_persistenceService != null) {
      try {
        final savedState = await _persistenceServiceOrThrow.loadState();
        if (savedState != null && savedState.isStarted) {
          // 恢复状态
          state = savedState;
          
          // 如果计时仍在进行中，恢复后台服务
          if (!savedState.isPaused && _backgroundService != null) {
            final remainingSeconds = savedState.countdownRemaining.inSeconds;
            if (remainingSeconds > 0 && savedState.startTime != null) {
              final now = DateTime.now();
              final newEndTime = now.add(Duration(seconds: remainingSeconds));
              try {
                await _backgroundServiceOrThrow.startTimer(
                  endTime: newEndTime,
                  duration: Duration(seconds: remainingSeconds),
                );
              } catch (e) {
                // 恢复后台服务失败不应该影响应用启动，只记录错误
                // ignore: avoid_print
                print('Failed to restore background timer: $e');
              }
            }
          }
        }
      } catch (e) {
        // 恢复失败不应该影响应用启动，只记录错误
        // ignore: avoid_print
        print('Failed to load timer state: $e');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService?.stopTickSound();
    super.dispose();
  }
}

/// 计时器 Provider
/// 注意：由于依赖的 Service 现在是 FutureProvider，我们需要在 StateNotifier 内部异步初始化
final clockTimerProvider = StateNotifierProvider<ClockTimerNotifier, ClockTimerState>((ref) {
  // StateNotifierProvider 不能是 async，所以我们需要在 StateNotifier 内部处理异步初始化
  // ClockTimerNotifier 需要在内部异步获取依赖
  return ClockTimerNotifier._(ref);
});

