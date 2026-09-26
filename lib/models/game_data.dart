/// 游戏数据目录：物品属性、关卡、成就、勋章。
///
/// 优先级：SharedPreferences 覆盖（官网更新）> 内置 assets > 内置兜底。
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 物品属性（来自 ranger2.js 的 r[] 数组）。
class ItemStats {
  const ItemStats({
    this.name = '',
    this.typeCategory = 0,
    this.icon = 0,
    this.itemClass = 0,
    this.rangeType = 0,
    this.color = 0,
    this.atMin = 0,
    this.atMax = 0,
    this.bullets = 0,
    this.agi = 0,
    this.range = 0,
    this.hp = 0,
    this.sp = 0,
    this.lvCap = 0,
    this.cost = 0,
    this.damageType = 'Physical',
    this.damageTypeId = 0,
  });

  factory ItemStats.fromJson(Map<String, dynamic> j) => ItemStats(
        name: (j['name'] ?? '').toString(),
        typeCategory: _int(j['type_category']),
        icon: _int(j['icon']),
        itemClass: _int(j['item_class']),
        rangeType: _int(j['range_type']),
        color: _int(j['color']),
        atMin: _int(j['at_min']),
        atMax: _int(j['at_max']),
        bullets: _int(j['bullets']),
        agi: _int(j['agi']),
        range: _int(j['range']),
        hp: _int(j['hp']),
        sp: _int(j['sp']),
        lvCap: _int(j['lv_cap']),
        cost: _int(j['cost']),
        damageType: (j['damage_type'] ?? 'Physical').toString(),
        damageTypeId: _int(j['damage_type_id']),
      );

  final String name;
  final int typeCategory;
  final int icon;
  final int itemClass;
  final int rangeType;
  final int color;
  final int atMin;
  final int atMax;
  final int bullets;
  final int agi;
  final int range;
  final int hp;
  final int sp;
  final int lvCap;
  final int cost;
  final String damageType;
  final int damageTypeId;

  static int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
}

class StageDef {
  const StageDef(this.id, this.name, this.area);
  final int id;
  final String name;
  final int area;
}

class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.stageId = 0,
    this.iconId = 0,
    this.targetValue = 1,
  });

  final int id;
  final String name;
  final String subtitle;
  final int stageId;
  final int iconId;
  final int targetValue;
}

class MedalDef {
  const MedalDef(this.name, this.value);
  final String name;
  final int value;
}

/// 关卡通关奖励物品（hf 数组）。
class StageMedalItem {
  const StageMedalItem(this.stageId, this.itemId, this.name);
  final int stageId;
  final int itemId;
  final String name;
}

/// 内置兜底成就（achievement_data.json 无成就数据时使用，与后端保持一致）。
const Map<int, AchievementDef> _hardcodedAchievements = {
  0: AchievementDef(id: 0, name: 'Stage clear', stageId: 2, targetValue: 1),
  1: AchievementDef(id: 1, name: 'Combo 100', stageId: 2, targetValue: 1),
  2: AchievementDef(
      id: 2, name: 'Giant green slime hunt 10', stageId: 2, targetValue: 10),
  3: AchievementDef(
      id: 3, name: 'Mining 20 gold ores', stageId: 2, targetValue: 20),
  4: AchievementDef(id: 4, name: 'Stickman', stageId: 2, targetValue: 1),
  5: AchievementDef(
      id: 5, name: 'Giant green worm hunt 30', stageId: 3, targetValue: 30),
  6: AchievementDef(
      id: 6, name: 'Pass through (undamaged)', stageId: 3, targetValue: 1),
  7: AchievementDef(id: 7, name: 'Two small rooms', stageId: 3, targetValue: 1),
  8: AchievementDef(
      id: 8, name: 'Defeat Giant Yellow Slime 30s', stageId: 3, targetValue: 1),
  9: AchievementDef(
      id: 9, name: 'Defeat Giant Red Slime 10s', stageId: 3, targetValue: 1),
  10: AchievementDef(id: 10, name: 'Stage clear 60s', stageId: 4, targetValue: 1),
  15: AchievementDef(
      id: 15, name: 'Stage clear without healing', stageId: 5, targetValue: 1),
  20: AchievementDef(
      id: 20, name: 'Stage clear & Combo 87', stageId: 7, targetValue: 1),
  25: AchievementDef(
      id: 25, name: 'Stage clear bonus 2.0', stageId: 8, targetValue: 1),
  30: AchievementDef(
      id: 30, name: 'Stage clear & Combo 111', stageId: 9, targetValue: 1),
  35: AchievementDef(
      id: 35, name: 'Stage clear without healing', stageId: 10, targetValue: 1),
  40: AchievementDef(id: 40, name: 'Stage clear 60s', stageId: 11, targetValue: 1),
  45: AchievementDef(
      id: 45, name: 'Stage clear 120s', stageId: 13, targetValue: 1),
  50: AchievementDef(
      id: 50, name: 'Stage clear without healing', stageId: 14, targetValue: 1),
  55: AchievementDef(
      id: 55, name: 'Stage clear & Combo 227', stageId: 15, targetValue: 1),
  60: AchievementDef(id: 60, name: 'Stage clear', stageId: 16, targetValue: 1),
  65: AchievementDef(
      id: 65, name: 'Stage clear without healing', stageId: 17, targetValue: 1),
  70: AchievementDef(
      id: 70, name: 'Stage clear 150s', stageId: 18, targetValue: 1),
  75: AchievementDef(
      id: 75, name: 'Stage clear & Combo 828', stageId: 19, targetValue: 1),
};

