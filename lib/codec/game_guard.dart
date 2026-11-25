/// 导入存档的「游戏可接受性」修复。
///
/// 解码只保证密文合法；游戏 `gg()` 还要求每个字段落在硬范围内
/// （见 [GameLimits]）。用户在编辑器里把金币拉到 16777215、或外部工具直接
/// 改出越界值，导出后进游戏就会卡死。
///
/// [repairForGame] 就地钳制所有已知越界字段，并返回被修正字段的中文告警，
/// 让 UI 提示用户「改动已按游戏上限收敛」。它只收敛到游戏允许的边界，
/// 不会削减任何游戏本身支持的功能。
library;

import 'game_limits.dart';
import 'save_codec.dart';

/// 一次修复的结果。
class GameRepairResult {
  const GameRepairResult(this.changes);

  /// 被人为收敛的字段（空表示原数据完全合法）。
  final List<String> changes;

  bool get changed => changes.isNotEmpty;

  String? get warning {
    if (changes.isEmpty) return null;
    return '以下字段超出游戏可接受范围，已自动收敛（否则进游戏会卡死）：'
        '${changes.join('、')}。';
  }
}

/// 逐字段把 [c] 钳制到游戏允许的范围，返回被修正的字段说明。
///
/// [isDefinedItem] 用于判定装备槽物品 ID 是否在游戏 `r[]` 中真实存在；
/// 省略时默认使用 [GameLimits.isDefinedItem]。
GameRepairResult repairForGame(
  List<int> c, {
  bool Function(int id)? isDefinedItem,
}) {
  final changes = <String>[];
  final itemExists = isDefinedItem ?? GameLimits.isDefinedItem;

  void clampBits(int off, int units, int min, int max, String label) {
    final v = readBits(c, off, units);
    if (v < min || v > max) {
      writeBits(c, off, units, v.clamp(min, max));
      changes.add('$label $v→${v.clamp(min, max)}');
    }
  }

  // 头部标量字段。
  clampBits(Fields.gold, 4, GameLimits.goldMin, GameLimits.goldMax,
      FieldViolation.gold.label);
  clampBits(Fields.exp, 4, GameLimits.expMin, GameLimits.expMax,
      FieldViolation.exp.label);
  clampBits(Fields.level, 2, GameLimits.levelMin, GameLimits.levelMax,
      FieldViolation.level.label);
  clampBits(Fields.stage, 2, GameLimits.stageMin, GameLimits.stageMax,
      FieldViolation.stage.label);

  final party = c[Fields.party];
  if (party < GameLimits.partyMin || party > GameLimits.partyMax) {
    c[Fields.party] = party.clamp(GameLimits.partyMin, GameLimits.partyMax);
    changes.add('${FieldViolation.party.label} $party→${c[Fields.party]}');
  }

  // 每名角色的技能点 / 属性加点。
  for (var ch = 0; ch < 4; ch++) {
    clampBits(
      Fields.skillPoints + ch * 2,
      2,
      GameLimits.skillPointMin,
      GameLimits.skillPointMax,
      '角色${ch + 1}技能点',
    );
    for (var stat = 0; stat < 7; stat++) {
      final isDodge = stat == 6;
      clampBits(
        Fields.wbStart + (ch * 7 + stat) * 2,
        2,
        isDodge ? GameLimits.dodgeMin : GameLimits.weaponStatMin,
        isDodge ? GameLimits.dodgeMax : GameLimits.weaponStatMax,
        '角色${ch + 1}${isDodge ? '闪避' : '属性${stat + 1}'}',
      );
    }
  }

  // 装备槽：物品 ID 必须指向游戏 `r[]` 中真实存在的条目，
  // 否则游戏读 `r[id][...]` 时抛异常（同样是卡死）。
  for (var ch = 0; ch < 4; ch++) {
    for (var slot = 0; slot < GameLimits.equipmentSlots; slot++) {
      final off = Fields.acStart + (ch * 8 + slot) * 2;
      final id = readBits(c, off, 2);
      if (id != 0 && !itemExists(id)) {
        writeBits(c, off, 2, 0);
        changes.add('角色${ch + 1}槽${slot + 1}物品$id→空');
      }
    }
  }

  // 已解锁技能数受 `lb<=9` 约束；`ib[]` 只有 9 格，写多于 9 个 1 不可能，
  // 但仍统一规整为非 0/1 的脏值，避免游戏计数出现 >9。
  var flagCount = 0;
  for (var i = 0; i < 9; i++) {
    final off = Fields.skillsIb + i;
    if (c[off] != 0 && c[off] != 1) {
      c[off] = c[off] > 0 ? 1 : 0;
      changes.add('技能标记${i + 1}已规整');
    }
    flagCount += c[off] == 1 ? 1 : 0;
  }
  if (flagCount > GameLimits.skillFlagCountMax) {
    // 理论上不会发生（只有 9 格），保留判断以防字段结构变动。
    for (var i = 0; i < 9; i++) {
      c[Fields.skillsIb + i] = 0;
    }
    changes.add('${FieldViolation.skillFlagCount.label} $flagCount→0');
  }

  return GameRepairResult(changes);
}
