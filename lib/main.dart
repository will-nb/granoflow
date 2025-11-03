import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
// ignore: unused_import
import 'package:isar_flutter_libs/isar_flutter_libs.dart';

import 'core/app.dart';
import 'core/providers/repository_providers.dart';
import 'data/isar/focus_session_entity.dart';
import 'data/isar/preference_entity.dart';
import 'data/isar/project_entity.dart';
import 'data/isar/milestone_entity.dart';
import 'data/isar/seed_import_log_entity.dart';
import 'data/isar/tag_entity.dart';
import 'data/isar/task_entity.dart';
import 'data/isar/task_template_entity.dart';

Isar? _isarInstance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isar = await _openIsar();
  runApp(
    ProviderScope(
      overrides: [isarProvider.overrideWithValue(isar)],
      child: const GranoFlowApp(),
    ),
  );
}

Future<Isar> _openIsar() async {
  // 如果实例已经打开，直接返回（用于集成测试场景）
  if (_isarInstance != null && _isarInstance!.isOpen) {
    return _isarInstance!;
  }

  try {
    final dir = await getApplicationSupportDirectory();
    final isar = await Isar.open(
      [
        TaskEntitySchema,
        TaskTemplateEntitySchema,
        FocusSessionEntitySchema,
        TagEntitySchema,
        PreferenceEntitySchema,
        SeedImportLogEntitySchema,
        ProjectEntitySchema,
        MilestoneEntitySchema,
      ],
      directory: dir.path,
      inspector: false,
    );
    _isarInstance = isar;
    return isar;
  } catch (e) {
    // 如果 Isar 已经打开，尝试获取已打开的实例
    // Isar.open() 在同一个目录下如果已经打开会抛出异常
    // 这种情况下，我们返回缓存的实例（如果存在）
    if (_isarInstance != null && _isarInstance!.isOpen) {
      return _isarInstance!;
    }
    rethrow;
  }
}