const List<String> _fallbackStageNames = [
  '', 'Village', 'Cave 1', 'Cave 2', 'Cave 3', 'Cave 4', 'Central cavity',
  'Terraced cave', 'Sky garden 1', 'Sky garden 2', 'Sky garden 3',
  'Upper cave', 'Terrace', 'Limestone cave 1', 'Limestone cave 2',
  'Limestone cave 3', 'Limestone cave 4', 'Limestone cave 5',
  'Limestone cave 6', 'Limestone cave 7', 'Limestone cave 8', 'Snow field 1',
];

const List<MedalDef> _fallbackMedals = [
  MedalDef('Gold Shower', 15),
  MedalDef('Clear Status', 30),
  MedalDef('ONIGIRI', 45),
  MedalDef('Level Up', 60),
  MedalDef('Warp Zone', 75),
];

class GameCatalog {
  GameCatalog({
    required Map<int, ItemStats> items,
    required Map<int, StageDef> stages,
    required Map<int, AchievementDef> achievements,
    required List<MedalDef> medals,
    required Map<int, StageMedalItem> stageMedalItems,
    required this.sourceLabel,
  })  : _items = items,
        _stages = stages,
        _achievements = achievements,
        _medals = medals,
        _stageMedalItems = stageMedalItems;

  final Map<int, ItemStats> _items;
  final Map<int, StageDef> _stages;
  final Map<int, AchievementDef> _achievements;
  final List<MedalDef> _medals;
  final Map<int, StageMedalItem> _stageMedalItems;
  final String sourceLabel;

  Map<int, ItemStats> get items => _items;
  Map<int, StageDef> get stages => _stages;
  Map<int, AchievementDef> get achievements => _achievements;
  List<MedalDef> get medals => _medals;
  Map<int, StageMedalItem> get stageMedalItems => _stageMedalItems;

  int get itemCount => _items.length;
  int get achievementCount => _achievements.values
      .where((a) => a.name.isNotEmpty && a.name != 'Achievement ${a.id}')
      .length;

  // ---- 物品 ----

  static const specialItemNames = {0: 'NONE', 1: 'NG', 2: 'gold', 3: 'onigiri'};

  String itemName(int id) {
    final s = _items[id];
    if (s != null && s.name.isNotEmpty) return s.name;
    return specialItemNames[id] ?? (id == 0 ? 'NONE' : 'ID$id');
  }

  ItemStats? itemStats(int id) => _items[id];

  /// 物品大类：None / Consumable / Weapon / Hat / Ring / Amulet / Skill。
  String itemCategory(int id) {
    if (id == 0) return 'None';
    if (id <= 3) return 'Consumable';
    final s = _items[id];
    if (s == null) return 'Consumable';
    switch (s.itemClass) {
      case <= 5:
        return s.typeCategory == 3 ? 'Weapon' : 'Skill';
      case 10:
        return 'Hat';
      case 20:
        return 'Ring';
      case 30:
        return 'Amulet';
      default:
        return 'Consumable';
    }
  }

  /// 武器子类型（仅 typeCategory==3，按 icon 区间）：拳/剑/枪/弓/杖。
  String weaponSubtype(int id) {
    final s = _items[id];
    if (s == null || s.typeCategory != 3) return '';
    if (s.icon <= 5) return '拳套';
    if (s.icon <= 9) return '剑';
    if (s.icon <= 15) return '枪';
    if (s.icon <= 28) return '弓';
    return '杖';
  }

  /// 通用分类标签（中文）。
  String categoryLabel(int id) {
    final cat = itemCategory(id);
    switch (cat) {
      case 'Weapon':
        return weaponSubtype(id);
      case 'Skill':
        return '技能';
      case 'Hat':
        return '帽子';
      case 'Ring':
        return '戒指';
      case 'Amulet':
        return '护符';
      case 'None':
        return '空';
      default:
        return '消耗品';
    }
  }

  // ---- 关卡 / 成就 / 勋章 ----

  String stageName(int id) => _stages[id]?.name ?? (id == 0 ? '' : 'Stage $id');

  int stageArea(int id) => _stages[id]?.area ?? (id <= 7 ? 0 : id <= 12 ? 1 : id <= 20 ? 2 : 3);

  AchievementDef achievementDef(int id) =>
      _achievements[id] ??
      AchievementDef(
          id: id, name: 'Achievement $id', stageId: id == 0 ? 2 : (id ~/ 5) + 2);

