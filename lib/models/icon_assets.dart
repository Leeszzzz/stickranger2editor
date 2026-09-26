/// item.png 精灵图切块的可用索引（由 images/items 切片脚本生成）。
///
/// 索引 = 行*16 + 列，对应 ranger2.js r[] 数组的 Pc 字段（icon）。
const Set<int> kAvailableIconIndices = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 18, 19, 20, 21, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 96, 97, 98, 99, 100, 101, 102, 103, 112, 113, 114, 128, 144, 145};

String iconAssetPath(int iconIndex) =>
    'assets/icons/icon_${iconIndex.clamp(0, 255).toString().padLeft(3, '0')}.png';
