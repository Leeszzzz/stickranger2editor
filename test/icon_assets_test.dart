import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sr2editor/models/game_data.dart';
import 'package:sr2editor/models/icon_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('item_stats 引用的每个 icon 都有对应资产', () async {
    final catalog = await GameCatalog.loadFromAssets();
    final missing = <String, int>{};
    for (final entry in catalog.items.entries) {
      final iconIndex = entry.value.icon;
      if (!kAvailableIconIndices.contains(iconIndex)) {
        missing['${entry.key}(${entry.value.name})'] = iconIndex;
      }
      try {
        await rootBundle.load(iconAssetPath(iconIndex));
      } catch (_) {
        missing['asset:${entry.key}'] = iconIndex;
      }
    }
    expect(missing, isEmpty);
  });

  test('iconAssetPath 格式', () {
    expect(iconAssetPath(6), 'assets/icons/icon_006.png');
    expect(iconAssetPath(128), 'assets/icons/icon_128.png');
  });
}
