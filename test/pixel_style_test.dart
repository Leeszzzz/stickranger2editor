import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sr2editor/codec/game_limits.dart';
import 'package:sr2editor/models/game_data.dart';
import 'package:sr2editor/state/editor_controller.dart';
import 'package:sr2editor/theme/pixel_theme.dart';
import 'package:sr2editor/ui/widgets/pixel_icons.dart';
import 'package:sr2editor/ui/widgets/pixel_kit.dart';

const _sample =
    'akY97ss*CrEFUKYWLCbHNVgaM9TKjvXfIBkXYmx45yRs16AbEQLriOHU7XxE13rAFrOBtNUlFJnn6uI4woiHiexuMRXDw1xxHIQSPR9YL9ckJ*W9wW8XD8Dz8d4q9jyEPPcQo8TTIjPwbeedI.2SWlyvqAJdh6rBXBW6nYD0btmFmvHyS068UEugqvvjQxq2lIlFfejCuD22lCW.fldPZ*ilvcUjzQG4zzKWOmz0Yo.nzEQXP.fu92NUhf8Vdk3iTJt02FRJ0R8KYf*JkX6I4KCe8qMS0OjxMiL3MSBoPoSEhHDu.9qDchyDA2PAjKhA1AtGqjH*sexsgC4*Jgui.RZ1uxBnlPpgx5c7dZHGENJ61c3IpdUw7DwbjVkBKLwrKWQ2uQjyBzFQyL4586Pz1ArMVTgfrTHget30thk.wBujV2xhvaUvD.aWyK4y84ewSpFJzlRexEYH02CRvPXIQnfU';

void main() {
  testWidgets('草方块风格组件渲染冒烟（无像素比对）', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final catalog = GameCatalog.tryParse(
      itemStatsJson: '{"9":{"name":"Sword","type_category":3,"icon":6,'
          '"item_class":2,"damage_type":"Physical","damage_type_id":0}}',
      achievementDataJson: '{"stages":[],"achievements":[],"medals":[]}',
      sourceLabel: 't',
    )!;
    final c = EditorController(catalog: catalog)..loadFromString(_sample);

    await tester.pumpWidget(MaterialApp(
      theme: PixelTheme.light,
      home: Scaffold(
        backgroundColor: PixelPalette.light.paper,
        body: PixelPaperBackground(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const WikiPageHeader(
                title: '草方块风格',
                subtitle: '面板顶部为草皮横切面，底缘参差',
                icon: PixelIcons.logo,
                tags: [PixelBadge('苔绿强调', tone: PixelBadgeTone.accent)],
              ),
              PixelPanel(
                title: '图标一览',
                subtitle: '实心剪影，单色，左右对称',
                icon: PixelIcons.grid,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final g in [
                      PixelIcons.save, PixelIcons.bag, PixelIcons.trophy,
                      PixelIcons.coin, PixelIcons.bolt, PixelIcons.star,
                      PixelIcons.heart, PixelIcons.sword, PixelIcons.shield,
                      PixelIcons.ring, PixelIcons.amulet, PixelIcons.hat,
                      PixelIcons.spark, PixelIcons.potion, PixelIcons.map,
                      PixelIcons.flag, PixelIcons.skull, PixelIcons.eye,
                      PixelIcons.dice, PixelIcons.clock, PixelIcons.gear,
                      PixelIcons.search, PixelIcons.sun, PixelIcons.moon,
                    ])
                      PixelGlyph(g, size: 32),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PixelPanel(
                title: '按钮与徽章',
                icon: PixelIcons.spark,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PixelButton(label: '主操作', tone: PixelButtonTone.primary, onPressed: () {}),
                    PixelButton(label: '强调', tone: PixelButtonTone.accent, onPressed: () {}),
                    PixelButton(label: '次要', onPressed: () {}),
                    PixelButton(label: '删除', tone: PixelButtonTone.danger, onPressed: () {}),
                    const PixelBadge('苔绿', tone: PixelBadgeTone.accent),
                    const PixelBadge('成功', tone: PixelBadgeTone.success),
                    const PixelBadge('警告', tone: PixelBadgeTone.danger),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PixelPanel(
                title: '数值',
                icon: PixelIcons.coin,
                child: PixelInfoTable(
                  rows: [
                    PixelInfoRow('金币', '${c.gold}', mono: true),
                    PixelInfoRow('等级', '${c.level}', mono: true),
                    PixelInfoRow('上限', '${GameLimits.goldMax}', mono: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(PixelPanel), findsNWidgets(3));
    expect(find.text('草方块风格'), findsOneWidget);

    // 不做像素比对，避免每次调 UI 都要重新生成基准图。
    // 这里只确认整棵树能完成一次绘制且无异常抛出。
    expect(tester.takeException(), isNull);
  });
}
