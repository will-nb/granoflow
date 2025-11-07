import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../providers/clock_providers.dart';

/// 计时器状态持久化服务
/// 
/// 使用 SharedPreferences 存储计时器状态，支持保存和恢复
class TimerPersistenceService {
  TimerPersistenceService();

  static const String _keyIsStarted = 'timer_is_started';
  static const String _keyIsPaused = 'timer_is_paused';
  static const String _keyStartTime = 'timer_start_time';
  static const String _keyPausePeriods = 'timer_pause_periods';
  static const String _keyCountdownDuration = 'timer_countdown_duration';
  static const String _keyOriginalCountdownDuration = 'timer_original_countdown_duration';
  static const String _keyFocusSessionId = 'timer_focus_session_id';
  static const String _keyLastUpdated = 'timer_last_updated';

  /// 保存计时器状态
  Future<void> saveState(ClockTimerState state) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_keyIsStarted, state.isStarted);
    await prefs.setBool(_keyIsPaused, state.isPaused);
    await prefs.setInt(_keyCountdownDuration, state.countdownDuration);
    await prefs.setInt(_keyOriginalCountdownDuration, state.originalCountdownDuration);
    await prefs.setInt(_keyFocusSessionId, state.focusSessionId ?? -1);
    await prefs.setString(_keyLastUpdated, DateTime.now().toIso8601String());
    
    if (state.startTime != null) {
      await prefs.setString(_keyStartTime, state.startTime!.toIso8601String());
    } else {
      await prefs.remove(_keyStartTime);
    }
    
    // 保存暂停时间段列表（JSON 格式）
    if (state.pausePeriods.isNotEmpty) {
      final pausePeriodsJson = state.pausePeriods.map((period) {
        return {
          'start': period.start.toIso8601String(),
          'end': period.end.toIso8601String(),
        };
      }).toList();
      await prefs.setString(_keyPausePeriods, jsonEncode(pausePeriodsJson));
    } else {
      await prefs.remove(_keyPausePeriods);
    }
  }

  /// 恢复计时器状态
  /// 
  /// 返回恢复的状态，如果状态无效或不存在则返回 null
  Future<ClockTimerState?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    
    final isStarted = prefs.getBool(_keyIsStarted) ?? false;
    final isPaused = prefs.getBool(_keyIsPaused) ?? false;
    final countdownDuration = prefs.getInt(_keyCountdownDuration) ?? 25 * 60;
    final originalCountdownDuration = prefs.getInt(_keyOriginalCountdownDuration) ?? 25 * 60;
    final focusSessionIdRaw = prefs.getInt(_keyFocusSessionId) ?? -1;
    final focusSessionId = focusSessionIdRaw == -1 ? null : focusSessionIdRaw;
    final lastUpdatedStr = prefs.getString(_keyLastUpdated);
    
    // 检查状态是否过期（超过 24 小时）
    if (lastUpdatedStr != null) {
      try {
        final lastUpdated = DateTime.parse(lastUpdatedStr);
        final now = DateTime.now();
        if (now.difference(lastUpdated).inHours > 24) {
          // 状态过期，清除
          await clearState();
          return null;
        }
      } catch (e) {
        // 解析失败，清除状态
        await clearState();
        return null;
      }
    }
    
    // 如果没有开始，返回 null
    if (!isStarted) {
      return null;
    }
    
    // 解析开始时间
    DateTime? startTime;
    final startTimeStr = prefs.getString(_keyStartTime);
    if (startTimeStr != null) {
      try {
        startTime = DateTime.parse(startTimeStr);
      } catch (e) {
        // 解析失败，清除状态
        await clearState();
        return null;
      }
    }
    
    // 解析暂停时间段列表
    List<({DateTime start, DateTime end})> pausePeriods = [];
    final pausePeriodsStr = prefs.getString(_keyPausePeriods);
    if (pausePeriodsStr != null) {
      try {
        final pausePeriodsJson = jsonDecode(pausePeriodsStr) as List;
        pausePeriods = pausePeriodsJson.map((item) {
          final start = DateTime.parse(item['start'] as String);
          final end = DateTime.parse(item['end'] as String);
          return (start: start, end: end);
        }).toList();
      } catch (e) {
        // 解析失败，使用空列表
        pausePeriods = [];
      }
    }
    
    // 计算当前状态（基于时间戳回算）
    Duration forwardElapsed = Duration.zero;
    Duration countdownRemaining = Duration(seconds: countdownDuration);
    
    if (startTime != null) {
      final now = DateTime.now();
      final totalDuration = now.difference(startTime);
      
      final pauseDuration = pausePeriods.fold<Duration>(
        Duration.zero,
        (sum, period) => sum + period.end.difference(period.start),
      );
      
      forwardElapsed = totalDuration - pauseDuration;
      if (forwardElapsed.isNegative) {
        forwardElapsed = Duration.zero;
      }
      
      final elapsedSeconds = forwardElapsed.inSeconds;
      final remainingSeconds = countdownDuration - elapsedSeconds;
      countdownRemaining = Duration(seconds: remainingSeconds);
    }
    
    return ClockTimerState(
      isStarted: isStarted,
      isPaused: isPaused,
      forwardElapsed: forwardElapsed,
      countdownRemaining: countdownRemaining,
      startTime: startTime,
      pausePeriods: pausePeriods,
      countdownDuration: countdownDuration,
      originalCountdownDuration: originalCountdownDuration,
      focusSessionId: focusSessionId,
    );
  }

  /// 清除持久化状态
  Future<void> clearState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsStarted);
    await prefs.remove(_keyIsPaused);
    await prefs.remove(_keyStartTime);
    await prefs.remove(_keyPausePeriods);
    await prefs.remove(_keyCountdownDuration);
    await prefs.remove(_keyOriginalCountdownDuration);
    await prefs.remove(_keyFocusSessionId);
    await prefs.remove(_keyLastUpdated);
  }
}

