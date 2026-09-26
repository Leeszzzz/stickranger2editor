/// Stick Ranger 2 存档编解码核心。
///
/// 移植自仓库根目录的 `ranger2_editor.py` / Android `SaveCodec.kt`：
/// 自定义 Base64 字母表 + 滚动混淆（随机盐 a/g）+ RLE 压缩。
/// 解码展开后的 C 数组固定 768 个 6-bit 值，字段偏移为常量。
library;

import 'dart:math';

/// 游戏自定义 Base64 字母表（来自 ranger2.js 的 `sf`）。
const String saveAlphabet =
    '01WtCplxayfTvqchHmA9*JZOri6VN7L4w8dUGe.S3FIDzsnPbEkQXYMRgu25BjoK';

final Map<String, int> _charToVal = {
  for (var i = 0; i < saveAlphabet.length; i++) saveAlphabet[i]: i,
};

/// 解码展开后的数据总长度（6-bit 值个数）。
const int saveLength = 768;

/// 字段偏移（RLE 展开后 C 数组中的下标）。
abstract final class Fields {
  static const userId = 5; // 8 × 6bit
  static const stage = 14; // 2
  static const party = 28; // 1
  static const level = 29; // 2
  static const exp = 31; // 4
  static const gold = 35; // 4
  static const skillPoints = 39; // 4 × 2
  static const currentHp = 47; // 4 × 3
  static const wbStart = 59; // 4 角色 × 7 项 × 2
  static const acStart = 115; // 4 × 8 槽 × 2
  static const ccStart = 181; // 256 物品数量
  static const skillsIb = 439; // 9 技能标记
  static const jbUsedSp = 448; // 已用技能点
  static const hcStages = 451; // 32 关卡
  static const jcMonsters = 485; // 128 图鉴
  static const mbAutoMove = 615; // 4 自动移动
  static const nbCliffStop = 619; // 悬崖停止
  static const lcAchievements = 622; // 128 成就
  static const ncMedals = 752; // 10 勋章
  static const rfEvents = 764; // 4 事件标记
}

/// 6-bit 位域读写。
int readBits(List<int> c, int off, int units) {
  var v = 0;
  for (var k = 0; k < units; k++) {
    v = (v << 6) | (c[off + k] & 63);
  }
  return v;
}

void writeBits(List<int> c, int off, int units, int value) {
  for (var k = units - 1; k >= 0; k--) {
    c[off + k] = (value >> (6 * (units - 1 - k))) & 63;
  }
}

int _val(String ch, int pos) {
  final v = _charToVal[ch];
  if (v == null) {
    throw FormatException('第 $pos 位出现非法字符 "$ch"');
  }
  return v;
}

/// 解码结果：展开后的 C 数组 + 数据校验和告警。
class DecodeResult {
  DecodeResult({required this.data, this.dataChecksumWarning});

  final List<int> data;
  final String? dataChecksumWarning;
}

/// 解码存档字符串为 C 数组（尾部校验和不匹配时抛 [FormatException]）。
DecodeResult decodeSave(String saveStr) {
  final s = saveStr.trim();
  final d = s.length - 4;
  if (d <= 0) throw const FormatException('存档字符串太短');

  final b = _val(s[d], d);
  final g = _val(s[d + 1], d + 1);
  var c = (b + d) & 63;

  final decoded = List<int>.filled(d, 0);
  for (var i = 0; i < d; i++) {
    final orig = (_val(s[i], i) - c) & 63;
    decoded[i] = orig;
    c = ((c * c) >> 4) + orig + i + g;
    c &= 0xFFFF;
  }

  final expHi = (c >> 6) & 63;
  final expLo = c & 63;
  if (expHi != _val(s[d + 2], d + 2) || expLo != _val(s[d + 3], d + 3)) {
    throw const FormatException('尾部校验和不匹配，存档可能不完整或被截断');
  }

  // RLE 展开：值 0/1 后跟重复计数。
  final out = <int>[];
  var i = 0;
  while (i < decoded.length) {
    final v = decoded[i++];
    out.add(v);
    if (v <= 1) {
      if (i >= decoded.length) {
        throw const FormatException('RLE 数据意外截断');
      }
      final count = decoded[i++];
      out.addAll(List<int>.filled(count, v));
    }
  }

  // 数据校验和（C[1..2]）只作告警：编码时会重算。
  String? warning;
  if (out.length >= 3) {
    final sum = out.skip(3).fold<int>(0, (a, v) => a + v);
    if (out[1] != ((sum >> 6) & 63) || out[2] != (sum & 63)) {
      warning = '数据校验和不匹配（导入后已自动重算）';
    }
  }
  return DecodeResult(data: out, dataChecksumWarning: warning);
}

/// 将 C 数组重新编码为存档字符串（随机盐，同一状态每次密文不同）。
String encodeSave(List<int> src, [Random? rng]) {
  final random = rng ?? Random.secure();
  final c = List<int>.of(src);
  if (c.length < 3) throw const FormatException('数据长度不足');

  final dataSum = c.skip(3).fold<int>(0, (a, v) => a + v);
  c[0] = 1;
  c[1] = (dataSum >> 6) & 63;
  c[2] = dataSum & 63;

  // RLE 压缩。
  final of = <int>[];
  var i = 0;
  while (i < c.length) {
    final v = c[i++];
    of.add(v);
    if (v <= 1) {
      var count = 0;
      while (i < c.length && count < 63 && c[i] == v) {
        count++;
        i++;
      }
      of.add(count);
    }
  }

  final a = random.nextInt(64);
  final g = random.nextInt(64);
  final d = of.length;
  var cc = (a + d) & 63;

  final buf = StringBuffer();
  for (var k = 0; k < d; k++) {
    buf.write(saveAlphabet[(of[k] + cc) & 63]);
    cc = (((cc * cc) >> 4) + of[k] + k + g) & 0xFFFF;
  }
  buf
    ..write(saveAlphabet[a])
    ..write(saveAlphabet[g])
    ..write(saveAlphabet[(cc >> 6) & 63])
    ..write(saveAlphabet[cc & 63]);
  return buf.toString();
}
