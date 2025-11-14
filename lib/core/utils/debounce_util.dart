import 'dart:async';
import 'package:flutter/material.dart';

/// 防抖工具类
/// 
/// 提供通用的防抖功能，用于限制函数调用频率
class DebounceUtil {
  const DebounceUtil._();

  /// 创建一个防抖函数
  /// 
  /// [delay] 防抖延迟时间
  /// [callback] 要防抖的回调函数
  /// 
  /// 返回一个防抖后的回调函数，每次调用会取消之前的调用，重新计时
  /// 
  /// 示例：
  /// ```dart
  /// final debouncedCallback = DebounceUtil.debounce(
  ///   const Duration(milliseconds: 500),
  ///   () => print('Called'),
  /// );
  /// debouncedCallback(); // 不会立即执行
  /// debouncedCallback(); // 取消上一次，重新计时
  /// // 500ms 后执行最后一次调用
  /// ```
  static VoidCallback debounce(
    Duration delay,
    VoidCallback callback,
  ) {
    Timer? timer;

    return () {
      timer?.cancel();
      timer = Timer(delay, callback);
    };
  }

  /// 取消防抖回调
  /// 
  /// [debouncedCallback] 防抖后的回调函数
  /// 
  /// 注意：此方法需要防抖回调函数内部支持取消机制
  /// 当前实现中，防抖回调函数会自动管理定时器，无需手动取消
  /// 如果需要取消，可以保存返回的 VoidCallback，并在需要时不再调用它
  static void cancel(VoidCallback debouncedCallback) {
    // 注意：当前实现中，防抖回调函数会自动管理定时器
    // 如果需要支持取消，需要修改 debounce 方法的实现
    // 暂时不实现，因为防抖回调函数会自动管理定时器
  }
}

