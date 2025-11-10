import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';

import '../../../core/constants/font_scale_level.dart';
import '../../database/database_adapter.dart';
import '../../database/objectbox_adapter.dart';
import '../../models/preference.dart';
import '../../objectbox/converters.dart';
import '../../objectbox/preference_entity.dart';
import '../preference_repository.dart';

class ObjectBoxPreferenceRepository implements PreferenceRepository {
  const ObjectBoxPreferenceRepository(this._adapter);

  final DatabaseAdapter _adapter;

  static const String _defaultPreferenceId = 'default';

  ObjectBoxAdapter get _objectBoxAdapter {
    final adapter = _adapter;
    if (adapter is! ObjectBoxAdapter) {
      throw StateError('ObjectBoxPreferenceRepository requires ObjectBoxAdapter');
    }
    return adapter;
  }

  Box<PreferenceEntity> get _preferenceBox =>
      _objectBoxAdapter.store.box<PreferenceEntity>();

  @override
  Future<Preference> load() async {
    return await _adapter.readTransaction(() async {
      final box = _preferenceBox;
      
      // 查找默认偏好设置
      PreferenceEntity? entity;
      for (final e in box.getAll()) {
        if (e.id == _defaultPreferenceId) {
          entity = e;
          break;
        }
      }

      // 如果不存在，创建默认设置
      if (entity == null) {
        final now = DateTime.now();
        entity = PreferenceEntity(
          id: _defaultPreferenceId,
          localeCode: 'en',
          themeModeIndex: themeModeToIndex(ThemeMode.system),
          fontScaleLevel: FontScaleLevel.medium.name,
          clockTickSoundEnabled: true,
          updatedAt: now,
        );
        box.put(entity);
      }

      return _toPreference(entity);
    });
  }

  @override
  Future<void> update(PreferenceUpdate payload) async {
    await _adapter.writeTransaction(() async {
      final box = _preferenceBox;
      
      // 查找现有偏好设置
      PreferenceEntity? entity;
      for (final e in box.getAll()) {
        if (e.id == _defaultPreferenceId) {
          entity = e;
          break;
        }
      }

      // 如果不存在，先创建默认设置
      if (entity == null) {
        final now = DateTime.now();
        entity = PreferenceEntity(
          id: _defaultPreferenceId,
          localeCode: 'en',
          themeModeIndex: themeModeToIndex(ThemeMode.system),
          fontScaleLevel: FontScaleLevel.medium.name,
          clockTickSoundEnabled: true,
          updatedAt: now,
        );
        box.put(entity);
      }

      // 更新字段
      final now = DateTime.now();
      final updatedEntity = PreferenceEntity(
        obxId: entity.obxId,
        id: entity.id,
        localeCode: payload.localeCode ?? entity.localeCode,
        themeModeIndex: payload.themeMode != null
            ? themeModeToIndex(payload.themeMode!)
            : entity.themeModeIndex,
        fontScaleLevel: payload.fontScaleLevel?.name ?? entity.fontScaleLevel,
        clockTickSoundEnabled:
            payload.clockTickSoundEnabled ?? entity.clockTickSoundEnabled,
        updatedAt: now,
      );

      box.put(updatedEntity);
    });
  }

  @override
  Stream<Preference> watch() {
    // 使用 ObjectBoxAdapter 的 watch 方法
    return _adapter.watch<PreferenceEntity>((builder) {
      // 查询所有偏好设置（应该只有一个）
      return builder;
    }).asyncMap((entities) async {
      // 查找默认偏好设置
      PreferenceEntity? entity;
      for (final e in entities) {
        if (e.id == _defaultPreferenceId) {
          entity = e;
          break;
        }
      }

      // 如果不存在，先创建默认设置
      if (entity == null) {
        final now = DateTime.now();
        entity = PreferenceEntity(
          id: _defaultPreferenceId,
          localeCode: 'en',
          themeModeIndex: themeModeToIndex(ThemeMode.system),
          fontScaleLevel: FontScaleLevel.medium.name,
          clockTickSoundEnabled: true,
          updatedAt: now,
        );
        _preferenceBox.put(entity);
      }

      return _toPreference(entity);
    });
  }

  Preference _toPreference(PreferenceEntity entity) {
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
