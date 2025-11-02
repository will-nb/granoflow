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
  final dir = await getApplicationSupportDirectory();
  return Isar.open(
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
}
