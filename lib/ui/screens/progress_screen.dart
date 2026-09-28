import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/game_data.dart';
import '../../models/icon_assets.dart';
import '../../state/editor_controller.dart';
import '../widgets/common.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    if (!controller.hasSave) {
      return EmptyState(
        icon: Icons.emoji_events_outlined,
        message: '载入存档后即可编辑关卡 / 成就 / 勋章 /\n技能标记 / 怪物图鉴 / 选项',
        actionLabel: '去载入存档',
        onAction: () => AppDeps.of(context).navIndex.value = 0,
      );
    }

    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: '关卡', icon: Icon(Icons.map_rounded, size: 18)),
              Tab(text: '成就', icon: Icon(Icons.emoji_events_rounded, size: 18)),
              Tab(text: '勋章', icon: Icon(Icons.workspace_premium_rounded, size: 18)),
              Tab(text: '饭团', icon: Icon(Icons.rice_bowl_rounded, size: 18)),
              Tab(text: '图鉴', icon: Icon(Icons.menu_book_rounded, size: 18)),
              Tab(text: '选项', icon: Icon(Icons.settings_rounded, size: 18)),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
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
    );
  }
}

// ==================== 关卡 ====================

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '已解锁 ${stages.where((s) => controller.stageUnlocked(s.id)).length} / 21',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    controller.unlockAllStages();
                    showAppSnackBar(context, '已解锁全部关卡');
                  },
                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                  label: const Text('全部解锁'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (var area = 0; area < 4; area++) ...[
          SectionCard(
            title: areaNames[area],
            icon: Icons.landscape_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in stages.where((s) => s.area == area))
                  FilterChip(
                    label: Text(s.name),
                    selected: controller.stageUnlocked(s.id),
                    onSelected: (v) => controller.setStageUnlocked(s.id, v),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ==================== 成就 ====================

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  Future<void> _confirmAll(BuildContext context, EditorController controller,
      {required bool complete}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(complete ? '完成全部成就？' : '清零全部成就？'),
        content: Text(complete
            ? '128 个成就将全部写入各自的目标值。'
            : '128 个成就进度将全部归零。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(complete ? '全部完成' : '全部清零'),
          ),
        ],
      ),
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
    final completed =
        [for (var i = 0; i < 128; i++) controller.achievementCompleted(i)]
            .where((v) => v)
            .length;

    // 按关卡分组。
    final groups = <int, List<int>>{};
    for (var i = 0; i < 128; i++) {
      groups.putIfAbsent(catalog.achievementDef(i).stageId, () => []).add(i);
    }
    final sortedStages = groups.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '已完成 $completed / 128',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _confirmAll(context, controller, complete: true),
                      child: const Text('全部完成'),
                    ),
                    TextButton(
                      onPressed: () => _confirmAll(context, controller, complete: false),
                      child: const Text('全部清零'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completed / 128,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final stageId in sortedStages)
          _AchievementStageGroup(stageId: stageId, ids: groups[stageId]!),
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
    final theme = Theme.of(context);
    final controller = EditorScope.watch(context);
    final catalog = controller.catalog;
    final stageName = stageId == 0 ? '（未分组）' : catalog.stageName(stageId);
    final done = ids.where(controller.achievementCompleted).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          title: Text(
            stageName,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '关卡 $stageId · $done/${ids.length}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontFeatures: tabularFigures,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: done == ids.length
              ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
              : Text(
                  '$done/${ids.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontFeatures: tabularFigures,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
          children: [
            for (final id in ids)
              CheckboxListTile(
                dense: true,
                controlAffinity: ListTileControlAffinity.trailing,
                title: Text(
                  catalog.achievementDef(id).name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: controller.achievementCompleted(id)
                        ? TextDecoration.none
                        : null,
                    fontWeight: controller.achievementCompleted(id)
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                subtitle: catalog.achievementDef(id).subtitle.isEmpty
                    ? null
                    : Text(catalog.achievementDef(id).subtitle),
                secondary: _AchievementLeading(
                  iconId: catalog.achievementDef(id).iconId,
                  targetValue: catalog.achievementDef(id).targetValue,
                  completed: controller.achievementCompleted(id),
                ),
                value: controller.achievementCompleted(id),
                onChanged: (v) => controller.setAchievementCompleted(id, v ?? false),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== 勋章 ====================

/// 成就行首：原版奖章图标（medal.png，索引 = v[][3]）+ 目标值徽章。
/// 游戏逻辑：未完成的奖章整体乘 0x444444 变暗。
class _AchievementLeading extends StatelessWidget {
  const _AchievementLeading({
    required this.iconId,
    required this.targetValue,
    required this.completed,
  });

  final int iconId;
  final int targetValue;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMedal = kAvailableMedalIcons.contains(iconId);
    Widget? medal;
    if (hasMedal) {
      medal = Image.asset(
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
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (medal != null) ...[
          medal,
          const SizedBox(width: 6),
        ],
        InfoBadge('目标 $targetValue', color: theme.colorScheme.tertiary),
      ],
    );
  }
}

class _MedalsTab extends StatelessWidget {
  const _MedalsTab();

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    final catalog = controller.catalog;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '已解锁 ${[for (var i = 0; i < 10; i++) controller.medalUnlocked(i)].where((v) => v).length} / 10',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    controller.unlockAllMedals();
                    showAppSnackBar(context, '已解锁全部勋章');
                  },
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: const Text('全部解锁'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < 10; i++) ...[
                SwitchListTile(
                  value: controller.medalUnlocked(i),
                  onChanged: (v) => controller.setMedalUnlocked(i, v),
                  secondary: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: controller.medalUnlocked(i)
                          ? theme.colorScheme.tertiaryContainer
                          : theme.colorScheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      size: 20,
                      color: controller.medalUnlocked(i)
                          ? theme.colorScheme.onTertiaryContainer
                          : theme.colorScheme.outline,
                    ),
                  ),
                  title: Text(
                    catalog.medalName(i),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: controller.medalUnlocked(i)
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  subtitle: Text(
                    i < 5
                        ? '收集 ${catalog.medalRequirement(i)} 个成就后解锁'
                        : '关卡通关勋章（第 ${i - 4} 枚）',
                  ),
                ),
                if (i < 9) const Divider(indent: 68),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== 饭团 ====================

class _OnigiriTab extends StatelessWidget {
  const _OnigiriTab();

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        SectionCard(
          title: '饭团数量',
          subtitle: '回血道具的持有数量',
          iconWidget: Image.asset(
            'assets/icons/onigiri.png',
            width: 22,
            height: 22,
            filterQuality: FilterQuality.none,
          ),
          child: NumberField(
            label: '饭团数量',
            value: controller.usedSp,
            min: 0,
            max: 63,
            onChanged: controller.setUsedSp,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ],
    );
  }
}

// ==================== 图鉴 ====================

class _MonsterTab extends StatelessWidget {
  const _MonsterTab();

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    final viewed =
        [for (var i = 0; i < 128; i++) controller.monsterState(i) == 2]
            .where((v) => v)
            .length;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '已查看 $viewed / 128',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    controller.viewAllMonsters();
                    showAppSnackBar(context, '已将全部图鉴设为「已查看」');
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('全部已查看'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.88,
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
    final theme = Theme.of(context);
    final controller = EditorScope.watch(context);
    final state = controller.monsterState(index);
    final face = controller.catalog.monsterFace(index);
    final faceAsset =
        face != null && kAvailableEnemyFaces.contains(face) ? face : null;
    // 脸谱按怪物主色（H[i][6]）乘法染色，与游戏内绘制一致。
    final faceColor = controller.catalog.monsterColor(index);

    return Card(
      margin: EdgeInsets.zero,
      color: state == 0 ? theme.colorScheme.surfaceContainerHigh : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 68,
              child: faceAsset == null
                  ? Icon(
                      Icons.pets_rounded,
                      size: 40,
                      color: theme.colorScheme.outlineVariant,
                    )
                  : Center(
                      child: Image.asset(
                        enemyAssetPath(faceAsset),
                        width: 96,
                        height: 96,
                        filterQuality: FilterQuality.none,
                        color: faceColor != null
                            ? Color(0xFF000000 | faceColor)
                            : null,
                        colorBlendMode:
                            faceColor != null ? BlendMode.modulate : null,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              '怪物 #${index.toString().padLeft(3, '0')}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontFeatures: tabularFigures,
                fontWeight: FontWeight.w600,
                color: state == 0 ? theme.colorScheme.outline : null,
              ),
            ),
            const SizedBox(height: 8),
            // 游戏内图鉴按金币逐步解锁：1 级=遇见、2 级=查看数据、3 级=完全查看。
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (value, label) in const [
                  (0, '怪物信息1级'),
                  (1, '怪物信息2级'),
                  (2, '怪物信息3级'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ChoiceChip(
                      label: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      selected: state == value,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onSelected: (_) => controller.setMonsterState(index, value),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 选项 ====================

class _OptionsTab extends StatelessWidget {
  const _OptionsTab();

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        SectionCard(
          title: '自动移动（mb）',
          icon: Icons.directions_run_rounded,
          subtitle: '每个角色的自动移动开关',
          child: Column(
            children: [
              for (var i = 0; i < 4; i++)
                SwitchListTile(
                  dense: true,
                  value: controller.autoMove(i),
                  onChanged: (v) => controller.setAutoMove(i, v),
                  title: Text('角色 ${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '悬崖停止（nb）',
          icon: Icons.block_rounded,
          child: SwitchListTile(
            value: controller.cliffStop,
            onChanged: (v) => controller.setCliffStop(v),
            title: const Text('在悬崖边停止',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '关卡事件标记（rf）',
          icon: Icons.extension_rounded,
          subtitle: 'rf[0]：关卡 13/16 地形通路 · rf[1]：关卡 19 隐藏区域入口',
          child: Column(
            children: [
              for (var i = 0; i < 4; i++)
                SwitchListTile(
                  dense: true,
                  value: controller.eventFlag(i),
                  onChanged: (v) => controller.setEventFlag(i, v),
                  title: Text(
                    'rf[$i]',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFeatures: tabularFigures,
                      color: i >= 2 ? theme.colorScheme.outline : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
