// 重新导出 clock_providers 中的类型以避免重复定义
// 这个文件是为了保持向后兼容性，实际实现都在 clock_providers.dart 中
export 'clock_providers.dart' show ClockTimerState, ClockTimerNotifier, clockTimerProvider;
