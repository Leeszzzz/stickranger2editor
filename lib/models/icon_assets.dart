/// 精灵图切块可用索引（由切片脚本生成）。
///
/// - kAvailableIconIndices: item.png 物品图标（索引 = 行*16+列）
/// - kAvailableMedalIcons: medal.png 成就奖章（索引 = 行*5+列，20x20）
/// - kAvailableEnemyFaces: en.png 怪物脸谱（索引 = 行*8+列，16x16）
const Set<int> kAvailableIconIndices = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 18, 19, 20, 21, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 96, 97, 98, 99, 100, 101, 102, 103, 112, 113, 114, 128, 144, 145};

const Set<int> kAvailableMedalIcons = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};

const Set<int> kAvailableEnemyFaces = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 24};

String iconAssetPath(int iconIndex) =>
    'assets/icons/icon_${iconIndex.clamp(0, 255).toString().padLeft(3, '0')}.png';

String medalAssetPath(int iconId) =>
    'assets/icons/medal_${iconId.clamp(0, 49).toString().padLeft(2, '0')}.png';

String enemyAssetPath(int faceIndex) =>
    'assets/icons/enemy_${faceIndex.clamp(0, 31).toString().padLeft(2, '0')}.png';
