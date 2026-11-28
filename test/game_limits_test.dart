import 'package:flutter_test/flutter_test.dart';
import 'package:sr2editor/codec/game_limits.dart';
import 'package:sr2editor/codec/game_guard.dart';
import 'package:sr2editor/codec/save_codec.dart';
import 'package:sr2editor/models/game_data.dart';
import 'package:sr2editor/state/editor_controller.dart';

/// 与 codec_test 相同的基准存档。
const sampleSave =
    'akY97ss*CrEFUKYWLCbHNVgaM9TKjvXfIBkXYmx45yRs16AbEQLriOHU7XxE13rAFrOBtNUlFJnn6uI4woiHiexuMRXDw1xxHIQSPR9YL9ckJ*W9wW8XD8Dz8d4q9jyEPPcQo8TTIjPwbeedI.2SWlyvqAJdh6rBXBW6nYD0btmFmvHyS068UEugqvvjQxq2lIlFfejCuD22lCW.fldPZ*ilvcUjzQG4zzKWOmz0Yo.nzEQXP.fu92NUhf8Vdk3iTJt02FRJ0R8KYf*JkX6I4KCe8qMS0OjxMiL3MSBoPoSEhHDu.9qDchyDA2PAjKhA1AtGqjH*sexsgC4*Jgui.RZ1uxBnlPpgx5c7dZHGENJ61c3IpdUw7DwbjVkBKLwrKWQ2uQjyBzFQyL4586Pz1ArMVTgfrTHget30thk.wBujV2xhvaUvD.aWyK4y84ewSpFJzlRexEYH02CRvPXIQnfU';

EditorController _newController() {
  final catalog = GameCatalog.tryParse(
    itemStatsJson: '{"9": {"name": "Sword", "type_category": 3, "icon": 6,'
        ' "item_class": 2, "damage_type": "Physical", "damage_type_id": 0}}',
    achievementDataJson: '{"stages": [], "achievements": [], "medals": []}',
    sourceLabel: 'test',
  )!;
  return EditorController(catalog: catalog);
}

