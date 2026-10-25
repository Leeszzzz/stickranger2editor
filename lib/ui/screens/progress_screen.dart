import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/game_data.dart';
import '../../models/icon_assets.dart';
import '../../state/editor_controller.dart';
import '../../theme/pixel_theme.dart';
import '../widgets/common.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_kit.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _tab = 0;

  static const _tabs = [
    PixelTab('关卡', icon: PixelIcons.map),
    PixelTab('成就', icon: PixelIcons.trophy),
    PixelTab('勋章', icon: PixelIcons.star),
    PixelTab('饭团', icon: PixelIcons.potion),
    PixelTab('图鉴', icon: PixelIcons.eye),
    PixelTab('选项', icon: PixelIcons.gear),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    if (!controller.hasSave) {
      return EmptyState(
        icon: PixelIcons.trophy,
        message: '载入存档后即可编辑关卡 / 成就 / 勋章 /\n图鉴 / 选项与饭团数量。',
        actionLabel: '去载入存档',
        onAction: () => AppDeps.of(context).navIndex.value = 0,
      );
    }

    final stages = [
      for (var i = 1; i <= 21; i++) i,
    ].where(controller.stageUnlocked).length;
    final achievements = [
      for (var i = 0; i < 128; i++) controller.achievementCompleted(i),
    ].where((v) => v).length;
    final monsters = [
      for (var i = 0; i < 128; i++) controller.monsterState(i) > 0,
    ].where((v) => v).length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: PixelLayout.contentMax),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 24, 0),
              child: WikiPageHeader(
                title: '进度档案',
                breadcrumb: const ['SR2 EDITOR', '进度档案'],
                icon: PixelIcons.trophy,
                subtitle:
                    '关卡解锁、128 项成就、10 枚勋章、怪物图鉴与存档选项。'
                    '所有切换都会立即写入内存，导出时统一编码。',
                tags: [
                  PixelBadge('关卡 $stages/21', tone: PixelBadgeTone.success),
                  PixelBadge('成就 $achievements/128', tone: PixelBadgeTone.gold),
                  PixelBadge('图鉴 $monsters/128', tone: PixelBadgeTone.link),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PixelTabs(
                tabs: _tabs,
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  _StagesTab(),
                  _AchievementsTab(),
                  _MedalsTab(),
                  _OnigiriTab(),
                  _MonsterTab(),
                  _OptionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 关卡
// ============================================================================

class _StagesTab extends StatelessWidget {
  const _StagesTab();

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    final catalog = controller.catalog;
    final stages = [
      for (var i = 1; i <= 21; i++)
        (id: i, name: catalog.stageName(i), area: catalog.stageArea(i)),
    ];
    final unlocked = stages.where((s) => controller.stageUnlocked(s.id)).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 24, 40),
      children: [
        PixelPanel(
          title: '关卡解锁',
          icon: PixelIcons.map,
          dense: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '已解锁 $unlocked / 21',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  PixelButton(
                    label: '全部解锁',
                    icon: PixelIcons.unlock,
                    size: PixelButtonSize.small,
                    tone: PixelButtonTone.gold,
                    onPressed: () {
                      controller.unlockAllStages();
                      showAppSnackBar(context, '已解锁全部关卡');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              PixelProgressBar(value: unlocked / 21),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var area = 0; area < 4; area++) ...[
          PixelPanel(
            title: areaNames[area],
            icon: PixelIcons.flag,
            dense: true,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in stages.where((s) => s.area == area))
                  PixelChip(
                    label: s.name,
                    selected: controller.stageUnlocked(s.id),
                    onTap: () => controller.setStageUnlocked(
                      s.id,
                      !controller.stageUnlocked(s.id),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        PixelCallout(
          message:
              '存档中共有 32 个关卡标记，本页展示可编辑的 1–21。'
              '「全部解锁」会写入全部 32 个标记。',
          icon: PixelIcons.info,
          tone: PixelBadgeTone.link,
        ),
      ],
    );
  }
}

// ============================================================================
// 成就
// ============================================================================

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  Future<void> _confirmAll(
    BuildContext context,
    EditorController controller, {
    required bool complete,
  }) async {
    final ok = await showPixelDialog<bool>(
      context: context,
      title: complete ? '完成全部成就？' : '清零全部成就？',
      icon: complete ? PixelIcons.trophy : PixelIcons.trash,
      maxWidth: 400,
      child: Text(
        complete ? '128 个成就将全部写入各自的目标值。' : '128 个成就进度将全部归零。',
        style: const TextStyle(height: 1.7),
      ),
      actions: [
        PixelButton(
          label: '取消',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PixelButton(
          label: complete ? '全部完成' : '全部清零',
          tone: complete ? PixelButtonTone.primary : PixelButtonTone.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (ok == true) {
      complete
          ? controller.completeAllAchievements()
          : controller.resetAllAchievements();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    final catalog = controller.catalog;
    final completed = [
      for (var i = 0; i < 128; i++) controller.achievementCompleted(i),
    ].where((v) => v).length;

    final groups = <int, List<int>>{};
    for (var i = 0; i < 128; i++) {
      groups.putIfAbsent(catalog.achievementDef(i).stageId, () => []).add(i);
    }
    final sortedStages = groups.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 24, 40),
      children: [
        PixelPanel(
          title: '成就进度',
          icon: PixelIcons.trophy,
          dense: true,
          trailing: Wrap(
            spacing: 6,
            children: [
              PixelButton(
                label: '全部完成',
                size: PixelButtonSize.small,
                tone: PixelButtonTone.gold,
                onPressed: () =>
                    _confirmAll(context, controller, complete: true),
              ),
              PixelButton(
                label: '全部清零',
                size: PixelButtonSize.small,
                tone: PixelButtonTone.danger,
                onPressed: () =>
                    _confirmAll(context, controller, complete: false),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '已完成 $completed / 128',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(completed / 128 * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: PixelFont.mono,
                      fontFamilyFallback: PixelFont.fallback,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PixelPalette.of(context).goldDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              PixelProgressBar(value: completed / 128),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PixelPanel(
          title: '成就列表',
          subtitle: '按关卡分组，点击行首复选框完成 / 清零',
          icon: PixelIcons.star,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < sortedStages.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: PixelPalette.of(context).border.withValues(
                          alpha: i == sortedStages.length - 1 ? 0 : 0.25,
                        ),
                      ),
                    ),
                  ),
                  child: _AchievementStageGroup(
                    stageId: sortedStages[i],
                    ids: groups[sortedStages[i]]!,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AchievementStageGroup extends StatelessWidget {
  const _AchievementStageGroup({required this.stageId, required this.ids});

  final int stageId;
  final List<int> ids;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final controller = EditorScope.watch(context);
    final catalog = controller.catalog;
    final stageName = stageId == 0 ? '（未分组）' : catalog.stageName(stageId);
    final done = ids.where(controller.achievementCompleted).length;

    return PixelExpansion(
      header: Row(
        children: [
          PixelGlyph(
            done == ids.length ? PixelIcons.check : PixelIcons.flag,
            size: 16,
            color: done == ids.length ? p.success : p.inkSoft,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stageName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '关卡 $stageId · $done / ${ids.length}',
                  style: TextStyle(
                    fontFamily: PixelFont.mono,
                    fontFamilyFallback: PixelFont.fallback,
                    fontSize: 12,
                    color: p.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 76,
            child: PixelProgressBar(
              value: ids.isEmpty ? 0 : done / ids.length,
              height: 8,
              color: done == ids.length ? p.success : p.gold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$done/${ids.length}',
            style: TextStyle(
              fontFamily: PixelFont.mono,
              fontFamilyFallback: PixelFont.fallback,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: done == ids.length ? p.success : p.inkSoft,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < ids.length; i++)
            _AchievementRow(id: ids[i], last: i == ids.length - 1),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.id, required this.last});

  final int id;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final controller = EditorScope.watch(context);
    final def = controller.catalog.achievementDef(id);
    final completed = controller.achievementCompleted(id);
    return InkWell(
      onTap: () => controller.setAchievementCompleted(id, !completed),
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: Container(
        decoration: BoxDecoration(
          color: completed ? p.panel : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: p.border.withValues(alpha: last ? 0 : 0.16),
            ),
            left: BorderSide(
              color: completed ? p.gold : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
        child: Row(
          children: [
            _AchievementMedal(
              iconId: def.iconId,
              targetValue: def.targetValue,
              completed: completed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    def.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: completed ? FontWeight.w700 : FontWeight.w400,
                      color: completed ? p.ink : p.inkSoft,
                    ),
                  ),
                  if (def.subtitle.isNotEmpty)
                    Text(
                      def.subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: p.inkFaint),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            PixelBadge(
              '目标 ${def.targetValue}',
              tone: completed ? PixelBadgeTone.gold : PixelBadgeTone.neutral,
            ),
            const SizedBox(width: 8),
            PixelCheckbox(
              value: completed,
              onChanged: (v) => controller.setAchievementCompleted(id, v),
            ),
          ],
        ),
      ),
    );
  }
}

/// 成就行首：原版奖章图标（medal.png）+ 未完成时的 0x444444 变暗。
class _AchievementMedal extends StatelessWidget {
  const _AchievementMedal({
    required this.iconId,
    required this.targetValue,
    required this.completed,
  });

  final int iconId;
  final int targetValue;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final hasMedal = kAvailableMedalIcons.contains(iconId);
    Widget content;
    if (hasMedal) {
      Widget medal = Image.asset(
        medalAssetPath(iconId),
        width: 22,
        height: 22,
        filterQuality: FilterQuality.none,
      );
      if (!completed) {
        medal = ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Color(0xFF444444),
            BlendMode.modulate,
          ),
          child: medal,
        );
      }
      content = medal;
    } else {
      content = PixelGlyph(
        PixelIcons.star,
        size: 16,
        color: completed ? p.goldDeep : p.inkFaint,
        accent: completed ? p.gold : p.inkFaint,
      );
    }
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: completed ? p.goldSoft : p.paperAlt,
        border: Border.all(color: completed ? p.goldDeep : p.border, width: 1),
      ),
      child: content,
    );
  }
}

// ============================================================================
// 勋章
// ============================================================================

class _MedalsTab extends StatelessWidget {
  const _MedalsTab();

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    final p = PixelPalette.of(context);
    final unlocked = [
      for (var i = 0; i < 10; i++) controller.medalUnlocked(i),
    ].where((v) => v).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 24, 40),
      children: [
        PixelPanel(
          title: '勋章解锁',
          icon: PixelIcons.star,
          dense: true,
          trailing: PixelButton(
            label: '全部解锁',
            icon: PixelIcons.unlock,
            size: PixelButtonSize.small,
            tone: PixelButtonTone.gold,
            onPressed: () {
              controller.unlockAllMedals();
              showAppSnackBar(context, '已解锁全部勋章');
            },
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '已解锁 $unlocked / 10',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(unlocked / 10 * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontFamily: PixelFont.mono,
                      fontFamilyFallback: PixelFont.fallback,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.goldDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              PixelProgressBar(value: unlocked / 10),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PixelPanel(
          title: '勋章列表',
          icon: PixelIcons.trophy,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < 10; i++) _MedalRow(index: i, last: i == 9),
            ],
          ),
        ),
      ],
    );
  }
}

class _MedalRow extends StatelessWidget {
  const _MedalRow({required this.index, required this.last});

  final int index;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final controller = EditorScope.watch(context);
    final catalog = controller.catalog;
    final unlocked = controller.medalUnlocked(index);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: p.border.withValues(alpha: last ? 0 : 0.18),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: unlocked ? p.goldSoft : p.paperAlt,
              border: Border.all(
                color: unlocked ? p.goldDeep : p.border,
                width: PixelSize.border,
              ),
            ),
            child: PixelGlyph(
              PixelIcons.star,
              size: 24,
              color: unlocked ? p.goldDeep : p.inkFaint,
              accent: unlocked ? p.gold : p.inkFaint,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  catalog.medalName(index),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: unlocked ? p.ink : p.inkSoft,
                  ),
                ),
                Text(
                  index < 5
                      ? '收集 ${catalog.medalRequirement(index)} 个成就后解锁'
                      : '关卡通关勋章（第 ${index - 4} 枚）',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: p.inkSoft),
                ),
              ],
            ),
          ),
          PixelSwitch(
            value: unlocked,
            onChanged: (v) => controller.setMedalUnlocked(index, v),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 饭团
// ============================================================================

class _OnigiriTab extends StatelessWidget {
  const _OnigiriTab();

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    final p = PixelPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 24, 40),
      children: [
        PixelPanel(
          title: '饭团数量',
          subtitle: '回血道具的持有数量',
          iconWidget: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.paperAlt,
              border: Border.all(color: p.border, width: 1),
            ),
            child: Image.asset(
              'assets/icons/onigiri.png',
              width: 22,
              height: 22,
              filterQuality: FilterQuality.none,
            ),
          ),
          child: NumberField(
            label: '饭团数量',
            value: controller.usedSp,
            min: 0,
            max: 63,
            onChanged: controller.setUsedSp,
            color: p.goldDeep,
          ),
        ),
        const SizedBox(height: 12),
        PixelCallout(
          message:
              '该值对应存档字段 jb[9]（饭团数量），与技能点无关。'
              '修改后进入关卡前会显示新的持有数量。',
          icon: PixelIcons.potion,
          tone: PixelBadgeTone.gold,
        ),
      ],
    );
  }
}

// ============================================================================
// 图鉴
// ============================================================================

class _MonsterTab extends StatelessWidget {
  const _MonsterTab();

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    final p = PixelPalette.of(context);
    final viewed = [
      for (var i = 0; i < 128; i++) controller.monsterState(i) == 2,
    ].where((v) => v).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 24, 0),
          child: PixelPanel(
            title: '怪物图鉴',
            icon: PixelIcons.eye,
            dense: true,
            trailing: PixelButton(
              label: '全部已查看',
              icon: PixelIcons.eye,
              size: PixelButtonSize.small,
              tone: PixelButtonTone.gold,
              onPressed: () {
                controller.viewAllMonsters();
                showAppSnackBar(context, '已将全部图鉴设为「已查看」');
              },
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      '已查看 $viewed / 128',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '三态：未遇 / 已遇 / 已查看',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: p.inkSoft),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                PixelProgressBar(value: viewed / 128, color: p.link),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 24, 40),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 196,
              mainAxisExtent: 164,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: 128,
            itemBuilder: (context, i) => _MonsterTile(index: i),
          ),
        ),
      ],
    );
  }
}