  /// 成就 5..9 的显示名（关卡通关勋章，用 stage_medal_items 兜底标注）。
  String medalName(int i) {
    if (i < _medals.length) return _medals[i].name;
    return '通关勋章${i - 4}';
  }

  int medalRequirement(int i) =>
      i < _medals.length ? _medals[i].value : 0;

  // ---- 构造 ----

  /// 从 JSON 字符串构建（物品表 + 成就数据表），解析失败返回 null。
  static GameCatalog? tryParse({
    required String itemStatsJson,
    required String achievementDataJson,
    required String sourceLabel,
  }) {
    try {
      final itemsRaw =
          jsonDecode(itemStatsJson) as Map<String, dynamic>;
      final achRaw = jsonDecode(achievementDataJson) as Map<String, dynamic>;
      return _build(itemsRaw, achRaw, sourceLabel);
    } catch (_) {
      return null;
    }
  }

  /// 内置 assets 优先，失败用最小兜底。
  static Future<GameCatalog> loadFromAssets({String? sourceLabel}) async {
    Map<String, dynamic> itemsRaw = {};
    Map<String, dynamic> achRaw = {};
    try {
      itemsRaw =
          jsonDecode(await rootBundle.loadString('assets/item_stats.json'))
              as Map<String, dynamic>;
    } catch (_) {}
    try {
      achRaw =
          jsonDecode(await rootBundle.loadString('assets/achievement_data.json'))
              as Map<String, dynamic>;
    } catch (_) {}
    return _build(itemsRaw, achRaw, sourceLabel ?? '内置数据');
  }

  static GameCatalog _build(Map<String, dynamic> itemsRaw,
      Map<String, dynamic> achRaw, String sourceLabel) {
    final items = <int, ItemStats>{
      for (final e in itemsRaw.entries)
        ?int.tryParse(e.key): ItemStats.fromJson(e.value as Map<String, dynamic>),
    };

    final stages = <int, StageDef>{};
    for (var i = 0; i < _fallbackStageNames.length; i++) {
      stages[i] = StageDef(i, _fallbackStageNames[i], _areaOf(i));
    }
    for (final s in (achRaw['stages'] as List<dynamic>? ?? [])) {
      if (s is Map) {
        final id = (s['id'] as num?)?.toInt();
        if (id != null) {
          stages[id] = StageDef(
            id,
            (s['name'] ?? '').toString(),
            (s['area'] as num?)?.toInt() ?? _areaOf(id),
          );
        }
      }
    }

    final achievements = <int, AchievementDef>{..._hardcodedAchievements};
    final achList = achRaw['achievements'] as List<dynamic>? ?? [];
    if (achList.isNotEmpty) {
      achievements.clear();
      for (final a in achList.whereType<Map>()) {
        final id = (a['id'] as num?)?.toInt();
        if (id == null) continue;
        achievements[id] = AchievementDef(
          id: id,
          name: (a['name'] ?? '').toString(),
          subtitle: (a['subtitle'] ?? '').toString(),
          stageId: (a['stage_id'] as num?)?.toInt() ?? 0,
          iconId: (a['icon_id'] as num?)?.toInt() ?? 0,
          targetValue: (a['target_value'] as num?)?.toInt() ?? 1,
        );
      }
    }

    final medals = (achRaw['medals'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((m) => MedalDef((m['name'] ?? '').toString(),
            (m['value'] as num?)?.toInt() ?? 0))
        .toList();
    if (medals.isEmpty) medals.addAll(_fallbackMedals);

    final stageMedalItems = <int, StageMedalItem>{};
    for (final e in
        (achRaw['stage_medal_items'] as Map<String, dynamic>? ?? {}).entries) {
      final stageId = int.tryParse(e.key);
      final v = e.value;
      if (stageId != null && v is Map) {
        final itemId = (v['item_id'] as num?)?.toInt() ?? 0;
        if (itemId > 0) {
          stageMedalItems[stageId] = StageMedalItem(
            stageId,
            itemId,
            (v['name'] ?? '').toString(),
          );
        }
      }
    }

    return GameCatalog(
      items: items,
      stages: stages,
      achievements: achievements,
      medals: medals,
      stageMedalItems: stageMedalItems,
      sourceLabel: sourceLabel,
    );
  }

  static int _areaOf(int stageId) {
    if (stageId <= 7) return 0;
    if (stageId <= 12) return 1;
    if (stageId <= 20) return 2;
    return 3;
  }
}

/// 伤害类型颜色（与 Web 版一致）。
const Map<String, int> damageTypeColors = {
  'Physical': 0xFF8B949E,
  'Fire': 0xFFF85149,
  'Ice': 0xFF58A6FF,
  'Lightning': 0xFFE3B341,
  'Poison': 0xFF3FB950,
};

const Map<String, String> damageTypeLabels = {
  'Physical': '物理',
  'Fire': '火',
  'Ice': '冰',
  'Lightning': '雷',
  'Poison': '毒',
};

/// 区域中文名（按 area id）。
const List<String> areaNames = ['洞穴区域', '天空区域', '石灰岩区域', '雪原区域'];
