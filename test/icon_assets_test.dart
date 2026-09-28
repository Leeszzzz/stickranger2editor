import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sr2editor/models/game_data.dart';
import 'package:sr2editor/models/icon_assets.dart';
import 'package:sr2editor/services/data_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('旧格式覆盖数据与内置数据按字段合并', () async {
    // 模拟旧版官网更新留下的覆盖：物品有数据，成就/脸谱字段为空。
    SharedPreferences.setMockInitialValues({
      'item_stats_json':
          '{"9": {"name": "SwordX", "type_category": 3, "icon": 6,'
          ' "item_class": 2, "damage_type": "Physical", "damage_type_id": 0}}',
      'achievement_data_json':
          '{"stages": [], "achievements": [], "medals": [],'
          ' "stage_medal_items": {}}',
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = DataRepository(prefs);
    final catalog = await repo.load();
    expect(catalog.sourceLabel, '官网更新');
    expect(catalog.itemName(9), 'SwordX'); // 覆盖的物品数据生效
    expect(catalog.achievementDef(0).name, 'Stage clear'); // 成就由内置补齐
    expect(catalog.monsterFace(0), 0); // 脸谱由内置补齐
    expect(catalog.monsterColor(0), 3394611); // 主色由内置补齐
  });

  test('item_stats 引用的每个 icon 都有对应资产', () async {
    final catalog = await GameCatalog.loadFromAssets();
    final missing = <String, int>{};
    for (final entry in catalog.items.entries) {
      final iconIndex = entry.value.icon;
      if (!kAvailableIconIndices.contains(iconIndex)) {
        missing['${entry.key}(${entry.value.name})'] = iconIndex;
      }
      try {
        await rootBundle.load(iconAssetPath(iconIndex));
      } catch (_) {
        missing['asset:${entry.key}'] = iconIndex;
      }
    }
    expect(missing, isEmpty);
  });

  test('成就奖章与怪物脸谱资产齐全', () async {
    final catalog = await GameCatalog.loadFromAssets();
    final missingMedals = <int>[];
    final missingFaces = <int>[];
    for (final def in catalog.achievements.values) {
      if (!kAvailableMedalIcons.contains(def.iconId)) {
        missingMedals.add(def.iconId);
      }
      try {
        await rootBundle.load(medalAssetPath(def.iconId));
      } catch (_) {
        missingMedals.add(def.iconId);
      }
    }
    for (var i = 0; i < 128; i++) {
      final face = catalog.monsterFace(i);
      if (face == null) continue;
      if (!kAvailableEnemyFaces.contains(face)) missingFaces.add(face);
      try {
        await rootBundle.load(enemyAssetPath(face));
      } catch (_) {
        missingFaces.add(face);
      }
    }
    expect(missingMedals, isEmpty);
    expect(missingFaces, isEmpty);
  });

  test('成就数据为真实游戏数据（非兜底）', () async {
    final catalog = await GameCatalog.loadFromAssets();
    expect(catalog.achievements.length, greaterThanOrEqualTo(80));
    expect(catalog.achievementDef(0).name, 'Stage clear');
    expect(catalog.achievementDef(2).targetValue, 10);
    expect(catalog.monsterFace(0), 0);
    // 怪物 0 = 绿史莱姆，主色 0x33CC33
    expect(catalog.monsterColor(0), 3394611);
  });

  test('iconAssetPath 格式', () {
    expect(iconAssetPath(6), 'assets/icons/icon_006.png');
    expect(iconAssetPath(128), 'assets/icons/icon_128.png');
    expect(medalAssetPath(5), 'assets/icons/medal_05.png');
    expect(enemyAssetPath(19), 'assets/icons/enemy_19.png');
  });
}
