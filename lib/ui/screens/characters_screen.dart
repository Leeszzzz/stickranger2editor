import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/game_data.dart';
import '../../state/editor_controller.dart';
import '../../theme/pixel_theme.dart';
import '../widgets/common.dart';
import '../widgets/item_icon.dart';
import '../widgets/item_picker.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_kit.dart';

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

const List<PixelGlyphData> _charIcons = [
  PixelIcons.sword,
  PixelIcons.bolt,
  PixelIcons.spark,
  PixelIcons.star,
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
    if (!controller.hasSave) {
      return EmptyState(
        icon: PixelIcons.person,
        message: '载入存档后即可编辑 4 名角色的\n技能点 / HP / 属性加点 / 装备。',
        actionLabel: '去载入存档',
        onAction: () => AppDeps.of(context).navIndex.value = 0,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: PixelLayout.contentMax),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 24, 40),
          children: [
            WikiPageHeader(
              title: '角色档案',
              breadcrumb: const ['SR2 EDITOR', '角色档案'],
              icon: PixelIcons.person,
              subtitle:
                  '4 名角色的技能点、当前 HP、7 项属性加点与 5 个装备槽。'
                  '装备槽会按槽位过滤物品，长按槽位可清空。',
              tags: [
                PixelBadge(
                  '角色 ${_char + 1}',
                  tone: PixelBadgeTone.ink,
                  icon: _charIcons[_char],
                ),
                PixelBadge(
                  'HP ${controller.currentHp(_char)}',
                  tone: PixelBadgeTone.danger,
                ),
                PixelBadge(
                  '技能点 ${controller.skillPoint(_char)}',
                  tone: PixelBadgeTone.link,
                ),
              ],
            ),
            PixelTabs(
              selected: _char,
              onChanged: (i) => setState(() => _char = i),
              tabs: [
                for (var i = 0; i < 4; i++)
                  PixelTab('角色 ${i + 1}', icon: _charIcons[i]),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoCol = constraints.maxWidth >= 720;
                final basic = _BasicPanel(controller: controller, char: _char);
                final stats = _WeaponStatsPanel(
                  controller: controller,
                  char: _char,
                );
                if (!twoCol) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [basic, const SizedBox(height: 16), stats],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: basic),
                    const SizedBox(width: 16),
                    Expanded(child: stats),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _EquipmentPanel(controller: controller, char: _char),
            const SizedBox(height: 16),
            PixelCallout(
              message:
                  '属性加点上限：近战 / 中程 / 远程 / 物理 / 元素 / 未知 为 196，'
                  '闪避为 25。修改会立即写入内存，导出时统一编码。',
              icon: PixelIcons.info,
              tone: PixelBadgeTone.link,
              title: '加点规则',
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicPanel extends StatelessWidget {
  const _BasicPanel({required this.controller, required this.char});

  final EditorController controller;
  final int char;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return PixelPanel(
      title: '基础状态',
      icon: PixelIcons.heart,
      accent: p.gold,
      child: Column(
        children: [
          NumberField(
            label: '技能点（升级获得）',
            value: controller.skillPoint(char),
            min: 0,
            max: 4095,
            onChanged: (v) => controller.setSkillPoint(char, v),
            color: p.link,
          ),
          PixelDivider(color: p.border.withValues(alpha: 0.3)),
          NumberField(
            label: '当前 HP',
            value: controller.currentHp(char),
            min: 0,
            max: 262143,
            onChanged: (v) => controller.setCurrentHp(char, v),
            color: p.danger,
          ),
          const SizedBox(height: 8),
          PixelCallout(
            message: '技能点为升级获得的可用点数；当前 HP 是进入关卡时的初始生命值。',
            icon: PixelIcons.info,
            tone: PixelBadgeTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _WeaponStatsPanel extends StatelessWidget {
  const _WeaponStatsPanel({required this.controller, required this.char});

  final EditorController controller;
  final int char;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return PixelPanel(
      title: '属性加点',
      icon: PixelIcons.gear,
      accent: p.gold,
      child: Column(
        children: [
          for (var i = 0; i < weaponStatMeta.length; i++) ...[
            _StatRow(
              label: weaponStatMeta[i].$1,
              value: controller.weaponStat(char, i),
              max: weaponStatMeta[i].$2,
              onChanged: (v) => controller.setWeaponStat(char, i, v),
            ),
            if (i != weaponStatMeta.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
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
    final p = PixelPalette.of(context);
    final dodge = label == '闪避';
    final accent = dodge ? p.link : p.goldDeep;
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: label == '（未知属性）' ? p.inkFaint : p.inkSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: PixelSlider(
            value: value.toDouble(),
            min: 0,
            max: max.toDouble(),
            color: dodge ? p.link : p.gold,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: PixelFont.mono,
              fontFamilyFallback: PixelFont.fallback,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: value > 0 ? accent : p.inkFaint,
            ),
          ),
        ),
      ],
    );
  }
}

class _EquipmentPanel extends StatelessWidget {
  const _EquipmentPanel({required this.controller, required this.char});

  final EditorController controller;
  final int char;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return PixelPanel(
      title: '装备',
      subtitle: '点击槽位选择物品，长按清空；槽位只显示可装备的分类',
      icon: PixelIcons.shield,
      accent: p.gold,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth >= 640 ? 2 : 1;
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: cols == 2 ? 3.6 : 4.6,
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
}

class _SlotTile extends StatefulWidget {
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
  State<_SlotTile> createState() => _SlotTileState();
}

class _SlotTileState extends State<_SlotTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final catalog = EditorScope.read(context).catalog;
    final stats = catalog.itemStats(widget.itemId);
    final empty = widget.itemId == 0;
    final name = empty ? '空槽位' : catalog.itemName(widget.itemId);
    final dmg = stats?.damageType ?? 'Physical';
    final dmgColor = Color(damageTypeColors[dmg] ?? 0xFF8B949E);
    final showAt =
        stats != null &&
        stats.atMax > 0 &&
        (stats.typeCategory == 3 || stats.typeCategory == 4);

    return InkWell(
      onTap: widget.onTap,
      onLongPress: empty ? null : widget.onClear,
      onHover: (v) => setState(() => _hover = v),
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _hover ? p.panelAlt : p.paperAlt,
          border: Border.all(
            color: _hover ? p.gold : p.border,
            width: PixelSize.border,
          ),
        ),
        child: Row(
          children: [
            if (empty)
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.panel,
                  border: Border.all(color: p.border, width: 1),
                ),
                child: PixelGlyph(PixelIcons.plus, size: 16, color: p.inkFaint),
              )
            else
              ItemIcon(catalog: catalog, itemId: widget.itemId, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.meta.label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: p.inkSoft),
                  ),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: empty ? p.inkFaint : p.ink,
                    ),
                  ),
                ],
              ),
            ),
            if (showAt) ...[
              const SizedBox(width: 6),
              Text(
                'AT ${stats.atMin}-${stats.atMax}',
                style: TextStyle(
                  fontFamily: PixelFont.mono,
                  fontFamilyFallback: PixelFont.fallback,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
