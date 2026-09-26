import 'package:flutter_test/flutter_test.dart';
import 'package:sr2editor/codec/save_codec.dart';
import 'package:sr2editor/models/game_data.dart';
import 'package:sr2editor/state/editor_controller.dart';

/// 与仓库 Python 解码器输出一致的基准存档。
const sampleSave =
    'akY97ss*CrEFUKYWLCbHNVgaM9TKjvXfIBkXYmx45yRs16AbEQLriOHU7XxE13rAFrOBtNUlFJnn6uI4woiHiexuMRXDw1xxHIQSPR9YL9ckJ*W9wW8XD8Dz8d4q9jyEPPcQo8TTIjPwbeedI.2SWlyvqAJdh6rBXBW6nYD0btmFmvHyS068UEugqvvjQxq2lIlFfejCuD22lCW.fldPZ*ilvcUjzQG4zzKWOmz0Yo.nzEQXP.fu92NUhf8Vdk3iTJt02FRJ0R8KYf*JkX6I4KCe8qMS0OjxMiL3MSBoPoSEhHDu.9qDchyDA2PAjKhA1AtGqjH*sexsgC4*Jgui.RZ1uxBnlPpgx5c7dZHGENJ61c3IpdUw7DwbjVkBKLwrKWQ2uQjyBzFQyL4586Pz1ArMVTgfrTHget30thk.wBujV2xhvaUvD.aWyK4y84ewSpFJzlRexEYH02CRvPXIQnfU';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('资产编码与基准字母表一致', () {
    expect(
        saveAlphabet,
        '01WtCplxayfTvqchHmA9*JZOri6VN7L4w8dUGe.S3FIDzsnPbEkQXYMRgu25BjoK');
  });
  group('decodeSave', () {
    final result = decodeSave(sampleSave);
    final c = result.data;

    test('展开为 768 个 6-bit 值', () {
      expect(c.length, 768);
      expect(c.every((v) => v >= 0 && v <= 63), isTrue);
      expect(c[0], 1); // version
    });

    test('头部字段与 Python 基准一致', () {
      expect(readBits(c, Fields.userId, 8), isNot(0));
      expect(readBits(c, Fields.stage, 2), 1);
      expect(c[Fields.party], 4);
      expect(readBits(c, Fields.level, 2), 45);
      expect(readBits(c, Fields.exp, 4), 990010);
      expect(readBits(c, Fields.gold, 4), 218975);
    });

    test('角色数据', () {
      expect([for (var i = 0; i < 4; i++) readBits(c, Fields.skillPoints + i * 2, 2)],
          [0, 0, 0, 0]);
      expect(
          [for (var i = 0; i < 4; i++) readBits(c, Fields.currentHp + i * 3, 3)],
          [240, 150, 150, 315]);
      expect(
          [for (var s = 0; s < 7; s++) readBits(c, Fields.wbStart + s * 2, 2)],
          [20, 0, 0, 50, 0, 18, 0]); // char0 wb
      expect(
          [for (var s = 0; s < 8; s++) readBits(c, Fields.acStart + s * 2, 2)],
          [130, 134, 68, 138, 76, 0, 0, 0]); // char0 equipment
    });

    test('进度数据', () {
      // 关卡 0-21 已解锁，22-31 未解锁
      expect([for (var i = 0; i < 32; i++) c[Fields.hcStages + i]],
          [...List.filled(22, 1), ...List.filled(10, 0)]);
      // 成就：60 项非零
      expect(
          [for (var i = 0; i < 128; i++) c[Fields.lcAchievements + i]]
              .where((v) => v > 0)
              .length,
          60);
      expect([for (var i = 0; i < 10; i++) c[Fields.ncMedals + i]],
          [1, 0, 1, 0, 0, 0, 0, 0, 0, 0]);
      expect([for (var i = 0; i < 9; i++) c[Fields.skillsIb + i]],
          [1, 1, 1, 1, 1, 0, 0, 0, 0]);
      // 图鉴 97 项已遇见
      expect(
          [for (var i = 0; i < 128; i++) c[Fields.jcMonsters + i]]
              .where((v) => v > 0)
              .length,
          97);
      expect(c[Fields.jbUsedSp], 5);
      expect(c[Fields.nbCliffStop], 1);
    });

    test('背包数量', () {
      expect(c[Fields.ccStart + 4], 11); // Glove x11
      expect(c[Fields.ccStart + 14], 7); // Triple arrow x7
      expect(
          [for (var i = 0; i < 256; i++) c[Fields.ccStart + i]]
              .where((v) => v > 0)
              .length,
          124);
    });

    test('损坏字符串报错', () {
      expect(() => decodeSave('ab'), throwsFormatException);
      // 截断最后一个字符 → 尾部校验和不匹配
      expect(
          () => decodeSave(sampleSave.substring(0, sampleSave.length - 1)),
          throwsFormatException);
    });
  });

  group('encodeSave', () {
    final c = decodeSave(sampleSave).data;

    test('编码 → 解码往返一致', () {
      final s = encodeSave(c);
      final back = decodeSave(s).data;
      expect(back, c);
    });

    test('随机盐产生不同密文但等价', () {
      final a = decodeSave(encodeSave(c)).data;
      final b = decodeSave(encodeSave(c)).data;
      expect(a, c);
      expect(b, c);
    });

    test('边界值：24 位字段上限', () {
      final copy = List<int>.of(c);
      writeBits(copy, Fields.gold, 4, 16777215);
      expect(readBits(copy, Fields.gold, 4), 16777215);
      writeBits(copy, Fields.gold, 4, 0);
      expect(readBits(copy, Fields.gold, 4), 0);
      final back = decodeSave(encodeSave(copy)).data;
      expect(readBits(back, Fields.gold, 4), 0);
    });
  });

  group('EditorController', () {
    late EditorController controller;

    setUp(() {
      final catalog = GameCatalog.tryParse(
        itemStatsJson: '{"9": {"name": "Sword", "type_category": 3, "icon": 6,'
            ' "item_class": 2, "at_min": 3, "at_max": 4, "agi": 20, "range": 24,'
            ' "lv_cap": 5, "damage_type": "Physical", "damage_type_id": 0},'
            ' "28": {"name": "Headband", "type_category": 6, "icon": 64,'
            ' "item_class": 10, "damage_type": "Physical", "damage_type_id": 0}}',
        achievementDataJson: '{"stages": [{"id": 1, "name": "Village", "area": 0},'
            ' {"id": 2, "name": "Cave 1", "area": 0}],'
            ' "achievements": [{"id": 0, "name": "Stage clear", "stage_id": 2,'
            ' "target_value": 1}], "medals": [{"name": "Gold Shower", "value": 15}],'
            ' "stage_medal_items": {}}',
        sourceLabel: 'test',
      )!;
      controller = EditorController(catalog: catalog);
    });

    test('载入与读取', () {
      expect(controller.loadFromString(sampleSave), isNull);
      expect(controller.hasSave, isTrue);
      expect(controller.userId, '25AMfBAA');
      expect(controller.gold, 218975);
      expect(controller.exp, 990010);
      expect(controller.level, 45);
      expect(controller.partyCount, 4);
      expect(controller.stage, 1);
      expect(controller.equipment(0, 0), 130);
      expect(controller.weaponStat(0, 0), 20);
      expect(controller.itemCount(4), 11);
      expect(controller.achievementCompleted(2), isTrue); // 10 >= target 10
      expect(controller.achievementCompleted(3), isTrue); // 20 >= 20
    });

    test('修改后重新编码可回读', () {
      controller.loadFromString(sampleSave);
      controller
        ..setGold(16777215)
        ..setExp(12345)
        ..setLevel(99)
        ..setStage(16)
        ..setPartyCount(1)
        ..setSkillPoint(2, 77)
        ..setCurrentHp(1, 4321)
        ..setWeaponStat(0, 0, 196)
        ..setEquipment(3, 0, 9)
        ..setItemCount(200, 63)
        ..setStageUnlocked(30, true)
        ..setAchievementCompleted(1, true)
        ..setMedalUnlocked(4, true)
        ..setSkillFlag(8, true)
        ..setMonsterState(0, 0)
        ..setAutoMove(3, true)
        ..setCliffStop(false)
        ..setUsedSp(10);

      final reloaded = EditorController(catalog: controller.catalog)
        ..loadFromString(controller.encode()!);
      expect(reloaded.gold, 16777215);
      expect(reloaded.exp, 12345);
      expect(reloaded.level, 99);
      expect(reloaded.stage, 16);
      expect(reloaded.partyCount, 1);
      expect(reloaded.skillPoint(2), 77);
      expect(reloaded.currentHp(1), 4321);
      expect(reloaded.weaponStat(0, 0), 196);
      expect(reloaded.equipment(3, 0), 9);
      expect(reloaded.itemCount(200), 63);
      expect(reloaded.stageUnlocked(30), isTrue);
      expect(reloaded.achievementCompleted(1), isTrue);
      expect(reloaded.medalUnlocked(4), isTrue);
      expect(reloaded.skillFlag(8), isTrue);
      expect(reloaded.monsterState(0), 0);
      expect(reloaded.autoMove(3), isTrue);
      expect(reloaded.cliffStop, isFalse);
      expect(reloaded.usedSp, 10);
    });

    test('批量操作', () {
      controller.loadFromString(sampleSave);
      controller
        ..unlockAllStages()
        ..completeAllAchievements()
        ..unlockAllMedals()
        ..unlockAllSkillFlags()
        ..viewAllMonsters()
        ..fillInventory({4, 5, 6}, count: 63)
        ..clearInventory();
      expect([for (var i = 0; i < 32; i++) controller.stageUnlocked(i)],
          everyElement(isTrue));
      expect(controller.achievementCompleted(0), isTrue);
      expect(controller.achievementCompleted(127), isTrue);
      expect(controller.medalUnlocked(9), isTrue);
      expect(controller.skillFlag(8), isTrue);
      expect(controller.monsterState(127), 2);
      expect(controller.itemCount(4), 0);
    });

    test('非法输入返回错误信息', () {
      expect(controller.loadFromString(''), isNotNull);
      expect(controller.loadFromString('abc'), isNotNull);
      expect(controller.hasSave, isFalse);
    });
  });

  group('GameCatalog', () {
    test('内置资产可加载', () async {
      final catalog = await GameCatalog.loadFromAssets();
      expect(catalog.itemCount, greaterThan(100));
      expect(catalog.itemName(9), 'Sword');
      expect(catalog.itemCategory(9), 'Weapon');
      expect(catalog.weaponSubtype(9), '剑');
      expect(catalog.stageName(2), 'Cave 1');
      expect(catalog.medalName(0), 'Gold Shower');
      expect(catalog.achievementDef(0).name, 'Stage clear');
      expect(catalog.categoryLabel(28), '帽子');
      expect(catalog.categoryLabel(72), '护符');
    });
  });
}
