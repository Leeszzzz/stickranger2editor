/// 全局导入 / 导出快捷操作。
///
/// 「导入/导出」页之外的页面都通过这里提供入口：
/// - [SaveQuickActions]：页眉右侧的「导入存档」按钮 —— 弹出输入框，
///   解析成功后直接在当前页继续编辑。
/// - [exportSaveWithDialog]：导出行按钮与「导入/导出」页共用，
///   成功后弹出可复制的存档字符串。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../../theme/pixel_theme.dart';
import '../widgets/common.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_kit.dart';

/// 与仓库 ranger2_decoder.py 内置示例一致的测试存档。
const kSampleSave =
    'akY97ss*CrEFUKYWLCbHNVgaM9TKjvXfIBkXYmx45yRs16AbEQLriOHU7XxE13rAFrOBtNUlFJnn6uI4woiHiexuMRXDw1xxHIQSPR9YL9ckJ*W9wW8XD8Dz8d4q9jyEPPcQo8TTIjPwbeedI.2SWlyvqAJdh6rBXBW6nYD0btmFmvHyS068UEugqvvjQxq2lIlFfejCuD22lCW.fldPZ*ilvcUjzQG4zzKWOmz0Yo.nzEQXP.fu92NUhf8Vdk3iTJt02FRJ0R8KYf*JkX6I4KCe8qMS0OjxMiL3MSBoPoSEhHDu.9qDchyDA2PAjKhA1AtGqjH*sexsgC4*Jgui.RZ1uxBnlPpgx5c7dZHGENJ61c3IpdUw7DwbjVkBKLwrKWQ2uQjyBzFQyL4586Pz1ArMVTgfrTHget30thk.wBujV2xhvaUvD.aWyK4y84ewSpFJzlRexEYH02CRvPXIQnfU';

/// 弹出粘贴框导入存档；成功返回 true。
Future<bool> importSaveWithDialog(BuildContext context) async {
  final controller = EditorScope.read(context);
  final textCtrl = TextEditingController();

  final ok = await showPixelDialog<bool>(
    context: context,
    title: '导入存档',
    icon: PixelIcons.download,
    maxWidth: 620,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelTextField(
          controller: textCtrl,
          hint: '粘贴存档字符串…',
          maxLines: 6,
          mono: true,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PixelButton(
              label: '粘贴剪贴板',
              icon: PixelIcons.copy,
              size: PixelButtonSize.small,
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                final t = data?.text?.trim();
                if (t != null && t.isNotEmpty) textCtrl.text = t;
              },
            ),
            PixelButton(
              label: '填入示例',
              icon: PixelIcons.spark,
              size: PixelButtonSize.small,
              onPressed: () => textCtrl.text = kSampleSave,
            ),
          ],
        ),
      ],
    ),
    actions: [
      PixelButton(
        label: '取消',
        tone: PixelButtonTone.ghost,
        onPressed: () => Navigator.of(context).pop(false),
      ),
      PixelButton(
        label: '解析存档',
        icon: PixelIcons.check,
        tone: PixelButtonTone.primary,
        onPressed: () async {
          final err = controller.loadFromString(textCtrl.text);
          if (err != null) {
            if (context.mounted) {
              showAppSnackBar(context, err, error: true);
            }
            return;
          }
          if (context.mounted) Navigator.of(context).pop(true);
        },
      ),
    ],
  );

  textCtrl.dispose();
  if (ok == true && context.mounted) {
    showAppSnackBar(context, '解析成功，可以开始编辑了');
    return true;
  }
  return false;
}

/// 生成新存档并弹出结果对话框（含复制按钮）。未载入存档时返回 null。
Future<String?> exportSaveWithDialog(BuildContext context) async {
  final controller = EditorScope.read(context);
  final save = controller.encode();
  if (save == null) {
    showAppSnackBar(context, '尚未导入存档', error: true);
    return null;
  }
  if (!context.mounted) return save;

  await showPixelDialog<void>(
    context: context,
    title: '导出成功',
    icon: PixelIcons.upload,
    maxWidth: 680,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelInfoTable(
          rows: [
            PixelInfoRow('密文长度', '${save.length}', mono: true),
            PixelInfoRow('金币', formatInt(controller.gold), mono: true),
            PixelInfoRow('等级', '${controller.level}', mono: true),
            PixelInfoRow('背包', '${controller.itemsTotal} 种', mono: true),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: PixelPalette.of(context).paperAlt,
            border: Border.all(
              color: PixelPalette.of(context).border,
              width: PixelSize.border,
            ),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              save,
              style: const TextStyle(
                fontFamily: PixelFont.mono,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    ),
    actions: [
      PixelButton(
        label: '复制到剪贴板',
        icon: PixelIcons.copy,
        tone: PixelButtonTone.primary,
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: save));
          if (context.mounted) {
            Navigator.of(context).pop();
            showAppSnackBar(context, '已复制，回到游戏点击 IMPORT 粘贴');
          }
        },
      ),
    ],
  );
  return save;
}

/// 页眉右侧的快捷按钮组：导入存档 + 导出存档。
class SaveQuickActions extends StatelessWidget {
  const SaveQuickActions({super.key, this.showExport = true});

  /// 是否同时提供导出按钮。
  final bool showExport;

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PixelButton(
          label: '导入存档',
          icon: PixelIcons.download,
          size: PixelButtonSize.small,
          onPressed: () => importSaveWithDialog(context),
        ),
        if (showExport)
          PixelButton(
            label: '导出存档',
            icon: PixelIcons.upload,
            size: PixelButtonSize.small,
            tone: PixelButtonTone.accent,
            onPressed: controller.hasSave
                ? () => exportSaveWithDialog(context)
                : null,
          ),
      ],
    );
  }
}
