/// 命令行数据更新：下载官网 ranger2.js，用应用内同一套解析器重新生成
/// assets/item_stats.json 与 assets/achievement_data.json。
///
/// 用法：
///   dart run tool/update_data.dart                 # 联网下载最新版
///   dart run tool/update_data.dart --js <路径>      # 用本地 JS（离线/复现）
///   dart run tool/update_data.dart --dry-run       # 只解析不写文件
///
/// 关键点：解析逻辑与 `lib/services/data_updater.dart` 完全共用，
/// 所以命令行产物与应用内「数据源」页更新结果一致，不会出现两套解析漂移。
/// 应用内解析器还额外补全了 Python 脚本遗漏的物品 114 与怪物 104-108。
library;

import 'dart:convert';
import 'dart:io';

import 'package:sr2editor/codec/game_limits.dart';
import 'package:sr2editor/services/data_updater.dart';

const _gameUrl = 'https://dan-ball.jp/en/javagame/ranger2/ranger2.js';

Future<void> main(List<String> args) async {
  String? localJs;
  var dryRun = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--js':
        if (i + 1 < args.length) localJs = args[++i];
      case '--dry-run':
        dryRun = true;
      case '--help' || '-h':
        _usage();
        return;
      default:
        stderr.writeln('未知参数：${args[i]}');
        _usage();
        exitCode = 64;
        return;
    }
  }

  String js;
  if (localJs != null) {
    final f = File(localJs);
    if (!f.existsSync()) {
      stderr.writeln('找不到文件：$localJs');
      exitCode = 66;
      return;
    }
    js = f.readAsStringSync();
    stdout.writeln('读取本地 JS：$localJs（${js.length} 字符）');
  } else {
    final url = Uri.parse('$_gameUrl?${_versionStamp()}');
    stdout.writeln('下载 $url ...');
    try {
      final client = HttpClient();
      final resp = await (await client.getUrl(url)).close();
      if (resp.statusCode != 200) {
        stderr.writeln('下载失败：HTTP ${resp.statusCode}');
        exitCode = 69;
        return;
      }
      js = await resp.transform(utf8.decoder).join();
      client.close();
      stdout.writeln('下载完成：${js.length} 字符');
    } catch (e) {
      stderr.writeln('下载出错：$e');
      exitCode = 69;
      return;
    }
  }

  final result = parseGameJs(js);
  if (result == null) {
    stderr.writeln('解析失败：未能从 JS 中提取 r[] 物品表。');
    stderr.writeln('若游戏改版重命名了变量，需要同步更新 data_updater.dart。');
    exitCode = 65;
    return;
  }

  stdout.writeln('解析结果：物品 ${result.itemCount} · 成就 '
      '${result.achievementCount} · 关卡 ${result.stageCount} · '
      '勋章 ${result.medalCount}');

  final issues = _validate(result);
  for (final line in issues) {
    stdout.writeln('  $line');
  }

  if (dryRun) {
    stdout.writeln('\n--dry-run：未写入任何文件。');
    return;
  }

  final root = _projectRoot();
  final itemsPath = File('${root.path}/assets/item_stats.json');
  final achPath = File('${root.path}/assets/achievement_data.json');
  itemsPath.writeAsStringSync(result.itemStatsJson);
  achPath.writeAsStringSync(result.achievementDataJson);
  stdout.writeln('\n已写入：');
  stdout.writeln('  ${itemsPath.path}');
  stdout.writeln('  ${achPath.path}');
  stdout.writeln('\n提示：若物品 ID 区间或关卡数与 GameLimits 不符，请按下述提示同步。');
}

String _versionStamp() {
  final d = DateTime.now();
  return '${d.year}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';
}

/// 与 GameLimits 交叉校验，提醒需要手工跟进的硬编码上限。
List<String> _validate(DataUpdateResult r) {
  final out = <String>[];
  final items = jsonDecode(r.itemStatsJson) as Map<String, dynamic>;
  final ids = items.keys.map(int.parse).toList()..sort();

  final undefined = [
    for (final id in ids)
      if (!GameLimits.isDefinedItem(id)) id,
  ];
  if (undefined.isNotEmpty) {
    out.add('⚠ 以下物品 ID 不在 GameLimits.definedItemRanges 内，'
        '写入装备槽会导致游戏卡死：$undefined');
    out.add('  → 请同步 lib/codec/game_limits.dart 的区间定义。');
  }

  final stages = (jsonDecode(r.achievementDataJson)
      as Map<String, dynamic>)['stages'] as List<dynamic>;
  final maxStage = stages
      .map((s) => (s as Map)['id'] as int)
      .fold<int>(0, (a, b) => a > b ? a : b);
  if (maxStage != GameLimits.stageMax) {
    out.add('⚠ 关卡最大 ID 为 $maxStage，而 GameLimits.stageMax 是 '
        '${GameLimits.stageMax}');
    out.add('  → 请同步 GameLimits.stageMax / stagePlayableCount。');
  }

  if (out.isEmpty) out.add('✓ 物品 ID 区间与关卡上限均与 GameLimits 一致。');
  return out;
}

Directory _projectRoot() {
  // 从脚本所在目录向上找 pubspec.yaml，兼容直接从仓库根或 tool/ 下执行。
  var dir = File(Platform.script.toFilePath()).parent;
  for (var i = 0; i < 4; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  return Directory.current;
}

void _usage() {
  stdout.writeln('''
SR2Editor 数据更新

  dart run tool/update_data.dart              联网下载最新 ranger2.js
  dart run tool/update_data.dart --js <路径>   使用本地 JS
  dart run tool/update_data.dart --dry-run    只解析，不写文件

产物：assets/item_stats.json、assets/achievement_data.json
解析器与 App 内「数据源」页更新共用 lib/services/data_updater.dart''');
}
