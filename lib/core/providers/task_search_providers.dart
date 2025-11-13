import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import 'service_providers.dart';

/// 搜索关键词状态
final taskSearchQueryProvider = StateProvider<String>((ref) => '');

/// 搜索防抖器
class _SearchDebouncer {
  Timer? _timer;
  Completer<List<Task>>? _pending;

  Future<List<Task>> run(Future<List<Task>> Function() action) {
    _timer?.cancel();
    _pending ??= Completer<List<Task>>();
    _timer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final result = await action();
        _pending?.complete(result);
      } catch (err, stack) {
        _pending?.completeError(err, stack);
      } finally {
        _pending = null;
      }
    });
    return _pending!.future;
  }

  void dispose() {
    _timer?.cancel();
    _pending?.completeError(Exception('Debouncer disposed'));
  }
}

/// 搜索结果 Provider（带防抖）
final taskSearchResultsProvider = FutureProvider<List<Task>>((ref) async {
  final query = ref.watch(taskSearchQueryProvider);
  
  // 如果搜索关键词长度 < 3，返回空列表
  if (query.trim().length < 3) {
    return const <Task>[];
  }

  // 使用防抖器延迟搜索
  final debouncer = _SearchDebouncer();
  ref.onDispose(() => debouncer.dispose());

  final taskQueryService = await ref.read(taskQueryServiceProvider.future);
  
  final results = await debouncer.run(() async {
    // 搜索所有状态的任务（不传 status 参数）
    final tasks = await taskQueryService.searchTasksByTitle(
      query,
      limit: 20,
    );
    
    // 按 updatedAt 降序排序（最近更新的在前）
    tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    return tasks;
  });

  return results;
});

/// 搜索加载状态 Provider
final taskSearchLoadingProvider = Provider<bool>((ref) {
  final resultsAsync = ref.watch(taskSearchResultsProvider);
  return resultsAsync.isLoading;
});

