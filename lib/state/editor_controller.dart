/// 编辑器全局状态：持有解码后的 C 数组，暴露全部字段的读写与批量操作。
library;

import 'package:flutter/foundation.dart';

import '../codec/save_codec.dart';
import '../models/game_data.dart';

class EditorController extends ChangeNotifier {
  EditorController({required GameCatalog catalog}) : _catalog = catalog;

  GameCatalog _catalog;
  List<int>? _c;
  String? _sourceString;
  String? _decodeWarning;

  GameCatalog get catalog => _catalog;
  bool get hasSave => _c != null;
  String? get sourceString => _sourceString;
  String? get decodeWarning => _decodeWarning;
  List<int>? get rawData => _c == null ? null : List.unmodifiable(_c!);

  void replaceCatalog(GameCatalog catalog) {
    _catalog = catalog;
    notifyListeners();
  }

  /// 解析并存入存档字符串；失败返回错误消息。
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
    _c = r.data;
    _sourceString = saveStr.trim();
    _decodeWarning = r.dataChecksumWarning;
    notifyListeners();
    return null;
  }

  void unload() {
    _c = null;
    _sourceString = null;
    _decodeWarning = null;
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

  static const maxGold = 16777215;
  static const maxExp = 16777215;

  void setGold(int v) => _edit((c) => writeBits(c, Fields.gold, 4, v.clamp(0, maxGold)));
  void setExp(int v) => _edit((c) => writeBits(c, Fields.exp, 4, v.clamp(0, maxExp)));
  void setLevel(int v) => _edit((c) => writeBits(c, Fields.level, 2, v.clamp(0, 4095)));
  void setStage(int v) => _edit((c) => writeBits(c, Fields.stage, 2, v.clamp(0, 4095)));
  void setPartyCount(int v) =>
      _edit((c) => c[Fields.party] = v.clamp(1, 4));

  // ==================== 角色 ====================

  int skillPoint(int ch) => readBits(_c!, Fields.skillPoints + ch * 2, 2);
  int currentHp(int ch) => readBits(_c!, Fields.currentHp + ch * 3, 3);

  /// 属性加点值 wb[char][stat]（stat: 0近战 1中程 2远程 3物理 4元素 5未用 6闪避）。
  int weaponStat(int ch, int stat) =>
      readBits(_c!, Fields.wbStart + (ch * 7 + stat) * 2, 2);

  /// 装备槽 ac[char][slot]。
  int equipment(int ch, int slot) =>
      readBits(_c!, Fields.acStart + (ch * 8 + slot) * 2, 2);

  void setSkillPoint(int ch, int v) =>
      _edit((c) => writeBits(c, Fields.skillPoints + ch * 2, 2, v.clamp(0, 4095)));
  void setCurrentHp(int ch, int v) =>
      _edit((c) => writeBits(c, Fields.currentHp + ch * 3, 3, v.clamp(0, 262143)));
  void setWeaponStat(int ch, int stat, int v) =>
      _edit((c) => writeBits(c, Fields.wbStart + (ch * 7 + stat) * 2, 2, v.clamp(0, 4095)));
  void setEquipment(int ch, int slot, int itemId) =>
      _edit((c) => writeBits(c, Fields.acStart + (ch * 8 + slot) * 2, 2, itemId.clamp(0, 4095)));

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
