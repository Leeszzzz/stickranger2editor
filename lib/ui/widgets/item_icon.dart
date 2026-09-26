/// 物品像素图标：按 item_stats 的 icon 索引加载精灵图切块，
/// 无对应资产（特殊物品 0-3 / 未引用索引）时回退为分类首字徽章。
library;

import 'package:flutter/material.dart';

import '../../models/game_data.dart';
import '../../models/icon_assets.dart';

class ItemIcon extends StatelessWidget {
  const ItemIcon({
    super.key,
    required this.catalog,
    required this.itemId,
    this.size = 36,
  });

  final GameCatalog catalog;
  final int itemId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = catalog.itemStats(itemId);
    final iconIndex = stats?.icon;
    final hasAsset =
        iconIndex != null && kAvailableIconIndices.contains(iconIndex);

    if (hasAsset) {
      final dmg = stats?.damageType ?? 'Physical';
      final dmgColor = Color(damageTypeColors[dmg] ?? 0xFF8B949E);
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dmgColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(size * 0.24),
        ),
        child: Image.asset(
          iconAssetPath(iconIndex),
          width: size * 0.82,
          height: size * 0.82,
          filterQuality: FilterQuality.none,
          fit: BoxFit.contain,
        ),
      );
    }

    // 回退：分类首字徽章（特殊物品 / 未引用图标）。
    final empty = itemId == 0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: empty
          ? Icon(Icons.block_rounded,
              size: size * 0.5, color: theme.colorScheme.outline)
          : Text(
              catalog.categoryLabel(itemId).characters.first,
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }
}
