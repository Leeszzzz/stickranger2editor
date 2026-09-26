/// 从官网 ranger2.js 解析物品/成就/关卡/勋章数据。
///
/// 移植自 Android `DataUpdater.kt`（源自 scripts/update_data.py）。
library;

import 'dart:convert';

/// ranger2.js 变量名 → r[] 字段索引映射（游戏压缩 JS 中稳定）。
const Map<String, int> _varMap = {
  'Nc': 0, 'Oc': 1, 'Pc': 2, 'Qc': 3, 'Rc': 4, 'Sc': 5,
  'Tc': 6, 'Uc': 7, 'Vc': 8, 'Wc': 9, 'Xc': 10,
  'Yc': 11, 'Zc': 12, r'$c': 13,
  'ad': 14, 'bd': 15, 'cd': 16,
  'dd': 17, 'ed': 18, 'fd': 19, 'gd': 20, 'hd': 21,
  'id': 22, 'jd': 23, 'kd': 24, 'ld': 25, 'md': 26,
  'nd': 27, 'od': 28, 'pd': 29, 'qd': 30, 'rd': 31,
  'sd': 32, 'td': 33, 'ud': 34, 'vd': 35,
  'wd': 36, 'xd': 37, 'yd': 38, 'zd': 39, 'Ad': 40, 'Bd': 41,
  'Cd': 48, 'Dd': 49, 'Ed': 50, 'Fd': 51, 'Gd': 52, 'Hd': 53, 'Id': 54,
  'Kd': 55, 'Ld': 56, 'Md': 57, 'Nd': 58, 'Od': 59, 'Pd': 60, 'Qd': 61,
  'Rd': 62, 'Sd': 63, 'Td': 64, 'Ud': 65, 'Xd': 66, 'Yd': 67, 'Zd': 68,
  r'$d': 69, 'ae': 70, 'be': 71,
  'ce': 7, 'de': 8, 'ee': 9, 'fe': 10, 'ge': 11,
  'he': 7, 'ie': 8, 'je': 9, 'ke': 10, 'le': 11, 'me': 12, 'ne': 13,
  'oe': 1, 'pe': 2, 'qe': 3, 're': 4, 'se': 5, 'te': 6,
  'ue': 7, 've': 8, 'we': 9, 'xe': 10,
  'ye': 16, 'ze': 17, 'Ae': 18, 'Be': 19, 'Ce': 20, 'De': 21,
  'Ee': 22, 'Fe': 23, 'Ge': 24, 'He': 25, 'Je': 26, 'Ke': 27,
  'Le': 28, 'Me': 29, 'Ne': 30, 'Oe': 31, 'Pe': 32, 'Qe': 33,
  'Re': 34, 'Se': 35, 'Te': 36, 'Ue': 37, 'Ve': 38, 'We': 39,
};

const damageNames = {
  0: 'Physical',
  1: 'Fire',
  2: 'Ice',
  3: 'Lightning',
  4: 'Poison',
};

/// 提取从 [start] 开始的平衡方括号段（跳过字符串字面量）。
(String?, int) _extractBracket(String content, int start) {
  if (start >= content.length || content[start] != '[') return (null, start);
  var depth = 0;
  var inString = false;
  var stringChar = ' ';
  var i = start;
  while (i < content.length) {
    final ch = content[i];
    if (inString) {
      if (ch == r'\') {
        i += 2;
        continue;
      }
      if (ch == stringChar) inString = false;
    } else if (ch == '"' || ch == "'") {
      inString = true;
      stringChar = ch;
    } else if (ch == '[') {
      depth++;
    } else if (ch == ']') {
      depth--;
      if (depth == 0) return (content.substring(start, i + 1), i + 1);
    }
    i++;
  }
  return (null, start);
}

List<String>? _tokenizeArray(String arrStr) {
  final s = arrStr.trim();
  if (!s.startsWith('[') || !s.endsWith(']')) return null;
  final inner = s.substring(1, s.length - 1).trim();
  final tokens = <String>[];
  var depth = 0;
  var inString = false;
  var stringChar = ' ';
  final current = StringBuffer();
  for (var i = 0; i < inner.length; i++) {
    final ch = inner[i];
    if (inString) {
      if (ch != r'\') {
        if (ch == stringChar) inString = false;
      }
      current.write(ch);
    } else if (ch == '"' || ch == "'") {
      inString = true;
      stringChar = ch;
      current.write(ch);
    } else if (ch == '[') {
      depth++;
      current.write(ch);
    } else if (ch == ']') {
      depth--;
      current.write(ch);
    } else if (ch == ',' && depth == 0) {
      tokens.add(current.toString().trim());
      current.clear();
    } else {
      current.write(ch);
    }
  }
  if (current.toString().trim().isNotEmpty) {
    tokens.add(current.toString().trim());
  }
  return tokens;
}

