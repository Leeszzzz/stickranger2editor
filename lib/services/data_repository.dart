/// 数据覆盖持久化（官网更新结果）与主题偏好。
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_data.dart';

abstract final class PrefsKeys {
  static const itemStats = 'item_stats_json';
  static const achievementData = 'achievement_data_json';
  static const updatedAt = 'data_updated_at';
  static const themeMode = 'theme_mode';
}

class DataRepository {
  DataRepository(this._prefs);

  final SharedPreferences _prefs;

  String? get updatedAtLabel => _prefs.getString(PrefsKeys.updatedAt);

  /// 优先返回覆盖数据（官网更新），失败回退内置 assets。
  ///
  /// 旧版本覆盖数据可能缺少后加的字段（monster_faces / monster_colors），
  /// 按字段与内置数据合并：覆盖里缺失或为空的一律用内置兜底。
  Future<GameCatalog> load() async {
    final itemJson = _prefs.getString(PrefsKeys.itemStats);
    final achJson = _prefs.getString(PrefsKeys.achievementData);
    if (itemJson != null && achJson != null) {
      final merged = await _mergeWithBuiltin(achJson);
      final catalog = GameCatalog.tryParse(
        itemStatsJson: itemJson,
        achievementDataJson: merged,
        sourceLabel: '官网更新',
      );
      if (catalog != null) return catalog;
    }
    return GameCatalog.loadFromAssets();
  }

  Future<String> _mergeWithBuiltin(String achJson) async {
    try {
      final override = jsonDecode(achJson);
      if (override is! Map<String, dynamic>) return achJson;
      final builtinRaw =
          await rootBundle.loadString('assets/achievement_data.json');
      final builtin = jsonDecode(builtinRaw);
      if (builtin is! Map<String, dynamic>) return achJson;
      const mergeableKeys = [
        'stages',
        'achievements',
        'medals',
        'stage_medal_items',
        'monster_faces',
        'monster_colors',
      ];
      final merged = {...override};
      for (final key in mergeableKeys) {
        final v = merged[key];
        final isEmptyList = v is List && v.isEmpty;
        final isEmptyMap = v is Map && v.isEmpty;
        if (v == null || isEmptyList || isEmptyMap) {
          merged[key] = builtin[key];
        }
      }
      return jsonEncode(merged);
    } catch (_) {
      return achJson;
    }
  }

  Future<bool> saveOverride(String itemStatsJson, String achievementDataJson) async {
    final ok = await Future.wait([
      _prefs.setString(PrefsKeys.itemStats, itemStatsJson),
      _prefs.setString(PrefsKeys.achievementData, achievementDataJson),
      _prefs.setString(
        PrefsKeys.updatedAt,
        DateTime.now().toString().substring(0, 16),
      ),
    ]).then((l) => l.every((e) => e));
    return ok;
  }

  Future<bool> clearOverride() async {
    final ok = await Future.wait([
      _prefs.remove(PrefsKeys.itemStats),
      _prefs.remove(PrefsKeys.achievementData),
      _prefs.remove(PrefsKeys.updatedAt),
    ]).then((l) => l.every((e) => e));
    return ok;
  }
}

class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs);

  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void load() {
    final v = _prefs.getInt(PrefsKeys.themeMode) ?? 0;
    _themeMode = ThemeMode.values.elementAtOrNull(v.clamp(0, 2)) ?? ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs.setInt(PrefsKeys.themeMode, mode.index);
  }
}