class _MonsterTile extends StatelessWidget {
  const _MonsterTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final controller = EditorScope.watch(context);
    final state = controller.monsterState(index);
    final face = controller.catalog.monsterFace(index);
    final faceAsset = face != null && kAvailableEnemyFaces.contains(face)
        ? face
        : null;
    final faceColor = controller.catalog.monsterColor(index);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: state == 0 ? p.paperAlt : p.panel,
        border: Border.all(
          color: state == 0 ? p.border.withValues(alpha: 0.5) : p.border,
          width: PixelSize.border,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: faceAsset == null
                  ? PixelGlyph(
                      PixelIcons.skull,
                      size: 48,
                      color: p.inkFaint,
                      accent: p.inkFaint,
                    )
                  : Image.asset(
                      enemyAssetPath(faceAsset),
                      width: 64,
                      height: 64,
                      filterQuality: FilterQuality.none,
                      color: faceColor != null
                          ? Color(0xFF000000 | faceColor)
                          : null,
                      colorBlendMode: faceColor != null
                          ? BlendMode.modulate
                          : null,
                    ),
            ),
          ),
          Text(
            '#${index.toString().padLeft(3, '0')}',
            style: TextStyle(
              fontFamily: PixelFont.mono,
              fontFamilyFallback: PixelFont.fallback,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: state == 0 ? p.inkFaint : p.inkSoft,
            ),
          ),
          const SizedBox(height: 4),
          PixelSegmented<int>(
            selected: state,
            onChanged: (v) => controller.setMonsterState(index, v),
            segments: const [
              PixelSegment(0, '未遇'),
              PixelSegment(1, '已遇'),
              PixelSegment(2, '查看'),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 选项
// ============================================================================

class _OptionsTab extends StatelessWidget {
  const _OptionsTab();

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 24, 40),
      children: [
        PixelPanel(
          title: '自动移动',
          subtitle: '每个角色的自动移动开关（mb）',
          icon: PixelIcons.person,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < 4; i++)
                _SwitchRow(
                  label: '角色 ${i + 1}',
                  value: controller.autoMove(i),
                  last: i == 3,
                  onChanged: (v) => controller.setAutoMove(i, v),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PixelPanel(
          title: '悬崖停止',
          subtitle: '遇到悬崖边缘时停止移动（nb）',
          icon: PixelIcons.shield,
          padding: EdgeInsets.zero,
          child: _SwitchRow(
            label: '在悬崖边停止',
            value: controller.cliffStop,
            last: true,
            onChanged: controller.setCliffStop,
          ),
        ),
        const SizedBox(height: 12),
        PixelPanel(
          title: '关卡事件标记',
          subtitle: 'rf[0]：关卡 13/16 地形通路 · rf[1]：关卡 19 隐藏区域入口',
          icon: PixelIcons.flag,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < 4; i++)
                _SwitchRow(
                  label: 'rf[$i]',
                  value: controller.eventFlag(i),
                  last: i == 3,
                  muted: i >= 2,
                  onChanged: (v) => controller.setEventFlag(i, v),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PixelCallout(
          message:
              '事件标记对应存档末尾的 rf 数组，仅部分关卡使用；'
              '不确定作用时建议保持原值。',
          icon: PixelIcons.info,
          tone: PixelBadgeTone.neutral,
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.last,
    this.muted = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: p.border.withValues(alpha: last ? 0 : 0.18),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: muted ? p.inkFaint : p.ink,
            ),
          ),
          const Spacer(),
          PixelSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
