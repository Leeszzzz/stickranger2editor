/// 编辑器全局状态：持有解码后的 C 数组，暴露全部字段的读写与批量操作。
library;

import 'package:flutter/foundation.dart';

import '../codec/game_guard.dart';
import '../codec/game_limits.dart';
import '../codec/save_codec.dart';
import '../models/game_data.dart';

class EditorController extends ChangeNotifier {
  EditorController({required GameCatalog catalog}) : _catalog = catalog;

  GameCatalog _catalog;
  List<int>? _c;
  String? _sourceString;
  String? _decodeWarning;
  List<String> _repairLog = const [];

  GameCatalog get catalog => _catalog;
  bool get hasSave => _c != null;
  String? get sourceString => _sourceString;
  String? get decodeWarning => _decodeWarning;

  /// 载入时被收敛到游戏允许范围的字段说明（空表示原数据合法）。
  List<String> get repairLog => _repairLog;
  List<int>? get rawData => _c == null ? null : List.unmodifiable(_c!);

  void replaceCatalog(GameCatalog catalog) {
    _catalog = catalog;
    notifyListeners();
  }

  /// 解析并存入存档字符串；失败返回错误消息。
  ///
  /// 解码成功后会做一次 [repairForGame]：把任何超出游戏硬范围的字段收敛到
  /// 边界内（否则导出的存档进游戏会被 `gg()` 判为非法而卡死）。
  String? loadFromString(String saveStr) {
    final DecodeResult r;
    try {
      r = decodeSave(saveStr);
    } on FormatException catch (e) {
      return e.message;
    } catch (e) {
      return '解码失败：$e';
    }
    if (r.data.length < saveLength) {
      return '数据长度异常（${r.data.length}，应为 $saveLength）';
    }
    final repair = repairForGame(r.data);
    _c = r.data;
    _sourceString = saveStr.trim();
    _decodeWarning = r.dataChecksumWarning;
    _repairLog = repair.changes;
    notifyListeners();
    return null;
  }

  /// 游戏 `r[]` 中真实存在的物品 ID。装备槽写入未定义的 ID 会让游戏
  /// 读 `r[id][...]` 时抛异常，所以写入前以它为准。
  bool _isWritableItem(int id) => GameLimits.isDefinedItem(id);

  void unload() {
    _c = null;
    _sourceString = null;
    _decodeWarning = null;
    _repairLog = const [];
    notifyListeners();
  }

  /// 编码当前状态为存档字符串（随机盐）。未载入存档时返回 null。
  String? encode() {
    final c = _c;
    if (c == null) return null;
    return encodeSave(c);
  }

  void _edit(void Function(List<int> c) fn) {
    final c = _c;
    if (c == null) return;
    fn(c);
    notifyListeners();
  }

  // ==================== 总览 ====================

  String get userId {
    final c = _c;
    if (c == null) return '';
    return [
      for (var i = 0; i < 8; i++) saveAlphabet[c[Fields.userId + i] & 63],
    ].join();
  }

  int get level => _c == null ? 0 : readBits(_c!, Fields.level, 2);
  int get exp => _c == null ? 0 : readBits(_c!, Fields.exp, 4);
  int get gold => _c == null ? 0 : readBits(_c!, Fields.gold, 4);
  int get stage => _c == null ? 0 : readBits(_c!, Fields.stage, 2);
  int get partyCount => _c?[Fields.party] ?? 0;

  static const maxGold = GameLimits.goldMax;
  static const maxExp = GameLimits.expMax;

  void setGold(int v) => _edit(
      (c) => writeBits(c, Fields.gold, 4, v.clamp(GameLimits.goldMin, GameLimits.goldMax)));
  void setExp(int v) => _edit(
      (c) => writeBits(c, Fields.exp, 4, v.clamp(GameLimits.expMin, GameLimits.expMax)));
  void setLevel(int v) => _edit(
      (c) => writeBits(c, Fields.level, 2, v.clamp(GameLimits.levelMin, GameLimits.levelMax)));
  void setStage(int v) => _edit(
      (c) => writeBits(c, Fields.stage, 2, v.clamp(GameLimits.stageMin, GameLimits.stageMax)));
  void setPartyCount(int v) => _edit(
      (c) => c[Fields.party] = v.clamp(GameLimits.partyMin, GameLimits.partyMax));

  // ==================== 角色 ====================

  int skillPoint(int ch) => readBits(_c!, Fields.skillPoints + ch * 2, 2);
  int currentHp(int ch) => readBits(_c!, Fields.currentHp + ch * 3, 3);

  /// 属性加点值 wb[char][stat]（stat: 0近战 1中程 2远程 3物理 4元素 5未用 6闪避）。
  int weaponStat(int ch, int stat) =>
      readBits(_c!, Fields.wbStart + (ch * 7 + stat) * 2, 2);

  /// 装备槽 ac[char][slot]。
  int equipment(int ch, int slot) =>
      readBits(_c!, Fields.acStart + (ch * 8 + slot) * 2, 2);

