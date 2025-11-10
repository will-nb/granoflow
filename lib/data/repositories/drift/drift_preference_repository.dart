import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/font_scale_level.dart';
import '../../database/database_adapter.dart';
import '../../drift/database.dart' hide Preference;
import '../../drift/database.dart' as drift show Preference;
import '../../drift/converters.dart';
import '../../models/preference.dart';
import '../../objectbox/converters.dart';
import '../preference_repository.dart';

/// Drift 版本的 PreferenceRepository 实现
class DriftPreferenceRepository implements PreferenceRepository {
  DriftPreferenceRepository(this._adapter);

  final DatabaseAdapter _adapter;

  /// 获取 AppDatabase 实例
  AppDatabase get _db => AppDatabase.instance;

  static const String _defaultPreferenceId = 'default';

  @override
  Stream<Preference> watch() {
    final query = _db.select(_db.preferences)
      ..where((p) => p.id.equals(_defaultPreferenceId));
    return query.watchSingleOrNull().asyncMap((entity) async {
      // 如果不存在，创建默认设置
      if (entity == null) {
        final now = DateTime.now();
        await _db.into(_db.preferences).insert(PreferencesCompanion(
          id: Value(_defaultPreferenceId),
          localeCode: const Value('en'),
          themeModeIndex: Value(themeModeToIndex(ThemeMode.system)),
          fontScaleLevel: Value(FontScaleLevel.medium.name),
          clockTickSoundEnabled: const Value(true),
          updatedAt: Value(now),
        ));
        // 重新查询
        final newEntity = await query.getSingleOrNull();
        return _toPreference(newEntity!);
      }
      return _toPreference(entity);
    });
  }

  @override
  Future<Preference> load() async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.preferences)
        ..where((p) => p.id.equals(_defaultPreferenceId));
      var entity = await query.getSingleOrNull();

      // 如果不存在，创建默认设置
      if (entity == null) {
        final now = DateTime.now();
        await _db.into(_db.preferences).insert(PreferencesCompanion(
          id: Value(_defaultPreferenceId),
          localeCode: Value('en'),
          themeModeIndex: Value(themeModeToIndex(ThemeMode.system)),
          fontScaleLevel: Value(FontScaleLevel.medium.name),
          clockTickSoundEnabled: const Value(true),
          updatedAt: Value(now),
        ));
        entity = await query.getSingleOrNull();
      }

      return _toPreference(entity!);
    });
  }

  @override
  Future<void> update(PreferenceUpdate payload) async {
    await _adapter.writeTransaction(() async {
      // 查找现有偏好设置
      final query = _db.select(_db.preferences)
        ..where((p) => p.id.equals(_defaultPreferenceId));
      var entity = await query.getSingleOrNull();

      // 如果不存在，先创建默认设置
      if (entity == null) {
        final now = DateTime.now();
        await _db.into(_db.preferences).insert(PreferencesCompanion(
          id: Value(_defaultPreferenceId),
          localeCode: Value('en'),
          themeModeIndex: Value(themeModeToIndex(ThemeMode.system)),
          fontScaleLevel: Value(FontScaleLevel.medium.name),
          clockTickSoundEnabled: const Value(true),
          updatedAt: Value(now),
        ));
        entity = await query.getSingleOrNull();
      }

      // 更新字段
      final companion = PreferencesCompanion(
        localeCode: payload.localeCode != null ? Value(payload.localeCode!) : const Value.absent(),
        themeModeIndex: payload.themeMode != null ? Value(themeModeToIndex(payload.themeMode!)) : const Value.absent(),
        fontScaleLevel: payload.fontScaleLevel != null ? Value(payload.fontScaleLevel!.name) : const Value.absent(),
        clockTickSoundEnabled: payload.clockTickSoundEnabled != null ? Value(payload.clockTickSoundEnabled!) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      );

      await (_db.update(_db.preferences)..where((p) => p.id.equals(_defaultPreferenceId))).write(companion);
    });
  }

  /// 将 Drift Preference 实体转换为领域模型 Preference
  Preference _toPreference(drift.Preference entity) {
    return Preference(
      id: entity.id,
      localeCode: entity.localeCode,
      themeMode: themeModeFromIndex(entity.themeModeIndex),
      fontScaleLevel: FontScaleLevel.fromString(entity.fontScaleLevel),
      clockTickSoundEnabled: entity.clockTickSoundEnabled,
      updatedAt: entity.updatedAt,
    );
  }
}
