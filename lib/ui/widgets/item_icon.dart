/// 物品像素图标：按 item_stats 的 icon 索引加载精灵图切块，
/// 无对应资产（特殊物品 0-3 / 未引用索引）时回退为分类首字徽章。
library;

import 'package:flutter/material.dart';

import '../../models/game_data.dart';
import '../../models/icon_assets.dart';
import '../../theme/pixel_theme.dart';

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
    final p = PixelPalette.of(context);
    final stats = catalog.itemStats(itemId);
    final iconIndex = stats?.icon;
    final hasAsset =
        iconIndex != null && kAvailableIconIndices.contains(iconIndex);
    final dmg = stats?.damageType ?? 'Physical';
    final dmgColor = Color(damageTypeColors[dmg] ?? 0xFF8B949E);
    final frame = BoxDecoration(
      color: Color.alphaBlend(dmgColor.withValues(alpha: 0.12), p.paperAlt),
      border: Border.all(color: p.border, width: 2),
    );

    if (hasAsset) {
      final tintColor =
          stats != null && stats.color > 0 && stats.color != 0xFFFFFF
          ? Color(0xFF000000 | stats.color)
          : null;
      Widget img = Image.asset(
        iconAssetPath(iconIndex),
        width: size * 0.74,
        height: size * 0.74,
        filterQuality: FilterQuality.none,
        fit: BoxFit.contain,
      );
      if (tintColor != null) {
        img = ColorFiltered(
          colorFilter: ColorFilter.mode(tintColor, BlendMode.modulate),
          child: img,
        );
      }
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: frame,
        child: img,
      );
    }

    // 回退：分类首字徽章（特殊物品 / 未引用图标）。
    final empty = itemId == 0;
    final catColor = _categoryColor(catalog.itemCategory(itemId), p);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: empty
          ? frame
          : frame.copyWith(
              color: Color.alphaBlend(
                catColor.withValues(alpha: 0.18),
                p.paperAlt,
              ),
            ),
      child: empty
          ? Text(
              '—',
              style: TextStyle(
                fontFamily: PixelFont.mono,
                fontFamilyFallback: PixelFont.fallback,
                fontSize: size * 0.5,
                fontWeight: FontWeight.w700,
                color: p.inkFaint,
              ),
            )
          : Text(
              catalog.categoryLabel(itemId).characters.first,
              style: TextStyle(
                fontFamily: PixelFont.family,
                fontFamilyFallback: PixelFont.fallback,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
    );
  }

  static Color _categoryColor(String category, PixelPalette p) {
    return switch (category) {
      'Weapon' => p.danger,
      'Skill' => p.link,
      'Hat' => p.success,
      'Ring' => p.gold,
      'Amulet' => p.info,
      _ => p.inkSoft,
    };
  }
}
