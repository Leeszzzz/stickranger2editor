import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/game_data.dart';
import '../../state/editor_controller.dart';
import '../../theme/pixel_theme.dart';
import '../widgets/common.dart';
import '../widgets/item_icon.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_kit.dart';

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
    final p = PixelPalette.of(context);
    if (!controller.hasSave) {
      return EmptyState(
        icon: PixelIcons.bag,
        message: '载入存档后即可编辑 256 格背包。\n物品以等级记录，0 级表示未获取。',
        actionLabel: '去载入存档',
        onAction: () => AppDeps.of(context).navIndex.value = 0,
      );
    }

    final filtered = _filtered(controller);
    final ownedCount = filtered
        .where((id) => controller.itemCount(id) > 0)
        .length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: PixelLayout.contentMax),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: WikiPageHeader(
                  title: '物品数据库',
                  breadcrumb: const ['SR2 EDITOR', '物品数据库'],
                  icon: PixelIcons.bag,
                  subtitle:
                      '256 格背包的完整索引。所有物品以等级记录：'
                      '0 级表示未获取，1 级及以上表示当前等级。',
                  tags: [
                    PixelBadge(
                      '持有 ${controller.itemsTotal} 种',
                      tone: PixelBadgeTone.gold,
                    ),
                    PixelBadge(
                      '数据库 ${controller.catalog.itemCount} 种',
                      tone: PixelBadgeTone.neutral,
                    ),
                    const PixelBadge('256 格', tone: PixelBadgeTone.link),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 24, 12),
              sliver: SliverToBoxAdapter(
                child: _Toolbar(
                  controller: controller,
                  query: _query,
                  category: _category,
                  ownedOnly: _ownedOnly,
                  filtered: filtered.length,
                  owned: ownedCount,
                  onQuery: (v) => setState(() => _query = v),
                  onCategory: (i) => setState(() => _category = i),
                  onOwnedOnly: (v) => setState(() => _ownedOnly = v),
                  onFillMissing: filtered.isEmpty
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
                          showAppSnackBar(
                            context,
                            '已添加当前页面 ${missing.length} 件未拥有物品',
                          );
                        },
                  onClear: () => _confirmClear(context, controller),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _TableHeader(
                  compact: MediaQuery.sizeOf(context).width < 760,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 24, 20),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) => _InventoryRow(
                  itemId: filtered[i],
                  last: i == filtered.length - 1,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 24, 40),
              sliver: SliverToBoxAdapter(
                child: filtered.isEmpty
                    ? PixelPanel(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              '没有匹配的物品',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: p.inkSoft),
                            ),
                          ),
                        ),
                      )
                    : _Legend(total: filtered.length, owned: ownedCount),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    EditorController controller,
  ) async {
    final ok = await showPixelDialog<bool>(
      context: context,
      title: '清空全部背包？',
      icon: PixelIcons.trash,
      maxWidth: 400,
      child: const Text(
        '256 格物品等级将全部归零，导出后才会写入游戏。此操作可以在导出前重新调整。',
        style: TextStyle(height: 1.7),
      ),
      actions: [
        PixelButton(
          label: '取消',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PixelButton(
          label: '清空',
          icon: PixelIcons.trash,
          tone: PixelButtonTone.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (ok == true) {
      controller.clearInventory();
      if (context.mounted) showAppSnackBar(context, '背包已清空');
    }
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.query,
    required this.category,
    required this.ownedOnly,
    required this.filtered,
    required this.owned,
    required this.onQuery,
    required this.onCategory,
    required this.onOwnedOnly,
    required this.onFillMissing,
    required this.onClear,
  });

  final EditorController controller;
  final String query;
  final int category;
  final bool ownedOnly;
  final int filtered;
  final int owned;
  final ValueChanged<String> onQuery;
  final ValueChanged<int> onCategory;
  final ValueChanged<bool> onOwnedOnly;
  final VoidCallback? onFillMissing;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return PixelPanel(
      title: '检索与筛选',
      icon: PixelIcons.search,
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 620;
              final search = PixelTextField(
                hint: '搜索物品名称或 ID…',
                prefixIcon: PixelIcons.search,
                onChanged: onQuery,
              );
              final ownedToggle = _OwnedToggle(
                value: ownedOnly,
                onChanged: onOwnedOnly,
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ownedToggle,
                        const Spacer(),
                        Text(
                          '$filtered 种 · 已有 $owned',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: p.inkSoft),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 10),
                  ownedToggle,
                  const SizedBox(width: 12),
                  Text(
                    '$filtered 种 · 已有 $owned',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: p.inkSoft),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _categoryChips.length; i++)
                PixelChip(
                  label: _categoryChips[i],
                  dense: true,
                  selected: category == i,
                  onTap: () => onCategory(i),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PixelButton(
                label: '添加当前页面未拥有',
                icon: PixelIcons.plus,
                size: PixelButtonSize.small,
                onPressed: onFillMissing,
              ),
              PixelButton(
                label: '清空全部',
                icon: PixelIcons.trash,
                size: PixelButtonSize.small,
                tone: PixelButtonTone.danger,
                onPressed: onClear,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnedToggle extends StatelessWidget {
  const _OwnedToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixelCheckbox(value: value, onChanged: onChanged),
          const SizedBox(width: 6),
          Text(
            '只看已有',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PixelPalette.of(context).inkSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: p.panelAlt,
        border: Border(
          top: BorderSide(color: p.border, width: PixelSize.border),
          left: BorderSide(color: p.border, width: PixelSize.border),
          right: BorderSide(color: p.border, width: PixelSize.border),
          bottom: BorderSide(color: p.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 36),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              '物品 / ID',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: p.inkSoft,
                letterSpacing: 0.6,
              ),
            ),
          ),
          if (!compact)
            Expanded(
              flex: 5,
              child: Text(
                '属性',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: p.inkSoft,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          SizedBox(
            width: compact ? 96 : 132,
            child: Text(
              '等级',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: p.inkSoft,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryRow extends StatefulWidget {
  const _InventoryRow({required this.itemId, required this.last});

  final int itemId;
  final bool last;

  @override
  State<_InventoryRow> createState() => _InventoryRowState();
}

class _InventoryRowState extends State<_InventoryRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final controller = EditorScope.watch(context);
    final catalog = controller.catalog;
    final count = controller.itemCount(widget.itemId);
    final stats = catalog.itemStats(widget.itemId);
    final name = catalog.itemName(widget.itemId);
    final countLabel = 'Lv.$count';
    final compact = MediaQuery.sizeOf(context).width < 760;
    final showStats = stats != null && stats.atMax > 0;

    return InkWell(
      onTap: () => _openSheet(context, controller),
      onHover: (v) => setState(() => _hover = v),
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: _hover
              ? p.goldSoft
              : (count > 0 ? p.panel : p.panel.withValues(alpha: 0.72)),
          border: Border(
            left: BorderSide(color: p.border, width: PixelSize.border),
            right: BorderSide(color: p.border, width: PixelSize.border),
            bottom: BorderSide(
              color: p.border,
              width: widget.last ? PixelSize.border : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            ItemIcon(catalog: catalog, itemId: widget.itemId, size: 36),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: count > 0 ? p.ink : p.inkSoft,
                              ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InfoBadge('#${widget.itemId}'),
                    ],
                  ),
                  if (compact && showStats)
                    Text(
                      'AT ${stats.atMin}-${stats.atMax} · AGI ${stats.agi} · Lv.cap ${stats.lvCap}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: PixelFont.mono,
                        fontFamilyFallback: PixelFont.fallback,
                        fontSize: 12,
                        height: 1.4,
                        color: p.inkFaint,
                      ),
                    ),
                ],
              ),
            ),
            if (!compact)
              Expanded(
                flex: 5,
                child: showStats
                    ? Text(
                        'AT ${stats.atMin}-${stats.atMax}  ·  AGI ${stats.agi}  ·  '
                        'RANGE ${stats.range}  ·  Lv.cap ${stats.lvCap}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: PixelFont.mono,
                          fontFamilyFallback: PixelFont.fallback,
                          fontSize: 12,
                          height: 1.4,
                          color: p.inkFaint,
                        ),
                      )
                    : Text(
                        catalog.categoryLabel(widget.itemId),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: p.inkFaint),
                      ),
              ),
            SizedBox(
              width: compact ? 96 : 132,
              child: _CountStepper(
                count: count,
                label: countLabel,
                compact: compact,
                onChanged: (v) => controller.setItemCount(widget.itemId, v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, EditorController controller) {
    showPixelSheet<void>(
      context: context,
      child: _ItemSheet(itemId: widget.itemId, controller: controller),
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.count,
    required this.label,
    required this.onChanged,
    required this.compact,
  });

  final int count;
  final String label;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final accent = count > 0 ? p.goldDeep : p.inkFaint;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        PixelIconButton(
          icon: PixelIcons.minus,
          tooltip: '减少',
          size: PixelButtonSize.small,
          onPressed: count > 0 ? () => onChanged(count - 1) : null,
        ),
        SizedBox(
          width: compact ? 36 : 44,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: PixelFont.mono,
              fontFamilyFallback: PixelFont.fallback,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
        PixelIconButton(
          icon: PixelIcons.plus,
          tooltip: '增加',
          size: PixelButtonSize.small,
          onPressed: count < 63 ? () => onChanged(count + 1) : null,
        ),
      ],
    );
  }
}

class _ItemSheet extends StatelessWidget {
  const _ItemSheet({required this.itemId, required this.controller});

  final int itemId;
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final catalog = controller.catalog;
    final stats = catalog.itemStats(itemId);
    final name = catalog.itemName(itemId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            ItemIcon(catalog: catalog, itemId: itemId, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      InfoBadge('#$itemId'),
                      PixelBadge(
                        catalog.categoryLabel(itemId),
                        tone: PixelBadgeTone.gold,
                      ),
                      const PixelBadge('等级语义', tone: PixelBadgeTone.link),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        PixelPanel(
          title: '物品属性',
          icon: PixelIcons.book,
          dense: true,
          shadow: false,
          child: PixelInfoTable(
            labelWidth: 70,
            rows: [
              PixelInfoRow(
                '伤害类型',
                stats == null
                    ? '—'
                    : '${damageTypeLabels[stats.damageType] ?? '物理'}'
                          ' / ${stats.damageType}',
              ),
              if (stats != null) ...[
                PixelInfoRow(
                  '攻击力',
                  '${stats.atMin} — ${stats.atMax}',
                  mono: true,
                ),
                PixelInfoRow('弹数', '${stats.bullets}', mono: true),
                PixelInfoRow('AGI', '${stats.agi}', mono: true),
                PixelInfoRow('射程', '${stats.range}', mono: true),
                if (stats.hp > 0) PixelInfoRow('HP', '${stats.hp}', mono: true),
                if (stats.sp > 0) PixelInfoRow('SP', '${stats.sp}', mono: true),
                PixelInfoRow('等级上限', '${stats.lvCap}', mono: true),
                PixelInfoRow('购买价格', '${stats.cost}', mono: true),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        PixelPanel(
          title: '等级设置',
          icon: PixelIcons.gear,
          dense: true,
          shadow: false,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final v = controller.itemCount(itemId);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: PixelSlider(
                          value: v.toDouble(),
                          min: 0,
                          max: 63,
                          onChanged: (nv) =>
                              controller.setItemCount(itemId, nv.round()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 60,
                        child: Text(
                          'Lv.$v',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: PixelFont.mono,
                            fontFamilyFallback: PixelFont.fallback,
                            fontSize: PixelSize.valueCompact,
                            fontWeight: FontWeight.w700,
                            color: v > 0 ? p.goldDeep : p.inkFaint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '0 = 未获取，1+ = 等级；上限 63',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: p.inkSoft),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PixelButton(
                        label: '设为 0',
                        icon: PixelIcons.trash,
                        size: PixelButtonSize.small,
                        onPressed: () => controller.setItemCount(itemId, 0),
                      ),
                      PixelButton(
                        label: '设为 63 级',
                        icon: PixelIcons.chevronUp,
                        size: PixelButtonSize.small,
                        tone: PixelButtonTone.gold,
                        onPressed: () => controller.setItemCount(itemId, 63),
                      ),
                      PixelButton(
                        label: '完成',
                        icon: PixelIcons.check,
                        size: PixelButtonSize.small,
                        tone: PixelButtonTone.primary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.total, required this.owned});

  final int total;
  final int owned;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return PixelPanel(
      dense: true,
      child: Row(
        children: [
          PixelGlyph(PixelIcons.info, size: 16, color: p.link, accent: p.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '当前筛选 $total 种，其中已有 $owned 种。点击任意行可打开物品详情与滑块。',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: p.inkSoft, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
