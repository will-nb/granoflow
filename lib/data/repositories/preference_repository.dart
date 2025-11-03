import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/constants/font_scale_level.dart';
import '../isar/preference_entity.dart';
import '../models/preference.dart';

abstract class PreferenceRepository {
  Stream<Preference> watch();

  Future<Preference> load();

  Future<void> update(PreferenceUpdate payload);
}

class IsarPreferenceRepository implements PreferenceRepository {
  IsarPreferenceRepository(this._isar);

  final Isar _isar;

  static const int _singletonId = 1;

  @override
  Stream<Preference> watch() {
    return _isar.preferenceEntitys
        .watchObject(_singletonId, fireImmediately: true)
        .asyncMap((entity) async {
          final ensured = await _ensureEntity(entity);
          return _toDomain(ensured);
        });
  }

  @override
  Future<Preference> load() async {
    final entity = await _isar.preferenceEntitys.get(_singletonId);
    final ensured = await _ensureEntity(entity);
    return _toDomain(ensured);
  }

  @override
  Future<void> update(PreferenceUpdate payload) async {
    await _isar.writeTxn(() async {
      final entity = await _ensureEntity(
        await _isar.preferenceEntitys.get(_singletonId),
      );
      if (payload.localeCode != null) {
        entity.localeCode = payload.localeCode!;
      }
      if (payload.themeMode != null) {
        entity.themeMode = payload.themeMode!;
      }
      if (payload.fontScaleLevel != null) {
        entity.fontScaleLevel = payload.fontScaleLevel!.name;
      }
      entity.updatedAt = DateTime.now();
      await _isar.preferenceEntitys.put(entity);
    });
  }

  Future<PreferenceEntity> _ensureEntity(PreferenceEntity? entity) async {
    if (entity != null) {
      return entity;
    }
    // 使用系统默认语言，支持 zh_CN, zh_HK, en 等
    String systemLocale = 'en';
    try {
      final platformLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (platformLocale.countryCode != null) {
        systemLocale = '${platformLocale.languageCode}_${platformLocale.countryCode}';
      } else {
        systemLocale = platformLocale.languageCode;
      }
    } catch (e) {
      // 如果无法获取系统语言，使用默认值 'en'
      systemLocale = 'en';
    }
    
    final newEntity = PreferenceEntity()
      ..id = _singletonId
      ..localeCode = systemLocale
      ..themeMode = ThemeMode.system
      ..fontScaleLevel = FontScaleLevel.medium.name  // 默认字体大小级别："中" (Default font size level: "Medium")
      ..updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.preferenceEntitys.put(newEntity);
    });
    return newEntity;
  }

  Preference _toDomain(PreferenceEntity entity) {
    return Preference(
      id: entity.id,
      localeCode: entity.localeCode,
      themeMode: entity.themeMode,
      fontScaleLevel: FontScaleLevel.fromString(entity.fontScaleLevel),
      updatedAt: entity.updatedAt,
    );
  }
}
