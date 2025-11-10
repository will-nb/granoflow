import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/tag.dart';
import 'app_config_providers.dart';
import 'service_providers.dart';

final contextTagOptionsProvider = FutureProvider<List<Tag>>((ref) async {
  try {
    // 依赖种子初始化：导入完成后会刷新本 Provider
    ref.watch(seedInitializerProvider);
    return await ref.watch(taskServiceProvider).listTagsByKind(TagKind.context);
  } catch (error) {
    debugPrint('ContextTagOptionsProvider error: $error');
    return <Tag>[]; // 返回空列表而不是抛出错误
  }
});

final priorityTagOptionsProvider = FutureProvider<List<Tag>>((ref) async {
  try {
    // 依赖种子初始化：导入完成后会刷新本 Provider
    ref.watch(seedInitializerProvider);
    return await ref
        .watch(taskServiceProvider)
        .listTagsByKind(TagKind.priority);
  } catch (error) {
    debugPrint('PriorityTagOptionsProvider error: $error');
    return <Tag>[]; // 返回空列表而不是抛出错误
  }
});

final urgencyTagOptionsProvider = FutureProvider<List<Tag>>((ref) async {
  try {
    // 依赖种子初始化：导入完成后会刷新本 Provider
    ref.watch(seedInitializerProvider);
    final taskService = await ref.read(taskServiceProvider.future);
    return await taskService.listTagsByKind(TagKind.urgency);
  } catch (error) {
    debugPrint('UrgencyTagOptionsProvider error: $error');
    return <Tag>[]; // 返回空列表而不是抛出错误
  }
});

final importanceTagOptionsProvider = FutureProvider<List<Tag>>((ref) async {
  try {
    // 依赖种子初始化：导入完成后会刷新本 Provider
    ref.watch(seedInitializerProvider);
    return await ref
        .watch(taskServiceProvider)
        .listTagsByKind(TagKind.importance);
  } catch (error) {
    debugPrint('ImportanceTagOptionsProvider error: $error');
    return <Tag>[]; // 返回空列表而不是抛出错误
  }
});

final executionTagOptionsProvider = FutureProvider<List<Tag>>((ref) async {
  try {
    ref.watch(seedInitializerProvider);
    final taskService = await ref.read(taskServiceProvider.future);
    return await taskService.listTagsByKind(TagKind.execution);
  } catch (error) {
    debugPrint('ExecutionTagOptionsProvider error: $error');
    return <Tag>[];
  }
});

