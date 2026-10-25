/// 物品选择对话框：像素百科风格的物品检索面板。
library;

import 'package:flutter/material.dart';

import '../../models/game_data.dart';
import '../../theme/pixel_theme.dart';
import 'item_icon.dart';
import 'pixel_icons.dart';
import 'pixel_kit.dart';

/// 装备槽定义（与存档 ac[4][8] 对应）。
class SlotMeta {
  const SlotMeta(this.index, this.label, this.accepted);
  final int index;
  final String label;

  /// 该槽位允许的物品分类（null = 全部）。
  final Set<String>? accepted;
}

const List<SlotMeta> slotMeta = [
  SlotMeta(0, '主手武器', {'Weapon'}),
  SlotMeta(1, '副手技能', {'Skill'}),
  SlotMeta(2, '头盔', {'Hat'}),
  SlotMeta(3, '戒指', {'Ring'}),
  SlotMeta(4, '护符', {'Amulet'}),
];

/// 弹出物品选择器，返回物品 id（0 = 清空）或 null（取消）。
Future<int?> showItemPicker(
  BuildContext context, {
  required GameCatalog catalog,
  SlotMeta? slot,
  String title = '选择物品',
}) {
  return showPixelDialog<int>(
    context: context,
    title: title,
    icon: PixelIcons.bag,
    subtitle: slot == null ? '检索物品数据库' : '只显示可放入「${slot.label}」的物品',
    maxWidth: 680,
    child: _ItemPickerBody(catalog: catalog, slot: slot),
    actions: [
      PixelButton(
        label: '清空槽位',
        icon: PixelIcons.trash,
        tone: PixelButtonTone.danger,
        onPressed: () => Navigator.of(context).pop(0),
      ),
      PixelButton(label: '取消', onPressed: () => Navigator.of(context).pop()),
    ],
  );
}

class _ItemPickerBody extends StatefulWidget {
  const _ItemPickerBody({required this.catalog, required this.slot});

  final GameCatalog catalog;
  final SlotMeta? slot;

  @override
  State<_ItemPickerBody> createState() => _ItemPickerBodyState();
}

class _ItemPickerBodyState extends State<_ItemPickerBody> {
  String _query = '';
  String _subtype = '全部';

  static const _weaponTypes = ['全部', '拳套', '剑', '枪', '弓', '杖'];

  bool get _isWeaponSlot => widget.slot?.accepted?.contains('Weapon') ?? false;

  List<int> _filtered() {
    final catalog = widget.catalog;
    final accepted = widget.slot?.accepted;
    final q = _query.trim().toLowerCase();
    final ids = <int>[];
    for (final id in catalog.items.keys.toList()..sort()) {
      final cat = catalog.itemCategory(id);
      if (accepted != null && !accepted.contains(cat)) continue;
      if (_subtype != '全部' && catalog.categoryLabel(id) != _subtype) continue;
      if (q.isNotEmpty) {
        final name = catalog.itemName(id).toLowerCase();
        if (!name.contains(q) && !'$id'.contains(q)) continue;
      }
      ids.add(id);
    }
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final items = _filtered();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelTextField(
          hint: '搜索物品名称或 ID…',
          prefixIcon: PixelIcons.search,
          onChanged: (v) => setState(() => _query = v),
        ),
        if (_isWeaponSlot) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final type in _weaponTypes)
                PixelChip(
                  label: type,
                  dense: true,
                  selected: _subtype == type,
                  onTap: () => setState(() => _subtype = type),
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              '共 ${items.length} 件',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: p.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '按 ID 排序',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: p.inkFaint),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 380,
          decoration: BoxDecoration(
            border: Border.all(color: p.border, width: 1),
          ),
          child: items.isEmpty
              ? Center(
                  child: Text(
                    '没有匹配的物品',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: p.inkSoft),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(6),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 210,
                    mainAxisExtent: 56,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      _ItemTile(catalog: widget.catalog, itemId: items[i]),
                ),
        ),
      ],
    );
  }
}

class _ItemTile extends StatefulWidget {
  const _ItemTile({required this.catalog, required this.itemId});

  final GameCatalog catalog;
  final int itemId;

  @override
  State<_ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<_ItemTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final stats = widget.catalog.itemStats(widget.itemId);
    return InkWell(
      onTap: () => Navigator.of(context).pop(widget.itemId),
      onHover: (v) => setState(() => _hover = v),
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: _hover ? p.goldSoft : p.paperAlt,
          border: Border.all(color: _hover ? p.gold : p.border, width: 1),
        ),
        child: Row(
          children: [
            ItemIcon(catalog: widget.catalog, itemId: widget.itemId, size: 32),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.catalog.itemName(widget.itemId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    stats == null
                        ? 'ID ${widget.itemId}'
                        : '#${widget.itemId} · ${widget.catalog.categoryLabel(widget.itemId)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: PixelFont.mono,
                      fontFamilyFallback: PixelFont.fallback,
                      fontSize: 12,
                      height: 1.3,
                      color: p.inkFaint,
                    ),
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
