import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../../state/editor_controller.dart';
import '../../theme/pixel_theme.dart';
import '../widgets/common.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_kit.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  Future<void> _editValue(
    BuildContext context, {
    required String title,
    required int value,
    required int max,
    required ValueChanged<int> onSet,
    String? quickMaxLabel,
  }) async {
    final text = TextEditingController(text: '$value');
    final result = await showPixelDialog<int>(
      context: context,
      title: title,
      icon: PixelIcons.gear,
      maxWidth: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '可输入 0 — ${formatInt(max)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PixelPalette.of(context).inkSoft,
            ),
          ),
          const SizedBox(height: 10),
          PixelTextField(
            controller: text,
            autofocus: true,
            mono: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (v) =>
                Navigator.of(context).pop(int.tryParse(v)?.clamp(0, max)),
          ),
        ],
      ),
      actions: [
        PixelButton(label: '取消', onPressed: () => Navigator.of(context).pop()),
        PixelButton(
          label: quickMaxLabel ?? '拉满',
          icon: PixelIcons.chevronUp,
          onPressed: () => Navigator.of(context).pop(max),
        ),
        PixelButton(
          label: '确定',
          tone: PixelButtonTone.primary,
          onPressed: () =>
              Navigator.of(context).pop(int.tryParse(text.text)?.clamp(0, max)),
        ),
      ],
    );
    text.dispose();
    if (result != null) onSet(result);
  }

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    if (!controller.hasSave) {
      return EmptyState(
        icon: PixelIcons.grid,
        message: '先在「存档工坊」解析存档字符串，\n这里会显示金币 / 经验 / 等级与档案总览。',
        actionLabel: '去载入存档',
        onAction: () => AppDeps.of(context).navIndex.value = 0,
      );
    }

    final catalog = controller.catalog;
    final unlockedStages = [
      for (var i = 1; i <= 21; i++) i,
    ].where(controller.stageUnlocked).length;
    final achievements = [
      for (var i = 0; i < 128; i++) controller.achievementCompleted(i),
    ].where((v) => v).length;
    final medals = [
      for (var i = 0; i < 10; i++) controller.medalUnlocked(i),
    ].where((v) => v).length;
    final monsters = [
      for (var i = 0; i < 128; i++) controller.monsterState(i),
    ].where((v) => v > 0).length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: PixelLayout.contentMax),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 24, 40),
          children: [
            WikiPageHeader(
              title: '总览',
              breadcrumb: const ['SR2 EDITOR', '总览'],
              icon: PixelIcons.grid,
              subtitle:
                  '当前存档的角色等级、资源与攻略进度一览。'
                  '点击数值卡可直接修改，批量操作会立即写入内存中的存档。',
              tags: [
                PixelBadge(
                  'User ID ${controller.userId}',
                  tone: PixelBadgeTone.neutral,
                ),
                PixelBadge(
                  '${controller.partyCount} 人队伍',
                  tone: PixelBadgeTone.link,
                ),
                PixelBadge(catalog.sourceLabel, tone: PixelBadgeTone.gold),
              ],
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final main = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatGrid(
                      controller: controller,
                      onEdit: (title, value, max, onSet, maxLabel) =>
                          _editValue(
                            context,
                            title: title,
                            value: value,
                            max: max,
                            onSet: onSet,
                            quickMaxLabel: maxLabel,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _PartyPanel(controller: controller),
                    const SizedBox(height: 16),
                    _ProgressPanel(
                      stages: unlockedStages,
                      achievements: achievements,
                      medals: medals,
                      monsters: monsters,
                    ),
                    const SizedBox(height: 16),
                    _QuickActions(controller: controller),
                  ],
                );
                final side = _ArchiveInfobox(controller: controller);
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

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.controller, required this.onEdit});

  final EditorController controller;
  final void Function(
    String title,
    int value,
    int max,
    ValueChanged<int> onSet,
    String? maxLabel,
  )
  onEdit;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final cards = [
      StatCard(
        label: '金币',
        value: formatInt(controller.gold),
        numericValue: controller.gold,
        formatter: formatInt,
        icon: PixelIcons.coin,
        color: p.goldDeep,
        max: formatInt(EditorController.maxGold),
        onTap: () => onEdit(
          '设置金币',
          controller.gold,
          EditorController.maxGold,
          controller.setGold,
          '拉满',
        ),
      ),
      StatCard(
        label: '经验',
        value: formatInt(controller.exp),
        numericValue: controller.exp,
        formatter: formatInt,
        icon: PixelIcons.bolt,
        color: p.link,
        max: formatInt(EditorController.maxExp),
        onTap: () => onEdit(
          '设置经验',
          controller.exp,
          EditorController.maxExp,
          controller.setExp,
          '拉满',
        ),
      ),
      StatCard(
        label: '等级',
        value: '${controller.level}',
        numericValue: controller.level,
        formatter: (v) => '$v',
        icon: PixelIcons.star,
        color: p.success,
        max: '99',
        onTap: () =>
            onEdit('设置等级', controller.level, 99, controller.setLevel, '99 级'),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }
        final width = (constraints.maxWidth - 24) / 3;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              SizedBox(width: width, child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _PartyPanel extends StatelessWidget {
  const _PartyPanel({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return PixelPanel(
      title: '队伍编成',
      subtitle: '队伍人数 1 — 4；角色详情请前往「角色档案」',
      icon: PixelIcons.dice,
      accent: p.gold,
      trailing: PixelBadge(
        '${controller.partyCount} 人',
        tone: PixelBadgeTone.ink,
      ),
      child: PixelSegmented<int>(
        selected: controller.partyCount.clamp(1, 4),
        onChanged: controller.setPartyCount,
        segments: const [
          PixelSegment(1, '1 人', icon: PixelIcons.person),
          PixelSegment(2, '2 人', icon: PixelIcons.person),
          PixelSegment(3, '3 人', icon: PixelIcons.person),
          PixelSegment(4, '4 人', icon: PixelIcons.person),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.stages,
    required this.achievements,
    required this.medals,
    required this.monsters,
  });

  final int stages;
  final int achievements;
  final int medals;
  final int monsters;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return PixelPanel(
      title: '进度概览',
      subtitle: '只统计当前存档中的标记值，可在「进度档案」逐项调整',
      icon: PixelIcons.trophy,
      accent: p.gold,
      child: Column(
        children: [
          _ProgressRow(
            label: '关卡解锁',
            value: stages,
            total: 21,
            color: p.success,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: '成就完成',
            value: achievements,
            total: 128,
            color: p.gold,
          ),
          const SizedBox(height: 12),
          _ProgressRow(label: '勋章解锁', value: medals, total: 10, color: p.link),
          const SizedBox(height: 12),
          _ProgressRow(
            label: '图鉴遇见',
            value: monsters,
            total: 128,
            color: p.danger,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '$value / $total',
              style: TextStyle(
                fontFamily: PixelFont.mono,
                fontFamilyFallback: PixelFont.fallback,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: p.inkSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        PixelProgressBar(value: total == 0 ? 0 : value / total, color: color),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return PixelPanel(
      title: '快捷操作',
      subtitle: '批量修改立即生效，导出前可随时在对应页面微调',
      icon: PixelIcons.spark,
      accent: p.gold,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          PixelButton(
            label: '金币拉满',
            icon: PixelIcons.coin,
            tone: PixelButtonTone.gold,
            onPressed: () {
              controller.setGold(EditorController.maxGold);
              showAppSnackBar(context, '金币已拉满');
            },
          ),
          PixelButton(
            label: '经验拉满',
            icon: PixelIcons.bolt,
            onPressed: () {
              controller.setExp(EditorController.maxExp);
              showAppSnackBar(context, '经验已拉满');
            },
          ),
          PixelButton(
            label: '等级 99',
            icon: PixelIcons.star,
            onPressed: () {
              controller.setLevel(99);
              showAppSnackBar(context, '等级已设为 99');
            },
          ),
          PixelButton(
            label: '全关卡',
            icon: PixelIcons.map,
            onPressed: () {
              controller.unlockAllStages();
              showAppSnackBar(context, '已解锁全部 32 个关卡标记');
            },
          ),
          PixelButton(
            label: '全成就',
            icon: PixelIcons.trophy,
            onPressed: () {
              controller.completeAllAchievements();
              showAppSnackBar(context, '已完成全部成就（写入目标值）');
            },
          ),
          PixelButton(
            label: '全勋章',
            icon: PixelIcons.star,
            onPressed: () {
              controller.unlockAllMedals();
              showAppSnackBar(context, '已解锁全部勋章');
            },
          ),
        ],
      ),
    );
  }
}

class _ArchiveInfobox extends StatelessWidget {
  const _ArchiveInfobox({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final sp =
        controller.skillPoint(0) +
        controller.skillPoint(1) +
        controller.skillPoint(2) +
        controller.skillPoint(3);
    return PixelPanel(
      title: '存档档案',
      icon: PixelIcons.book,
      accent: p.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelInfoTable(
            rows: [
              PixelInfoRow('User ID', controller.userId, mono: true),
              PixelInfoRow('队伍', '${controller.partyCount} 人', mono: true),
              PixelInfoRow(
                '金币',
                formatInt(controller.gold),
                mono: true,
                valueColor: p.goldDeep,
              ),
              PixelInfoRow(
                '经验',
                formatInt(controller.exp),
                mono: true,
                valueColor: p.link,
              ),
              PixelInfoRow('等级', '${controller.level}', mono: true),
              PixelInfoRow('当前关卡', '${controller.stage}', mono: true),
              PixelInfoRow('持有物品', '${controller.itemsTotal} 种', mono: true),
              PixelInfoRow('技能点合计', '$sp', mono: true),
            ],
          ),
          const SizedBox(height: 10),
          PixelCallout(
            message: '数值上限由存档的 6-bit 位域决定：金币 / 经验 16,777,215，等级 99。',
            icon: PixelIcons.info,
            tone: PixelBadgeTone.link,
          ),
        ],
      ),
    );
  }
}
