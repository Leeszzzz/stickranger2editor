/// 游戏端（ranger2.js）的硬性字段上限。
///
/// 游戏每帧执行 `gg()`，其中 19 条范围检查任一不过就把画布缓冲 `E` 置 null，
/// 于是下一帧 `E[a]=0` 抛异常、渲染循环停摆——表现为「游戏卡死」。
///
/// 因此编辑器写入的每个值都必须落在本文件范围内，否则导出的存档虽然能过
/// 解码校验，一旦进入游戏就会卡住。这里的常量全部照抄 `gg()` 的判断式。
/// 注意与 6-bit / 12-bit 的**存储容量**区分：容量更大，但游戏只认这些值。
library;

abstract final class GameLimits {
  /// `if(0>Wa||4<Wa)` 队伍人数。注意游戏允许 0，但编辑器语义上至少 1 人。
  static const partyMin = 1;
  static const partyMax = 4;

  /// `if(0>Xa||99<Xa)` 等级。
  static const levelMin = 0;
  static const levelMax = 99;

  /// `if(0>Ya||9999999<Ya)` 经验。存储是 24 bit（16777215），游戏只认 9999999。
  static const expMin = 0;
  static const expMax = 9999999;

  /// `if(0>Za||9999999<Za)` 金币。同上。
  static const goldMin = 0;
  static const goldMax = 9999999;

  /// `if(0>$a[a]||196<$a[a])` 技能点。存储 12 bit，游戏只认 196。
  static const skillPointMin = 0;
  static const skillPointMax = 196;

  /// `if(0>ob..ub[a]||196<..)` 六项属性加点。
  static const weaponStatMin = 0;
  static const weaponStatMax = 196;

  /// `if(0>vb[a]||25<vb[a])` 闪避。
  static const dodgeMin = 0;
  static const dodgeMax = 25;

  /// `if(0>lb||9<lb)` 已解锁技能数（`ib[]` 中值为 1 的个数）。
  /// 由存档里的 `ib[]` 推导，编辑器改的是 `ib[]`，此处仅用于校验。
  static const skillFlagCountMax = 9;

  /// 关卡 ID。`G` 只有 0..22 真正定义，23..31 是空槽。
  /// 游戏写入 `q` 后立即 `kg(q)` 读 `ka[q]`，越界会解引用不存在的地图。
  static const stageMin = 0;
  static const stageMax = 22;

  /// 编辑器 UI 展示的可编辑关卡数（存档含 32 个标记，前 23 个有效）。
  static const stageMarkerCount = 32;
  static const stagePlayableCount = 23;

  /// 每名角色的装备槽数量（存档 `ac[char][slot]`）。
  static const equipmentSlots = 8;

  /// 背包物品数量上限（6 bit）。
  static const itemCountMax = 63;

  /// 当前 HP 存储为 18 bit（262143）。游戏不做范围判死，但 `wg()` 会
  /// 用 `ab[a]=Ng(ab[a],0,bb[a])` 夹到该角色最大 HP，超出的值会被静默改写。
  static const currentHpMax = 262143;

  /// 游戏 `r[]` 中真实定义过的物品 ID 区间（含首含尾）。
  ///
  /// 游戏只有这些 ID 有数据；其余（142-144、152-159、165-255）在 `r[]` 里
  /// 是 `undefined`。装备槽写入未定义 ID 会让游戏读 `r[id][...]` 抛异常。
  /// 数值来自 ranger2.js ver34.1：`0-141, 145-151, 160-165`，共 155 项。
  ///
  /// 注意与内置 `item_stats.json` 的区别：后者由解析脚本生成，遗漏了
  /// 物品 114（Garnet Amulet）等条目，不能当作白名单使用。
  static const List<(int, int)> definedItemRanges = [
    (0, 141),
    (145, 151),
    (160, 165),
  ];

  /// 判断物品 ID 是否为游戏定义过的条目。
  static bool isDefinedItem(int id) {
    for (final (lo, hi) in definedItemRanges) {
      if (id >= lo && id <= hi) return true;
    }
    return false;
  }
}

/// 一个字段被游戏拒绝的原因，用于导入时生成告警文案。
enum FieldViolation {
  gold('金币'),
  exp('经验'),
  level('等级'),
  party('队伍人数'),
  skillPoint('技能点'),
  weaponStat('属性加点'),
  stage('当前关卡'),
  equipment('装备槽物品'),
  skillFlagCount('已解锁技能数');

  const FieldViolation(this.label);
  final String label;
}
