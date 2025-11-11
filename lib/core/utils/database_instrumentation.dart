import 'package:flutter/foundation.dart';

import '../../data/database/database_adapter.dart';

/// 默认的数据库操作 instrumentation 实现，将日志输出为结构化 JSON Map。
class DefaultDatabaseInstrumentation implements DatabaseInstrumentation {
  DefaultDatabaseInstrumentation({
    this.enabled = true,
    this.slowQueryThresholdMs = 100,
    this.logSink,
  });

  /// 是否启用日志记录
  final bool enabled;

  /// 慢查询阈值（毫秒），超过此阈值的操作会记录警告
  final int slowQueryThresholdMs;

  /// 自定义日志输出目标（如 Sentry、Crashlytics）
  final void Function(Map<String, dynamic> log)? logSink;

  @override
  void onStart(DatabaseOperationContext context) {
    if (!enabled) return;
    
    final log = {
      'timestamp': DateTime.now().toIso8601String(),
      'event': 'operation_start',
      'operation': context.operation,
      'entity': context.entity,
      'parameters': context.parameters,
    };
    
    _outputLog(log);
  }

  @override
  void onSuccess(
    DatabaseOperationContext context, {
    int? affectedCount,
  }) {
    if (!enabled) return;
    
    final duration = context.duration ?? 0;
    final isSlow = duration > slowQueryThresholdMs;
    
    final log = {
      'timestamp': DateTime.now().toIso8601String(),
      'event': isSlow ? 'operation_slow' : 'operation_success',
      'operation': context.operation,
      'entity': context.entity,
      'duration_ms': duration,
      'affected_count': affectedCount,
      'parameters': context.parameters,
    };
    
    if (isSlow) {
      log['warning'] = 'Operation exceeded slow query threshold (${slowQueryThresholdMs}ms)';
    }
    
    _outputLog(log);
  }

  @override
  void onError(DatabaseOperationContext context, Object error) {
    if (!enabled) return;
    
    final duration = context.duration ?? 0;
    
    final log = {
      'timestamp': DateTime.now().toIso8601String(),
      'event': 'operation_error',
      'operation': context.operation,
      'entity': context.entity,
      'duration_ms': duration,
      'error': error.toString(),
      'error_type': error.runtimeType.toString(),
      'parameters': context.parameters,
    };
    
    // 如果是 DatabaseAdapterException，添加更多上下文
    if (error is DatabaseAdapterException) {
      log['error_message'] = error.message;
      if (error.cause != null) {
        log['error_cause'] = error.cause.toString();
      }
      if (error.context != null) {
        log['error_context'] = error.context.toString();
      }
    }
    
    _outputLog(log);
  }

  void _outputLog(Map<String, dynamic> log) {
    if (logSink != null) {
      logSink!(log);
    } else {
      // 默认输出到 debugPrint
      if (kDebugMode) {
        debugPrint('DatabaseInstrumentation: ${log.toString()}');
      }
    }
  }
}

/// 数据库操作计时器，封装 Stopwatch 与慢查询阈值设定。
class DatabaseOpTimer {
  DatabaseOpTimer({
    this.slowQueryThresholdMs = 100,
  });

  final int slowQueryThresholdMs;
  final Stopwatch _stopwatch = Stopwatch();

  /// 开始计时
  void start() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  /// 停止计时并返回耗时（毫秒）
  int stop() {
    _stopwatch.stop();
    return _stopwatch.elapsedMilliseconds;
  }

  /// 检查是否为慢查询
  bool isSlow(int durationMs) {
    return durationMs > slowQueryThresholdMs;
  }

  /// 获取当前耗时（毫秒），不停止计时器
  int get elapsedMs => _stopwatch.elapsedMilliseconds;
}

/// 用于测试的 Fake Instrumentation，记录所有回调以便断言。
class FakeDatabaseInstrumentation implements DatabaseInstrumentation {
  FakeDatabaseInstrumentation();

  final List<DatabaseOperationContext> _started = [];
  final List<DatabaseOperationContext> _succeeded = [];
  final List<MapEntry<DatabaseOperationContext, Object>> _errors = [];

  List<DatabaseOperationContext> get started => List.unmodifiable(_started);
  List<DatabaseOperationContext> get succeeded => List.unmodifiable(_succeeded);
  List<MapEntry<DatabaseOperationContext, Object>> get errors =>
      List.unmodifiable(_errors);

  @override
  void onStart(DatabaseOperationContext context) {
    _started.add(context);
  }

  @override
  void onSuccess(DatabaseOperationContext context, {int? affectedCount}) {
    _succeeded.add(context.copyWith(duration: context.duration));
  }

  @override
  void onError(DatabaseOperationContext context, Object error) {
    _errors.add(MapEntry(context, error));
  }

  /// 清空所有记录
  void clear() {
    _started.clear();
    _succeeded.clear();
    _errors.clear();
  }

  /// 获取操作统计
  Map<String, int> getStats() {
    return {
      'started': _started.length,
      'succeeded': _succeeded.length,
      'errors': _errors.length,
    };
  }
}