  void setSkillPoint(int ch, int v) => _edit((c) => writeBits(
      c,
      Fields.skillPoints + ch * 2,
      2,
      v.clamp(GameLimits.skillPointMin, GameLimits.skillPointMax)));
  void setCurrentHp(int ch, int v) => _edit((c) => writeBits(
      c,
      Fields.currentHp + ch * 3,
      3,
      v.clamp(0, GameLimits.currentHpMax)));
  void setWeaponStat(int ch, int stat, int v) => _edit((c) {
        final isDodge = stat == 6;
        writeBits(
          c,
          Fields.wbStart + (ch * 7 + stat) * 2,
          2,
          v.clamp(
            isDodge ? GameLimits.dodgeMin : GameLimits.weaponStatMin,
            isDodge ? GameLimits.dodgeMax : GameLimits.weaponStatMax,
          ),
        );
      });
  void setEquipment(int ch, int slot, int itemId) => _edit((c) {
        // 只允许写入游戏 r[] 中真实存在的物品，否则游戏读表会抛异常卡死。
        final safe = itemId == 0 || _isWritableItem(itemId) ? itemId : 0;
        writeBits(c, Fields.acStart + (ch * 8 + slot) * 2, 2, safe.clamp(0, 4095));
      });

  // ==================== 背包 ====================

  int itemCount(int id) => _c![Fields.ccStart + id];
  int get itemsTotal {
    final c = _c;
    if (c == null) return 0;
    var n = 0;
    for (var i = 0; i < 256; i++) {
      if (c[Fields.ccStart + i] > 0) n++;
    }
    return n;
  }

  void setItemCount(int id, int count) =>
      _edit((c) => c[Fields.ccStart + id] = count.clamp(0, 63));

  void fillInventory(Set<int> ids, {int count = 63}) =>
      _edit((c) {
        for (final id in ids) {
          c[Fields.ccStart + id] = count.clamp(0, 63);
        }
      });

  void clearInventory([Set<int>? ids]) => _edit((c) {
        for (var i = 0; i < 256; i++) {
          if (ids == null || ids.contains(i)) c[Fields.ccStart + i] = 0;
        }
      });

  // ==================== 进度 ====================

  bool stageUnlocked(int id) => _c![Fields.hcStages + id] > 0;

  void setStageUnlocked(int id, bool unlocked) =>
      _edit((c) => c[Fields.hcStages + id] = unlocked ? 1 : 0);

  int achievementValue(int id) => _c![Fields.lcAchievements + id];

  bool achievementCompleted(int id) =>
      achievementValue(id) >= _catalog.achievementDef(id).targetValue;

  void setAchievementCompleted(int id, bool completed) => _edit((c) {
        c[Fields.lcAchievements + id] =
            completed ? _catalog.achievementDef(id).targetValue : 0;
      });

  bool medalUnlocked(int id) => _c![Fields.ncMedals + id] > 0;

  void setMedalUnlocked(int id, bool unlocked) =>
      _edit((c) => c[Fields.ncMedals + id] = unlocked ? 1 : 0);

  bool skillFlag(int i) => _c![Fields.skillsIb + i] > 0;

  void setSkillFlag(int i, bool unlocked) =>
      _edit((c) => c[Fields.skillsIb + i] = unlocked ? 1 : 0);

  int get usedSp => _c?[Fields.jbUsedSp] ?? 0;

  void setUsedSp(int v) => _edit((c) => c[Fields.jbUsedSp] = v.clamp(0, 63));

  /// 怪物图鉴三态：0 未遇 / 1 已遇 / 2 已查看。
  int monsterState(int id) => _c![Fields.jcMonsters + id];

  void setMonsterState(int id, int state) =>
      _edit((c) => c[Fields.jcMonsters + id] = state.clamp(0, 2));

  bool autoMove(int ch) => _c![Fields.mbAutoMove + ch] > 0;

  void setAutoMove(int ch, bool v) =>
      _edit((c) => c[Fields.mbAutoMove + ch] = v ? 1 : 0);

  bool get cliffStop => _c?[Fields.nbCliffStop] == 1;

  void setCliffStop(bool v) =>
      _edit((c) => c[Fields.nbCliffStop] = v ? 1 : 0);

  bool eventFlag(int i) => _c![Fields.rfEvents + i] > 0;

  void setEventFlag(int i, bool v) =>
      _edit((c) => c[Fields.rfEvents + i] = v ? 1 : 0);

  // ==================== 批量操作 ====================

  void unlockAllStages() =>
      _edit((c) { for (var i = 0; i < 32; i++) { c[Fields.hcStages + i] = 1; } });

  void completeAllAchievements() => _edit((c) {
        for (var i = 0; i < 128; i++) {
          c[Fields.lcAchievements + i] = _catalog.achievementDef(i).targetValue;
        }
      });

  void resetAllAchievements() => _edit((c) {
        for (var i = 0; i < 128; i++) {
          c[Fields.lcAchievements + i] = 0;
        }
      });

  void unlockAllMedals() =>
      _edit((c) { for (var i = 0; i < 10; i++) { c[Fields.ncMedals + i] = 1; } });

  void unlockAllSkillFlags() =>
      _edit((c) { for (var i = 0; i < 9; i++) { c[Fields.skillsIb + i] = 1; } });

  void viewAllMonsters() =>
      _edit((c) { for (var i = 0; i < 128; i++) { c[Fields.jcMonsters + i] = 2; } });
}