String _resolveToken(String token) {
  final t = token.trim();
  if (t.length >= 2 && t.codeUnitAt(0) == t.codeUnitAt(t.length - 1)) {
    final q = t[0];
    if (q == '"' || q == "'") return t;
  }
  final num = double.tryParse(t);
  if (num != null) {
    if (num == num.truncateToDouble() && !t.toLowerCase().contains('e')) {
      return num.toInt().toString();
    }
    return num.toString();
  }
  final mapped = _varMap[t] ?? _varMap[t.replaceFirst(r'$', '')];
  if (mapped != null) return mapped.toString();
  return 'null';
}

List<dynamic>? _parseItemArray(String arrStr) {
  final tokens = _tokenizeArray(arrStr);
  if (tokens == null) return null;
  final jsonStr = '[${tokens.map(_resolveToken).join(',')}]';
  try {
    return jsonDecode(jsonStr) as List<dynamic>;
  } catch (_) {
    return null;
  }
}

List<dynamic> _parseSimpleJson(String jsonStr) {
  final s = jsonStr.trim();
  if (!s.startsWith('[') || !s.endsWith(']')) {
    throw const FormatException('not an array');
  }
  final inner = s.substring(1, s.length - 1).trim();
  final result = <dynamic>[];
  var i = 0;
  while (i < inner.length) {
    final ch = inner[i];
    if (ch == '"' || ch == "'") {
      var j = i + 1;
      while (j < inner.length && inner[j] != ch) {
        j++;
      }
      result.add(inner.substring(i + 1, j));
      i = j + 1;
    } else if ((ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39) ||
        ch == '-' ||
        ch == '+') {
      var j = i;
      while (j < inner.length &&
          (inner[j].contains(RegExp(r'[0-9.\-+eE]')))) {
        j++;
      }
      final num = double.tryParse(inner.substring(i, j)) ?? 0.0;
      result.add(num == num.truncateToDouble() ? num.toInt() : num);
      i = j;
    } else if (inner.startsWith('true', i)) {
      result.add(true);
      i += 4;
    } else if (inner.startsWith('false', i)) {
      result.add(false);
      i += 5;
    } else if (inner.startsWith('null', i)) {
      result.add(null);
      i += 4;
    } else {
      i++;
    }
    while (i < inner.length && (inner[i] == ',' || inner[i] == ' ')) {
      i++;
    }
  }
  return result;
}

Map<int, List<dynamic>> _extractRArray(String js) {
  final start = js.indexOf('var r=Array(256);');
  if (start < 0) return {};
  final section = js.substring(start);
  final items = <int, List<dynamic>>{};
  final regex = RegExp(r'r\[(\d+)]\s*=');
  for (final match in regex.allMatches(section)) {
    final idx = int.parse(match.group(1)!);
    final bracketStart = match.end;
    if (bracketStart < section.length && section[bracketStart] == '[') {
      final (arrStr, _) = _extractBracket(section, bracketStart);
      if (arrStr != null) {
        final parsed = _parseItemArray(arrStr);
        if (parsed != null) items[idx] = parsed;
      }
    }
  }
  return items;
}

List<List<dynamic>> _extractVArray(String js) {
  final start = js.indexOf('v[0]=');
  if (start < 0) return [];
  final section = js.substring(start);
  final found = <int, List<dynamic>>{};
  final regex = RegExp(r'v\[(\d+)]\s*=');
  for (final match in regex.allMatches(section)) {
    final idx = int.parse(match.group(1)!);
    var pos = match.end;
    while (pos < section.length && section[pos] != '[') {
      pos++;
    }
    if (pos < section.length) {
      final (arrStr, _) = _extractBracket(section, pos);
      if (arrStr != null) {
        try {
          found[idx] = _parseSimpleJson(arrStr);
        } catch (_) {}
      }
    }
  }
  final keys = found.keys.toList()..sort();
  return [for (final k in keys) found[k]!];
}

List<(int, String, int)> _extractGArray(String js) {
  final start = js.indexOf('G[0]=');
  if (start < 0) return [];
  final section = js.substring(start);
  final stages = <(int, String, int)>[];
  final regex = RegExp(r'G\[(\d+)]\s*=');
  for (final match in regex.allMatches(section)) {
    final idx = int.parse(match.group(1)!);
    final bracketStart = match.end;
    if (bracketStart < section.length && section[bracketStart] == '[') {
      final (arrStr, _) = _extractBracket(section, bracketStart);
      if (arrStr != null) {
        try {
          final parsed = _parseSimpleJson(arrStr);
          final name = parsed.isNotEmpty ? '${parsed[0]}' : '';
          final area = parsed.length > 1 && parsed[1] is num
              ? (parsed[1] as num).toInt()
              : 0;
          stages.add((idx, name, area));
        } catch (_) {}
      }
    }
  }
  return stages;
}

