import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_providers.dart';

/// 计时器音频设置状态 Provider
/// 
/// 提供音频开关状态的读取和更新
/// 通过 StreamProvider 监听 Preference 变化，自动同步状态
final clockTickSoundEnabledProvider = StreamProvider<bool>((ref) async* {
  final preferenceService = await ref.read(preferenceServiceProvider.future);
  yield* preferenceService.watch().map((preference) => preference.clockTickSoundEnabled);
});

/// 更新计时器音频设置
Future<void> updateClockTickSoundEnabled(
  WidgetRef ref,
  bool enabled,
) async {
  final preferenceService = await ref.read(preferenceServiceProvider.future);
  await preferenceService.updateClockTickSoundEnabled(enabled);
}

