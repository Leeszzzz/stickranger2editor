import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/game_data.dart';
import '../../state/editor_controller.dart';
import '../widgets/common.dart';
import '../widgets/item_icon.dart';
import '../widgets/item_picker.dart';

/// 属性加点（wb）7 个方向，闪避上限 25，其余 196。
const List<(String, int)> weaponStatMeta = [
  ('近战强化', 196),
  ('中程强化', 196),
  ('远程强化', 196),
  ('物理强化', 196),
  ('元素强化', 196),
  ('（未知属性）', 196),
  ('闪避', 25),
];

class CharactersScreen extends StatefulWidget {
  const CharactersScreen({super.key});

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  int _char = 0;

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    final theme = Theme.of(context);
    if (!controller.hasSave) {
      return EmptyState(
        icon: Icons.person_outline,
        message: '载入存档后即可编辑 4 名角色的\n技能点 / HP / 属性加点 / 装备',
        actionLabel: '去载入存档',
        onAction: () => AppDeps.of(context).navIndex.value = 0,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            SegmentedButton<int>(
              segments: [
                for (var i = 0; i < 4; i++)
                  ButtonSegment(
                    value: i,
                    label: Text('角色 ${i + 1}'),
                    icon: _charIcon(i),
                  ),
              ],
              selected: {_char},
              onSelectionChanged: (s) => setState(() => _char = s.first),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoCol = constraints.maxWidth >= 640;
                final basic = SectionCard(
                  title: '基础状态',
                  icon: Icons.favorite_rounded,
                  child: Column(
                    children: [
                      NumberField(
                        label: '技能点（升级获得）',
                        value: controller.skillPoint(_char),
                        min: 0,
                        max: 4095,
                        onChanged: (v) => controller.setSkillPoint(_char, v),
                        color: theme.colorScheme.secondary,
                      ),
                      const Divider(),
                      NumberField(
                        label: '当前 HP',
                        value: controller.currentHp(_char),
                        min: 0,
                        max: 262143,
                        onChanged: (v) => controller.setCurrentHp(_char, v),
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                );
                final weapons = SectionCard(
                  title: '属性加点',
                  icon: Icons.tune_rounded,
                  child: Column(
                    children: [
                      for (var i = 0; i < weaponStatMeta.length; i++)
                        _WeaponStatRow(
                          label: weaponStatMeta[i].$1,
                          max: weaponStatMeta[i].$2,
                          value: controller.weaponStat(_char, i),
                          onChanged: (v) => controller.setWeaponStat(_char, i, v),
                        ),
                    ],
                  ),
                );
                return twoCol
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: basic),
                          const SizedBox(width: 12),
                          Expanded(child: weapons),
                        ],
                      )
                    : Column(
                        children: [
                          basic,
                          const SizedBox(height: 12),
                          weapons,
                        ],
                      );
              },
            ),
            const SizedBox(height: 12),
            _EquipmentCard(controller: controller, char: _char),
          ],
        ),
      ),
    );
  }

  Widget? _charIcon(int i) {
    const icons = [
      Icons.sports_martial_arts_rounded,
      Icons.bolt_rounded,
      Icons.bubble_chart_rounded,
      Icons.auto_fix_high_rounded,
    ];
    return Icon(icons[i], size: 18);
  }
}

class _WeaponStatRow extends StatelessWidget {
  const _WeaponStatRow({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = label == '闪避'
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: label == '（未知属性）'
                  ? theme.colorScheme.outline
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            max: max.toDouble(),
            divisions: max,
            label: '$value',
            activeColor: accent,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: theme.textTheme.titleSmall?.copyWith(
              fontFeatures: tabularFigures,
              fontWeight: FontWeight.w700,
              color: value > 0 ? accent : theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({required this.controller, required this.char});

  final EditorController controller;
  final int char;

  Future<void> _pickSlot(BuildContext context, int slot) async {
    final meta = slotMeta[slot];
    final current = controller.equipment(char, slot);
    final picked = await showItemPicker(
      context,
      catalog: controller.catalog,
      slot: meta,
      title: '角色 ${char + 1} · ${meta.label}',
    );
    if (picked != null && picked != current) {
      controller.setEquipment(char, slot, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '装备',
      icon: Icons.shield_rounded,
      subtitle: '点击槽位选择物品，长按清空',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth >= 640 ? 2 : 1;
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: cols == 2 ? 3.4 : 4.4,
            children: [
              for (final meta in slotMeta)
                _SlotTile(
                  meta: meta,
                  itemId: controller.equipment(char, meta.index),
                  onTap: () => _pickSlot(context, meta.index),
                  onClear: () => controller.setEquipment(char, meta.index, 0),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.meta,
    required this.itemId,
    required this.onTap,
    required this.onClear,
  });

  final SlotMeta meta;
  final int itemId;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = EditorScope.read(context).catalog;
    final stats = catalog.itemStats(itemId);
    final empty = itemId == 0;
    final name = empty ? '空' : catalog.itemName(itemId);
    final dmg = stats?.damageType ?? 'Physical';
    final dmgColor = Color(damageTypeColors[dmg] ?? 0xFF8B949E);
    final showAt = stats != null &&
        stats.atMax > 0 &&
        (stats.typeCategory == 3 || stats.typeCategory == 4);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      onLongPress: empty ? null : onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            empty
                ? Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add,
                        size: 18, color: theme.colorScheme.outline),
                  )
                : ItemIcon(
                    catalog: EditorScope.read(context).catalog,
                    itemId: itemId,
                    size: 34,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    meta.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: empty ? theme.colorScheme.outline : null,
                    ),
                  ),
                ],
              ),
            ),
            if (showAt) ...[
              const SizedBox(width: 6),
              Text(
                'AT ${stats.atMin}-${stats.atMax}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFeatures: tabularFigures,
                  color: dmgColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