(List<int>, List<List<dynamic>>) _extractMedalData(String js) {
  final hfMatch = RegExp(r'var hf=\[([^\]]*)]').firstMatch(js);
  final hf = <int>[];
  if (hfMatch != null) {
    try {
      hf.addAll(
        (_parseSimpleJson('[${hfMatch.group(1)}]'))
            .map((v) => v is num ? v.toInt() : 0),
      );
    } catch (_) {}
  }

  final medals = <List<dynamic>>[];
  final jfStart = js.indexOf('var jf=[');
  if (jfStart >= 0) {
    final (arrStr, _) = _extractBracket(js, jfStart + 7);
    if (arrStr != null) {
      try {
        medals.addAll(
          _parseSimpleJson(arrStr).whereType<List<dynamic>>(),
        );
      } catch (_) {}
    }
  }
  return (hf, medals);
}

class DataUpdateResult {
  DataUpdateResult({
    required this.itemStatsJson,
    required this.achievementDataJson,
    required this.itemCount,
    required this.achievementCount,
    required this.stageCount,
    required this.medalCount,
  });

  final String itemStatsJson;
  final String achievementDataJson;
  final int itemCount;
  final int achievementCount;
  final int stageCount;
  final int medalCount;
}

/// 纯解析：从 ranger2.js 内容生成两个数据 JSON。
/// 网络下载由调用方完成（便于注入/测试）。
DataUpdateResult? parseGameJs(String js) {
  final items = _extractRArray(js);
  if (items.isEmpty) return null;

  final parsedItems = <String, Map<String, dynamic>>{};
  for (final entry in items.entries) {
    final arr = entry.value;
    if (arr.isEmpty || arr.first is! String) continue;
    final name = arr.first as String;
    if (const ['NONE', 'NG', 'gold', 'onigiri'].contains(name)) continue;
    int at(int i) => arr.length > i && arr[i] is num ? (arr[i] as num).toInt() : 0;
    final dmgId = at(36);
    parsedItems[entry.key.toString()] = {
      'name': name,
      'type_category': at(1),
      'icon': at(2),
      'item_class': at(3),
      'range_type': at(4),
      'color': at(5),
      'at_min': at(11),
      'at_max': at(12),
      'bullets': at(13),
      'agi': at(15),
      'range': at(16),
      'hp': at(21),
      'sp': at(24),
      'damage_type': damageNames[dmgId] ?? 'Physical',
      'damage_type_id': dmgId,
      'lv_cap': at(39),
      'cost': at(40),
    };
  }

  final achievements = _extractVArray(js);
  final achList = <Map<String, dynamic>>[];
  for (var i = 0; i < achievements.length; i++) {
    final arr = achievements[i];
    if (arr.length < 5) continue;
    achList.add({
      'id': i,
      'name': '${arr[0]}',
      'subtitle': '${arr[1]}',
      'stage_id': arr[2] is num ? (arr[2] as num).toInt() : 0,
      'icon_id': arr[3] is num ? (arr[3] as num).toInt() : 0,
      'target_value': arr[4] is num ? (arr[4] as num).toInt() : 1,
    });
  }

  final stageList = [
    for (final (sid, name, area) in _extractGArray(js))
      {'id': sid, 'name': name, 'area': area},
  ];

  final (hf, medalsRaw) = _extractMedalData(js);
  final medals = [
    for (final m in medalsRaw)
      {
        'name': m.isNotEmpty ? '${m.first}' : '',
        'value': m.length > 1 && m[1] is num ? (m[1] as num).toInt() : 0,
      },
  ];

  final stageMedalItems = <String, Map<String, dynamic>>{};
  for (var stageId = 0; stageId < hf.length; stageId++) {
    final itemId = hf[stageId];
    if (itemId > 0) {
      stageMedalItems[stageId.toString()] = {
        'item_id': itemId,
        'name': parsedItems['$itemId']?['name'] ?? '',
      };
    }
  }

  final itemStatsJson =
      const JsonEncoder.withIndent('  ').convert(parsedItems);
  final achievementDataJson = const JsonEncoder.withIndent('  ').convert({
    'stages': stageList,
    'achievements': achList,
    'medals': medals,
    'stage_medal_items': stageMedalItems,
    'achievement_groups': [
      for (var g = 0; g < 18; g++)
        [
          for (var i = g * 5; i < (g + 1) * 5 && i < achList.length; i++) i,
        ],
    ],
  });

  return DataUpdateResult(
    itemStatsJson: itemStatsJson,
    achievementDataJson: achievementDataJson,
    itemCount: parsedItems.length,
    achievementCount: achList.length,
    stageCount: stageList.length,
    medalCount: medals.length,
  );
}
