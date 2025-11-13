import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局任务展开状态管理 Provider
/// 
/// 管理所有任务的展开/收缩状态（全局共享，所有页面、所有任务状态都有效）
/// 使用 Set<String> 存储已展开的任务 ID 集合
final taskExpansionProvider = StateProvider<Set<String>>((ref) => <String>{});

