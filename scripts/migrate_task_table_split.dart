import 'dart:io';

import 'package:isar/isar.dart';

import '../lib/data/migrations/task_table_split_migrator.dart';

Future<void> main(List<String> arguments) async {
  final mode = _parseMode(arguments);
  if (mode == _Mode.help) {
    _printUsage();
    return;
  }

  final isar = Isar.getInstance();
  if (isar == null) {
    stderr.writeln('未找到现有 Isar 实例，后续迭代将会提供独立的数据库打开逻辑。');
    exitCode = 1;
    return;
  }

  final migrator = TaskTableSplitMigrator(isar);
  switch (mode) {
    case _Mode.dryRun:
      final report = await migrator.dryRun();
      stdout.writeln(
        'Dry-run 完成：projects=${report.projectCount}, milestones=${report.milestoneCount}, tasks=${report.taskCount}',
      );
      break;
    case _Mode.apply:
      final report = await migrator.apply();
      stdout.writeln(
        '迁移完成：projects=${report.projectCount}, milestones=${report.milestoneCount}, tasks=${report.taskCount}',
      );
      break;
    case _Mode.rollback:
      await migrator.rollback();
      stdout.writeln('回滚完成');
      break;
    case _Mode.help:
      _printUsage();
      break;
  }
}

void _printUsage() {
  stdout.writeln(
    '用法: dart run scripts/migrate_task_table_split.dart [--dry-run | --apply | --rollback]\n'
    '  --dry-run   : 输出迁移前的统计信息，不改动数据\n'
    '  --apply     : 执行迁移\n'
    '  --rollback  : 回滚迁移结果\n'
    '未提供参数时显示此帮助',
  );
}

_Mode _parseMode(List<String> args) {
  if (args.contains('--dry-run')) {
    return _Mode.dryRun;
  }
  if (args.contains('--apply')) {
    return _Mode.apply;
  }
  if (args.contains('--rollback')) {
    return _Mode.rollback;
  }
  return _Mode.help;
}

enum _Mode { help, dryRun, apply, rollback }
