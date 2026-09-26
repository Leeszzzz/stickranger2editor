import 'package:flutter/material.dart';

import '../../main.dart';
import '../../state/editor_controller.dart';
import '../widgets/common.dart';
import '../widgets/item_icon.dart';

const List<String> _categoryChips = [
  '全部',
  '拳套',
  '剑',
  '枪',
  '弓',
  '杖',
  '技能',
  '帽子',
  '戒指',
  '护符',
];

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _query = '';
  int _category = 0;
  bool _ownedOnly = false;

  List<int> _filtered(EditorController controller) {
    final catalog = controller.catalog;
    final chip = _categoryChips[_category];
    final q = _query.trim().toLowerCase();
    final result = <int>[];
    for (final id in catalog.items.keys.toList()..sort()) {
      final count = controller.itemCount(id);
      if (_ownedOnly && count == 0) continue;
      if (chip != '全部' && catalog.categoryLabel(id) != chip) continue;
      if (q.isNotEmpty) {
        final name = catalog.itemName(id).toLowerCase();
        if (!name.contains(q) && !'$id'.contains(q)) continue;
      }
      result.add(id);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    final theme = Theme.of(context);
    if (!controller.hasSave) {
      return EmptyState(
        icon: Icons.backpack_outlined,
        message: '载入存档后即可编辑 256 格背包（每格 0-63）',
        actionLabel: '去载入存档',
        onAction: () => AppDeps.of(context).navIndex.value = 0,
      );
    }

    final filtered = _filtered(controller);
    final ownedCount = filtered.where((id) => controller.itemCount(id) > 0).length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search, size: 20),
                            hintText: '搜索物品名称或 ID…',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilterChip(
                        label: const Text('只看已有'),
                        selected: _ownedOnly,
                        onSelected: (v) => setState(() => _ownedOnly = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (var i = 0; i < _categoryChips.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              // CanvasKit 下部分中文字形测量宽 < 绘制宽，
                              // 禁止按测量框裁剪，避免「弓」「杖」右半被切。
                              label: Text(
                                _categoryChips[i],
                                overflow: TextOverflow.visible,
                              ),
                              selected: _category == i,
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) => setState(() => _category = i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  Text(
                    '筛选结果 ${filtered.length} 种 · 已有 $ownedCount 种',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: filtered.isEmpty
                        ? null
                        : () {
                            final missing = filtered
                                .where((id) => controller.itemCount(id) == 0)
                                .toSet();
                            if (missing.isEmpty) {
                              showAppSnackBar(context, '当前列表内没有未拥有的物品');
                              return;
                            }
                            controller.fillInventory(missing, count: 1);
                            showAppSnackBar(context, '已添加 ${missing.length} 件未拥有物品');
                          },
                    icon: const Icon(Icons.playlist_add_rounded, size: 18),
                    label: const Text('添加未拥有'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await _confirm(
                        context,
                        '清空全部背包？',
                        '256 格物品数量全部归零，导出后生效。',
                      );
                      if (ok == true) {
                        controller.clearInventory();
                        if (context.mounted) showAppSnackBar(context, '背包已清空');
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('清空全部'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        '没有匹配的物品',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, i) => _InventoryTile(
                        itemId: filtered[i],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirm(BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = EditorScope.watch(context);
    final catalog = controller.catalog;
    final count = controller.itemCount(itemId);
    final stats = catalog.itemStats(itemId);
    final name = catalog.itemName(itemId);
    final showStats = stats != null && stats.atMax > 0;
    // 武器 / 技能类物品的数量格存的是等级：0 = 未获取，1+ = 等级。
    final isLevel = stats != null &&
        (stats.typeCategory == 3 || stats.typeCategory == 4);
    final countLabel = isLevel ? 'Lv.$count' : '×$count';

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEditor(context, controller),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ItemIcon(catalog: catalog, itemId: itemId, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InfoBadge('ID $itemId'),
                      ],
                    ),
                    if (showStats)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'AT ${stats.atMin}-${stats.atMax}'
                          ' · AGI ${stats.agi}'
                          ' · RANGE ${stats.range}'
                          ' · Lv.cap ${stats.lvCap}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFeatures: tabularFigures,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CountStepper(
                count: count,
                countLabel: countLabel,
                onChanged: (v) => controller.setItemCount(itemId, v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, EditorController controller) {
    final catalog = controller.catalog;
    final stats = catalog.itemStats(itemId);
    final isLevel = stats != null &&
        (stats.typeCategory == 3 || stats.typeCategory == 4);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${catalog.itemName(itemId)}（ID $itemId）',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLevel
                      ? '拖动滑块设置等级（0 = 未获取，1+ = 等级）'
                      : '拖动滑块设置持有数量（0-63）',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                        color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    final v = controller.itemCount(itemId);
                    return Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: v.toDouble(),
                            max: 63,
                            divisions: 63,
                            label: isLevel ? 'Lv.$v' : '$v',
                            onChanged: (nv) =>
                                controller.setItemCount(itemId, nv.round()),
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          child: Text(
                            isLevel ? 'Lv.$v' : '×$v',
                            textAlign: TextAlign.center,
                            style: Theme.of(sheetContext)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontFeatures: tabularFigures,
                                  fontWeight: FontWeight.w700,
                                  color: v > 0
                                      ? Theme.of(sheetContext).colorScheme.primary
                                      : Theme.of(sheetContext).colorScheme.outline,
                                ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.count,
    required this.countLabel,
    required this.onChanged,
  });

  final int count;
  final String countLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = count > 0 ? theme.colorScheme.primary : theme.colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: count > 0 ? () => onChanged(count - 1) : null,
          icon: const Icon(Icons.remove_circle_outline, size: 20),
        ),
        SizedBox(
          width: 44,
          child: Text(
            countLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontFeatures: tabularFigures,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: count < 63 ? () => onChanged(count + 1) : null,
          icon: const Icon(Icons.add_circle_outline, size: 20),
        ),
      ],
    );
  }
}