void main() {
  group('GameLimits 与游戏 gg() 一致', () {
    test('标量上限照抄游戏判断式', () {
      // gg(): if(0>Xa||99<Xa) / if(0>Ya||9999999<Ya) / if(0>Za||9999999<Za)
      expect(GameLimits.levelMax, 99);
      expect(GameLimits.expMax, 9999999);
      expect(GameLimits.goldMax, 9999999);
      // gg(): if(0>$a[a]||196<$a[a]) —— 技能点存储 12bit 但游戏只认 196
      expect(GameLimits.skillPointMax, 196);
      expect(GameLimits.weaponStatMax, 196);
      expect(GameLimits.dodgeMax, 25);
      expect(GameLimits.partyMax, 4);
    });

    test('上限严格小于 12/24 bit 存储容量', () {
      expect(GameLimits.expMax, lessThan(1 << 24));
      expect(GameLimits.goldMax, lessThan(1 << 24));
      expect(GameLimits.skillPointMax, lessThan(1 << 12));
      expect(GameLimits.levelMax, lessThan(1 << 12));
    });

    test('物品 ID 白名单覆盖游戏 r[] 的 155 项', () {
      final ids = [
        for (var i = 0; i < 256; i++)
          if (GameLimits.isDefinedItem(i)) i,
      ];
      expect(ids.length, 155);
      expect(GameLimits.isDefinedItem(0), isTrue); // NONE
      expect(GameLimits.isDefinedItem(114), isTrue); // Garnet Amulet（JSON 缺失但游戏有）
      expect(GameLimits.isDefinedItem(161), isTrue);
      expect(GameLimits.isDefinedItem(165), isTrue); // Fire tornado（v1.4 新增）
      expect(GameLimits.isDefinedItem(142), isFalse); // r[] 未定义
      expect(GameLimits.isDefinedItem(152), isFalse);
      expect(GameLimits.isDefinedItem(166), isFalse);
      expect(GameLimits.isDefinedItem(255), isFalse);
    });
  });

  group('repairForGame', () {
    test('合法存档不产生任何修改', () {
      final c = decodeSave(sampleSave).data;
      final r = repairForGame(c);
      expect(r.changed, isFalse);
      expect(r.warning, isNull);
    });

    test('越界字段被收敛到游戏上限', () {
      final c = List<int>.of(decodeSave(sampleSave).data);
      writeBits(c, Fields.gold, 4, 16777215); // 编辑器旧上限
      writeBits(c, Fields.exp, 4, 16777215);
      writeBits(c, Fields.level, 2, 4095);
      writeBits(c, Fields.skillPoints, 2, 4095);
      writeBits(c, Fields.wbStart, 2, 4095); // 角色0 近战
      writeBits(c, Fields.wbStart + 6 * 2, 2, 100); // 角色0 闪避
      writeBits(c, Fields.stage, 2, 4000);

      final r = repairForGame(c);
      expect(r.changed, isTrue);
      expect(readBits(c, Fields.gold, 4), GameLimits.goldMax);
      expect(readBits(c, Fields.exp, 4), GameLimits.expMax);
      expect(readBits(c, Fields.level, 2), GameLimits.levelMax);
      expect(readBits(c, Fields.skillPoints, 2), GameLimits.skillPointMax);
      expect(readBits(c, Fields.wbStart, 2), GameLimits.weaponStatMax);
      expect(readBits(c, Fields.wbStart + 6 * 2, 2), GameLimits.dodgeMax);
      expect(readBits(c, Fields.stage, 2), GameLimits.stageMax);
      // 修复后必须能被 encode → decode 往返，且仍在合法范围
      final back = decodeSave(encodeSave(c)).data;
      expect(readBits(back, Fields.gold, 4), lessThanOrEqualTo(GameLimits.goldMax));
    });

    test('非法装备 ID 被清空，合法 ID 保留', () {
      final c = List<int>.of(decodeSave(sampleSave).data);
      writeBits(c, Fields.acStart, 2, 142); // 未定义
      writeBits(c, Fields.acStart + 2, 2, 114); // 定义过（JSON 缺失）

      final r = repairForGame(c);
      expect(readBits(c, Fields.acStart, 2), 0);
      expect(readBits(c, Fields.acStart + 2, 2), 114);
      expect(r.changes, contains('角色1槽1物品142→空'));
    });

    test('告警文案列出被修正字段', () {
      final c = List<int>.of(decodeSave(sampleSave).data);
      writeBits(c, Fields.gold, 4, 99999999 & 0xFFFFFF);
      final r = repairForGame(c);
      expect(r.warning, contains('金币'));
      expect(r.warning, contains('卡死'));
    });
  });

  group('EditorController 写入受游戏上限约束', () {
    late EditorController c;

    setUp(() {
      c = _newController()..loadFromString(sampleSave);
    });

    test('拉满不会写出超过游戏上限的值', () {
      c
        ..setGold(99999999)
        ..setExp(99999999)
        ..setLevel(9999)
        ..setSkillPoint(0, 4095)
        ..setWeaponStat(0, 0, 4095)
        ..setWeaponStat(0, 6, 999)
        ..setStage(4000)
        ..setPartyCount(9);

      final data = c.rawData!;
      expect(readBits(data, Fields.gold, 4), GameLimits.goldMax);
      expect(readBits(data, Fields.exp, 4), GameLimits.expMax);
      expect(readBits(data, Fields.level, 2), GameLimits.levelMax);
      expect(readBits(data, Fields.skillPoints, 2), GameLimits.skillPointMax);
      expect(readBits(data, Fields.wbStart, 2), GameLimits.weaponStatMax);
      expect(readBits(data, Fields.wbStart + 6 * 2, 2), GameLimits.dodgeMax);
      expect(readBits(data, Fields.stage, 2), GameLimits.stageMax);
      expect(data[Fields.party], GameLimits.partyMax);
    });

    test('写入未定义物品 ID 会被拒绝', () {
      c.setEquipment(0, 0, 142); // 游戏 r[] 未定义
      expect(c.equipment(0, 0), 0);
      c.setEquipment(0, 0, 114); // 游戏有定义
      expect(c.equipment(0, 0), 114);
    });

    test('拉满后导出再导入，仍满足游戏约束', () {
      c
        ..setGold(99999999)
        ..setExp(99999999)
        ..setLevel(9999)
        ..setSkillPoint(1, 4095);
      final reparsed = _newController()..loadFromString(c.encode()!);
      expect(reparsed.repairLog, isEmpty);
      expect(reparsed.gold, GameLimits.goldMax);
      expect(reparsed.level, GameLimits.levelMax);
    });

    test('载入脏存档时记录修复日志', () {
      final dirty = List<int>.of(decodeSave(sampleSave).data);
      writeBits(dirty, Fields.gold, 4, 16777215);
      final c2 = _newController()..loadFromString(encodeSave(dirty));
      expect(c2.repairLog, isNotEmpty);
      expect(c2.gold, GameLimits.goldMax);
    });

    test('卸载后修复日志清空', () {
      c.unload();
      expect(c.repairLog, isEmpty);
      expect(c.hasSave, isFalse);
    });
  });
}
