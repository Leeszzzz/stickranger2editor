import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/open_external.dart';


import '../../main.dart';
import '../../models/game_data.dart';
import '../../services/data_updater.dart';
import '../widgets/common.dart';

const _gameJsUrl = 'https://dan-ball.jp/en/javagame/ranger2/ranger2.js';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  bool _updating = false;

  Future<void> _updateFromOfficial() async {
    final deps = AppDeps.of(context);
    final controller = deps.controller;
    setState(() => _updating = true);
    try {
      // 缓存穿透：当日版本号。
      final now = DateTime.now();
      final version =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final resp = await http
          .get(
            Uri.parse('$_gameJsUrl?$version'),
            headers: {'User-Agent': 'Mozilla/5.0'},
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw 'HTTP ${resp.statusCode}';
      }
      final result = parseGameJs(resp.body);
      if (result == null) {
        throw '未能从 ranger2.js 中解析出物品数据（游戏版本可能已变化）';
      }
      final catalog = GameCatalog.tryParse(
        itemStatsJson: result.itemStatsJson,
        achievementDataJson: result.achievementDataJson,
        sourceLabel: '官网更新',
      );
      if (catalog == null) throw '解析结果无法构建目录';

      await deps.repository.saveOverride(
        result.itemStatsJson,
        result.achievementDataJson,
      );
      controller.replaceCatalog(catalog);
      if (mounted) {
        showAppSnackBar(
          context,
          '更新完成：物品 ${result.itemCount} · 成就 ${result.achievementCount} · '
              '关卡 ${result.stageCount} · 勋章 ${result.medalCount}',
        );
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, '更新失败：${_friendlyError(e)}', error: true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  String _friendlyError(Object e) {
    final s = '$e';
    if (s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('Network is unreachable')) {
      return '网络不可用，请检查设备网络后重试';
    }
    if (s.contains('TimeoutException')) return '连接超时，请稍后重试';
    return s;
  }

  Future<void> _launchBilibili(BuildContext context) async {
    final ok = await openExternal('https://space.bilibili.com/622550948');
    if (!ok && context.mounted) {
      showAppSnackBar(context, '无法打开浏览器链接，请检查弹窗拦截设置', error: true);
    }
  }

  Future<void> _restoreBuiltin() async {
    final deps = AppDeps.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复内置数据？'),
        content: const Text('将丢弃官网更新的本地覆盖，重新使用随应用打包的数据文件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final catalog = await GameCatalog.loadFromAssets();
    await deps.repository.clearOverride();
    deps.controller.replaceCatalog(catalog);
    if (mounted) showAppSnackBar(context, '已恢复内置数据');
  }

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    final deps = AppDeps.of(context);
    final catalog = controller.catalog;
    final theme = Theme.of(context);
    final isOverride = catalog.sourceLabel == '官网更新';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            SectionCard(
              title: '数据概览',
              icon: Icons.dataset_rounded,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoBadge('物品 ${catalog.itemCount} 种'),
                  InfoBadge('成就 ${catalog.achievementCount} 项'),
                  InfoBadge('关卡 ${catalog.stages.length - 1} 个'),
                  InfoBadge('勋章 ${catalog.medals.length} 枚'),
                  InfoBadge(
                    '来源：${catalog.sourceLabel}',
                    color: theme.colorScheme.primary,
                  ),
                  if (isOverride && deps.repository.updatedAtLabel != null)
                    InfoBadge('更新于 ${deps.repository.updatedAtLabel}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '从官网更新',
              icon: Icons.cloud_download_rounded,
              subtitle: '下载 dan-ball.jp 的 ranger2.js 并重新解析物品 / 成就 / 关卡数据，'
                  '结果保存在本地（无需重新解析存档）',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _updating ? null : _updateFromOfficial,
                    icon: _updating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download_rounded, size: 18),
                    label: Text(_updating ? '正在更新…' : '立即更新'),
                  ),
                  OutlinedButton.icon(
                    onPressed: (isOverride && !_updating) ? _restoreBuiltin : null,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('恢复内置数据'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '关于',
              icon: Icons.info_outline_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SR2Editor',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '面向 Dan-Ball Stick Ranger 2（ver32.3）的本地存档编辑工具，'
                    '存档格式逆向自 ranger2.js。本应用完全离线工作（除数据更新外），'
                    '不会上传任何数据。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⚠ 修改存档前请务必备份原始字符串。',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.tertiary),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        '作者：',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Leesz',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.play_circle_outline_rounded,
                          size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        'bilibili：',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Flexible(
                        child: Semantics(
                          link: true,
                          onTap: () => _launchBilibili(context),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _launchBilibili(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                'space.bilibili.com/622550948',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: theme.colorScheme.primary
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
