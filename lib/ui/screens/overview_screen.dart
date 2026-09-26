import 'package:flutter/material.dart';

import '../../main.dart';
import '../../state/editor_controller.dart';
import '../widgets/common.dart';

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
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          autofocus: true,
          controller: text,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: '数值（0 - ${formatInt(max)}）'),
          onSubmitted: (v) =>
              Navigator.of(context).pop(int.tryParse(v)?.clamp(0, max)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(max), // 拉满
            child: Text(quickMaxLabel ?? '拉满'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(text.text)?.clamp(0, max)),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null) onSet(result);
  }

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    final theme = Theme.of(context);
    if (!controller.hasSave) {
      return EmptyState(
        icon: Icons.dashboard_outlined,
        message: '先在「存档」页解析存档字符串，\n这里会显示金币 / 经验 / 等级等总览信息',
        actionLabel: '去载入存档',
        onAction: () => AppDeps.of(context).navIndex.value = 0,
      );
    }

    final stages = controller.catalog.stages;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 24) / 3;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        label: '金币',
                        value: formatInt(controller.gold),
                        icon: Icons.paid_rounded,
                        color: theme.colorScheme.tertiary,
                        max: formatInt(EditorController.maxGold),
                        onTap: () => _editValue(
                          context,
                          title: '设置金币',
                          value: controller.gold,
                          max: EditorController.maxGold,
                          onSet: controller.setGold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        label: '经验',
                        value: formatInt(controller.exp),
                        icon: Icons.bolt_rounded,
                        color: theme.colorScheme.primary,
                        max: formatInt(EditorController.maxExp),
                        onTap: () => _editValue(
                          context,
                          title: '设置经验',
                          value: controller.exp,
                          max: EditorController.maxExp,
                          onSet: controller.setExp,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        label: '等级',
                        value: '${controller.level}',
                        icon: Icons.military_tech_rounded,
                        color: theme.colorScheme.secondary,
                        max: '99',
                        onTap: () => _editValue(
                          context,
                          title: '设置等级',
                          value: controller.level,
                          max: 99,
                          quickMaxLabel: '99 级',
                          onSet: controller.setLevel,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '队伍人数',
              icon: Icons.groups_rounded,
              trailing: InfoBadge('User ID  ${controller.userId}'),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1 人'), icon: Icon(Icons.person)),
                  ButtonSegment(value: 2, label: Text('2 人'), icon: Icon(Icons.group)),
                  ButtonSegment(value: 3, label: Text('3 人'), icon: Icon(Icons.group)),
                  ButtonSegment(value: 4, label: Text('4 人'), icon: Icon(Icons.groups)),
                ],
                selected: {controller.partyCount.clamp(1, 4)},
                onSelectionChanged: (s) => controller.setPartyCount(s.first),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '快捷操作',
              icon: Icons.flash_on_rounded,
              subtitle: '批量修改立即生效，导出前可随时在对应页面微调',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => controller.setGold(EditorController.maxGold),
                    icon: const Icon(Icons.paid_rounded, size: 18),
                    label: const Text('金币拉满'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => controller.setExp(EditorController.maxExp),
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: const Text('经验拉满'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => controller.setLevel(99),
                    icon: const Icon(Icons.military_tech_rounded, size: 18),
                    label: const Text('等级 99'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      controller.unlockAllStages();
                      showAppSnackBar(context, '已解锁全部 32 个关卡标记');
                    },
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('全关卡'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      controller.completeAllAchievements();
                      showAppSnackBar(context, '已完成全部成就（写入目标值）');
                    },
                    icon: const Icon(Icons.emoji_events_rounded, size: 18),
                    label: const Text('全成就'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      controller.unlockAllMedals();
                      showAppSnackBar(context, '已解锁全部勋章');
                    },
                    icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                    label: const Text('全勋章'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (stages.isNotEmpty)
              SectionCard(
                title: '存档信息',
                icon: Icons.info_outline_rounded,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoBadge('密文 ${controller.sourceString?.length ?? 0} 字符'),
                    InfoBadge('数据 ${controller.rawData?.length ?? 0} 值'),
                    InfoBadge('持有物品 ${controller.itemsTotal} 种'),
                    InfoBadge('技能点合计 ${controller.skillPoint(0) + controller.skillPoint(1) + controller.skillPoint(2) + controller.skillPoint(3)}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
