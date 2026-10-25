import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../app_info.dart';
import '../../main.dart';
import '../../models/game_data.dart';
import '../../services/data_updater.dart';
import '../../services/open_external.dart';
import '../../theme/pixel_theme.dart';
import '../widgets/common.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_kit.dart';

const _gameJsUrl = 'https://dan-ball.jp/en/javagame/ranger2/ranger2.js';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  bool _updating = false;

  Future<void> _updateFromOfficial() async {
    // 浏览器 CORS 限制导致 web 端无法直读 dan-ball.jp 响应，直接引导使用客户端。
    if (kIsWeb) {
      await showPixelDialog<void>(
        context: context,
        title: 'Web 端暂不支持',
        icon: PixelIcons.warning,
        maxWidth: 420,
        child: const Text(
          '浏览器安全策略（CORS）禁止网页直接读取官网数据。\n'
          '请下载安装 Windows 或 Android 客户端使用数据更新功能。',
          style: TextStyle(height: 1.8),
        ),
        actions: [
          PixelButton(
            label: '知道了',
            tone: PixelButtonTone.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
      return;
    }
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
      if (mounted) {
        showAppSnackBar(context, '更新失败：${_friendlyError(e)}', error: true);
      }
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
    final ok = await showPixelDialog<bool>(
      context: context,
      title: '恢复内置数据？',
      icon: PixelIcons.download,
      maxWidth: 420,
      child: const Text(
        '将丢弃官网更新的本地覆盖，重新使用随应用打包的数据文件。',
        style: TextStyle(height: 1.8),
      ),
      actions: [
        PixelButton(
          label: '取消',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PixelButton(
          label: '恢复',
          icon: PixelIcons.download,
          tone: PixelButtonTone.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
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
    final isOverride = catalog.sourceLabel == '官网更新';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: PixelLayout.contentMax),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 24, 40),
          children: [
            WikiPageHeader(
              title: '数据源',
              breadcrumb: const ['SR2 EDITOR', '数据源'],
              icon: PixelIcons.book,
              subtitle:
                  '物品 / 关卡 / 成就 / 勋章的本地目录。可从 dan-ball.jp 拉取最新的 '
                  'ranger2.js 重新解析，结果保存在本机，随时可恢复内置数据。',
              tags: [
                PixelBadge(
                  '来源：${catalog.sourceLabel}',
                  tone: isOverride
                      ? PixelBadgeTone.gold
                      : PixelBadgeTone.neutral,
                ),
                if (isOverride && deps.repository.updatedAtLabel != null)
                  PixelBadge(
                    '更新于 ${deps.repository.updatedAtLabel}',
                    tone: PixelBadgeTone.link,
                  ),
                const PixelBadge(
                  '离线可用',
                  tone: PixelBadgeTone.success,
                  dot: true,
                ),
              ],
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final main = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DataOverviewPanel(catalog: catalog),
                    const SizedBox(height: 16),
                    _UpdatePanel(
                      updating: _updating,
                      isOverride: isOverride,
                      onUpdate: _updateFromOfficial,
                      onRestore: isOverride ? _restoreBuiltin : null,
                    ),
                    const SizedBox(height: 16),
                    _AboutPanel(onBilibili: () => _launchBilibili(context)),
                  ],
                );
                final side = _DataInfobox(
                  catalog: catalog,
                  isOverride: isOverride,
                  updatedAt: deps.repository.updatedAtLabel,
                );
                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [main, const SizedBox(height: 16), side],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: main),
                    const SizedBox(width: 16),
                    SizedBox(width: 300, child: side),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DataOverviewPanel extends StatelessWidget {
  const _DataOverviewPanel({required this.catalog});

  final GameCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final entries = [
      ('物品', '${catalog.itemCount} 种', PixelIcons.bag, p.goldDeep),
      ('成就', '${catalog.achievementCount} 项', PixelIcons.trophy, p.link),
      ('关卡', '${catalog.stages.length - 1} 个', PixelIcons.map, p.success),
      ('勋章', '${catalog.medals.length} 枚', PixelIcons.star, p.danger),
    ];
    return PixelPanel(
      title: '数据概览',
      icon: PixelIcons.grid,
      accent: p.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCol = constraints.maxWidth >= 480;
              final width = twoCol ? (constraints.maxWidth - 12) / 2 : null;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (label, value, icon, color) in entries)
                    SizedBox(
                      width: width,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: p.paperAlt,
                          border: Border.all(color: p.border, width: 1),
                        ),
                        child: Row(
                          children: [
                            PixelGlyph(
                              icon,
                              size: 24,
                              color: color,
                              accent: color,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  label,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: p.inkSoft),
                                ),
                                Text(
                                  value,
                                  style: TextStyle(
                                    fontFamily: PixelFont.family,
                                    fontFamilyFallback: PixelFont.fallback,
                                    fontSize: 24,
                                    height: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: p.ink,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          PixelCallout(
            message:
                '数据更新只替换物品 / 关卡 / 成就 / 勋章的目录展示信息，'
                '不会修改已载入的存档数组；重新解析存档不是必需的。',
            icon: PixelIcons.info,
            tone: PixelBadgeTone.link,
          ),
        ],
      ),
    );
  }
}

class _UpdatePanel extends StatelessWidget {
  const _UpdatePanel({
    required this.updating,
    required this.isOverride,
    required this.onUpdate,
    required this.onRestore,
  });

  final bool updating;
  final bool isOverride;
  final VoidCallback onUpdate;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return PixelPanel(
      title: '从官网更新',
      subtitle: '下载 dan-ball.jp 的 ranger2.js 并重新解析，结果保存在本机',
      icon: PixelIcons.download,
      accent: p.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PixelButton(
                label: updating ? '正在更新…' : '立即更新',
                icon: updating ? PixelIcons.clock : PixelIcons.download,
                tone: PixelButtonTone.primary,
                onPressed: updating ? null : onUpdate,
              ),
              PixelButton(
                label: '恢复内置数据',
                icon: PixelIcons.download,
                onPressed: (isOverride && !updating) ? onRestore : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          PixelCallout(
            message: kIsWeb
                ? 'Web 端受浏览器 CORS 限制，无法直接读取官网数据；请使用 Windows / Android 客户端。'
                : '更新请求只访问 dan-ball.jp，不会上传存档或任何本地数据。',
            icon: PixelIcons.warning,
            tone: kIsWeb ? PixelBadgeTone.gold : PixelBadgeTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel({required this.onBilibili});

  final VoidCallback onBilibili;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return PixelPanel(
      title: '关于',
      icon: PixelIcons.bookOpen,
      accent: p.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SR2Editor',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '面向 Dan-Ball Stick Ranger 2（ver32.3）的本地存档编辑工具，'
            '存档格式逆向自 ranger2.js。应用除数据更新外完全离线，不会上传任何数据。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: p.inkSoft, height: 1.75),
          ),
          const SizedBox(height: 10),
          PixelCallout(
            message: '修改存档前请务必备份原始字符串。',
            icon: PixelIcons.warning,
            tone: PixelBadgeTone.gold,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PixelGlyph(PixelIcons.person, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '作者：Leesz',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PixelGlyph(PixelIcons.external, size: 16, color: p.link),
                  const SizedBox(width: 6),
                  PixelLink(
                    'bilibili · space.bilibili.com/622550948',
                    onTap: onBilibili,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataInfobox extends StatelessWidget {
  const _DataInfobox({
    required this.catalog,
    required this.isOverride,
    required this.updatedAt,
  });

  final GameCatalog catalog;
  final bool isOverride;
  final String? updatedAt;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return PixelPanel(
      title: '数据源档案',
      icon: PixelIcons.book,
      accent: p.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelInfoTable(
            rows: [
              PixelInfoRow(
                '来源',
                catalog.sourceLabel,
                valueColor: isOverride ? p.goldDeep : p.ink,
              ),
              if (isOverride && updatedAt != null)
                PixelInfoRow('更新时间', updatedAt!, mono: true),
              PixelInfoRow('物品', '${catalog.itemCount} 种', mono: true),
              PixelInfoRow('成就', '${catalog.achievementCount} 项', mono: true),
              PixelInfoRow('关卡', '${catalog.stages.length - 1} 个', mono: true),
              PixelInfoRow('勋章', '${catalog.medals.length} 枚', mono: true),
              const PixelInfoRow('版本', kAppVersion, mono: true),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.paperAlt,
              border: Border.all(color: p.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '内置数据文件',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'assets/item_stats.json\nassets/achievement_data.json',
                  style: TextStyle(
                    fontFamily: PixelFont.mono,
                    fontFamilyFallback: PixelFont.fallback,
                    fontSize: 12,
                    height: 1.6,
                    color: p.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
