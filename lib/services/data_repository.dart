/// 数据覆盖持久化（官网更新结果）与主题偏好。
library;

import 'package:flutter/material.dart';
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
  Future<GameCatalog> load() async {
    final itemJson = _prefs.getString(PrefsKeys.itemStats);
    final achJson = _prefs.getString(PrefsKeys.achievementData);
    if (itemJson != null && achJson != null) {
      final catalog = GameCatalog.tryParse(
        itemStatsJson: itemJson,
        achievementDataJson: achJson,
        sourceLabel: '官网更新',
      );
      if (catalog != null) return catalog;
    }
    return GameCatalog.loadFromAssets();
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
