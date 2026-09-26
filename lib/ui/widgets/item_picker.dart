/// 物品选择对话框：按槽位过滤 + 搜索。
library;

import 'package:flutter/material.dart';

import '../../models/game_data.dart';
import 'common.dart';
import 'item_icon.dart';

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
  return showDialog<int>(
    context: context,
    builder: (_) => _ItemPickerDialog(catalog: catalog, slot: slot, title: title),
  );
}

class _ItemPickerDialog extends StatefulWidget {
  const _ItemPickerDialog({
    required this.catalog,
    required this.slot,
    required this.title,
  });

  final GameCatalog catalog;
  final SlotMeta? slot;
  final String title;

  @override
  State<_ItemPickerDialog> createState() => _ItemPickerDialogState();
}

class _ItemPickerDialogState extends State<_ItemPickerDialog> {
  String _query = '';
  late final List<String> _subtypes;

  @override
  void initState() {
    super.initState();
    final accepted = widget.slot?.accepted;
    if (accepted != null && accepted.contains('Weapon')) {
      _subtypes = ['全部', '拳套', '剑', '枪', '弓', '杖'];
    } else {
      _subtypes = const ['全部'];
    }
  }

  int _selectedSubtype = 0;

  List<int> get _filtered {
    final cat = widget.slot?.accepted;
    final q = _query.trim().toLowerCase();
    final result = <int>[];
    for (final id in widget.catalog.items.keys.toList()..sort()) {
      final category = widget.catalog.itemCategory(id);
      if (cat != null && !cat.contains(category)) continue;
      if (_subtypes.length > 1 && _selectedSubtype > 0) {
        if (widget.catalog.weaponSubtype(id) != _subtypes[_selectedSubtype]) {
          continue;
        }
      }
      if (q.isNotEmpty) {
        final name = widget.catalog.itemName(id).toLowerCase();
        if (!name.contains(q) && !'$id'.contains(q)) continue;
      }
      result.add(id);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filtered;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, size: 20),
                        hintText: '搜索名称或 ID…',
                      ),
                    ),
                  ),
                ],
              ),
              if (_subtypes.length > 1) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (var i = 0; i < _subtypes.length; i++)
                      ChoiceChip(
                        label: Text(
                          _subtypes[i],
                          overflow: TextOverflow.visible,
                        ),
                        selected: _selectedSubtype == i,
                        onSelected: (_) => setState(() => _selectedSubtype = i),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                leading: Icon(Icons.block_rounded, color: theme.colorScheme.outline),
                title: const Text('空（NONE）'),
                onTap: () => Navigator.of(context).pop(0),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          '没有匹配的物品',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) =>
                            _ItemTile(catalog: widget.catalog, itemId: items[i]),
                      ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${items.length} 项',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.catalog, required this.itemId});

  final GameCatalog catalog;
  final int itemId;

  @override
  Widget build(BuildContext context) {
    final stats = catalog.itemStats(itemId);
    final name = catalog.itemName(itemId);
    final dmg = stats?.damageType ?? 'Physical';
    final dmgColor = Color(damageTypeColors[dmg] ?? 0xFF8B949E);
    final isWeapon = stats != null && stats.typeCategory == 3;
    final subtitleParts = <String>[
      if (stats != null && (isWeapon || stats.typeCategory == 4))
        'AT ${stats.atMin}-${stats.atMax}',
      if (stats != null && stats.agi > 0) 'AGI ${stats.agi}',
      if (stats != null && stats.range > 0) 'RANGE ${stats.range}',
      if (stats != null && stats.lvCap > 0) 'Lv.cap ${stats.lvCap}',
    ];

    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: ItemIcon(catalog: catalog, itemId: itemId, size: 36),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: subtitleParts.isEmpty
          ? null
          : Text(
              subtitleParts.join(' · '),
              style: const TextStyle(fontSize: 12, fontFeatures: tabularFigures),
            ),
      trailing: dmgColor != const Color(0xFF8B949E)
          ? InfoBadge(damageTypeLabels[dmg] ?? dmg, color: dmgColor)
          : null,
      onTap: () => Navigator.of(context).pop(itemId),
    );
  }
}
