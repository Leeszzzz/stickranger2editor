import 'package:flutter_test/flutter_test.dart';
import 'package:sr2editor/services/data_updater.dart';

/// 精简版游戏 JS 片段：只保留解析器依赖的数组结构。
/// 数值刻意用真实游戏里的形态（r[] 是长数字数组、jf 是嵌套数组）。
const _miniJs = '''
var e,aa,m=window;var Nc=0,Oc=1,Pc=2,Qc=3,Sc=5,Yc=11,Zc=12,Bd=41;
var r=Array(256);
r[0]=["NONE",0,0,0,0,0];
r[4]=["Glove",3,1,5,0,16777215,0,0,0,0,0,3,5,1,0,20,24,0,0,0,0,16,0,0,8,0,0,0,0,0,0,0,0,0,0,1,0,0,0,5,30];
r[9]=["Sword",3,6,5,0,16777215,0,0,0,0,0,3,4,1,0,20,24,0,0,0,0,16,0,0,8,0,0,0,0,0,0,0,0,0,0,1,0,0,0,5,30];
var w=Array(128);
w[0]=["Stage clear","",2,0,1,0];
w[1]=["Combo 100","",2,0,1,0];
var H=Array(128);var jc=Array(128);
H[0]=[1,0,7,0,0,1,3394611,3355443,0,30];
H[1]=[1,0,9,0,0,1,11141120,3355443,0,30];
var G=Array(32);
G[0]=["",0,13407305];
G[1]=["Village",0,14526];
G[2]=["Cave 1",0,14526];
var hf=[0,0,72,74];
var jf=[["Gold Shower",15],["Clear Status",30],["ONIGIRI",45]];
''';

void main() {
  group('parseGameJs', () {
    test('能解析出物品 / 成就 / 关卡 / 勋章', () {
      final r = parseGameJs(_miniJs);
      expect(r, isNotNull);
      expect(r!.itemCount, 2); // 跳过 NONE
      expect(r.achievementCount, 2);
      expect(r.stageCount, 3);
      expect(r.medalCount, 3);
    });

    test('勋章是嵌套数组，不能被拍平', () {
      final r = parseGameJs(_miniJs)!;
      // 回归：曾因 _parseSimpleJson 不处理嵌套数组，导致勋章解析为 0 个。
      expect(r.medalCount, 3);
      expect(r.achievementDataJson, contains('"Gold Shower"'));
      expect(r.achievementDataJson, contains('"ONIGIRI"'));
      expect(r.achievementDataJson, contains('"value": 45'));
    });

    test('物品字段按固定下标抽取', () {
      final r = parseGameJs(_miniJs)!;
      expect(r.itemStatsJson, contains('"name": "Glove"'));
      expect(r.itemStatsJson, contains('"icon": 1'));
      expect(r.itemStatsJson, contains('"lv_cap": 5'));
      expect(r.itemStatsJson, contains('"cost": 30'));
    });

    test('怪物脸谱与颜色成对提取', () {
      final r = parseGameJs(_miniJs)!;
      expect(r.achievementDataJson, contains('"monster_faces"'));
      expect(r.achievementDataJson, contains('"monster_colors"'));
    });

    test('关卡名称与区域正确', () {
      final r = parseGameJs(_miniJs)!;
      expect(r.achievementDataJson, contains('"name": "Village"'));
      expect(r.achievementDataJson, contains('"name": "Cave 1"'));
    });

    test('无 r[] 物品表时返回 null', () {
      expect(parseGameJs('var x = 1;'), isNull);
    });
  });
}
