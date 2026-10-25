import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../../state/editor_controller.dart';
import '../../theme/pixel_theme.dart';
import '../widgets/common.dart';
import '../widgets/pixel_icons.dart';
import '../widgets/pixel_kit.dart';

/// 与仓库 ranger2_decoder.py 内置示例一致的测试存档。
const kSampleSave =
    'akY97ss*CrEFUKYWLCbHNVgaM9TKjvXfIBkXYmx45yRs16AbEQLriOHU7XxE13rAFrOBtNUlFJnn6uI4woiHiexuMRXDw1xxHIQSPR9YL9ckJ*W9wW8XD8Dz8d4q9jyEPPcQo8TTIjPwbeedI.2SWlyvqAJdh6rBXBW6nYD0btmFmvHyS068UEugqvvjQxq2lIlFfejCuD22lCW.fldPZ*ilvcUjzQG4zzKWOmz0Yo.nzEQXP.fu92NUhf8Vdk3iTJt02FRJ0R8KYf*JkX6I4KCe8qMS0OjxMiL3MSBoPoSEhHDu.9qDchyDA2PAjKhA1AtGqjH*sexsgC4*Jgui.RZ1uxBnlPpgx5c7dZHGENJ61c3IpdUw7DwbjVkBKLwrKWQ2uQjyBzFQyL4586Pz1ArMVTgfrTHget30thk.wBujV2xhvaUvD.aWyK4y84ewSpFJzlRexEYH02CRvPXIQnfU';

class SaveScreen extends StatefulWidget {
  const SaveScreen({super.key});

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  String? _error;
  bool _exported = false;

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  void _decode(EditorController controller) {
    final err = controller.loadFromString(_input.text);
    setState(() {
      _error = err;
      _exported = false;
      _output.clear();
    });
    if (err == null && mounted) {
      showAppSnackBar(context, '解析成功，可以开始编辑了');
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (mounted) showAppSnackBar(context, '剪贴板为空', error: true);
      return;
    }
    setState(() => _input.text = text);
  }

  void _export(EditorController controller) {
    final s = controller.encode();
    if (s == null) return;
    setState(() {
      _output.text = s;
      _exported = true;
    });
    showAppSnackBar(context, '已生成新存档');
  }

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: PixelLayout.contentMax),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 24, 40),
          children: [
            WikiPageHeader(
              title: '存档工坊',
              breadcrumb: const ['SR2 EDITOR', '存档工坊'],
              icon: PixelIcons.save,
              subtitle:
                  '导入、修改并重新编码 Stick Ranger 2 的存档字符串。'
                  '解码会校验尾部校验和与数据校验和，导出时自动重算。',
              tags: const [
                PixelBadge('离线解码', tone: PixelBadgeTone.success, dot: true),
                PixelBadge('768 个 6-bit 值', tone: PixelBadgeTone.neutral),
                PixelBadge('重编码导出', tone: PixelBadgeTone.gold),
              ],
            ),
            _StatusStrip(controller: controller, onUnload: _unload),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 880;
                final left = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ImportPanel(
                      controller: controller,
                      input: _input,
                      error: _error,
                      onClearError: () => setState(() => _error = null),
                      onPaste: _paste,
                      onSample: () => setState(() => _input.text = kSampleSave),
                      onDecode: () => _decode(controller),
                    ),
                    const SizedBox(height: 16),
                    _ExportPanel(
                      controller: controller,
                      output: _output,
                      exported: _exported,
                      onExport: () => _export(controller),
                    ),
                  ],
                );
                final right = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ArchiveInfobox(controller: controller),
                    const SizedBox(height: 16),
                    const _GuidePanel(),
                  ],
                );
                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [left, const SizedBox(height: 16), right],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: left),
                    const SizedBox(width: 16),
                    SizedBox(width: 300, child: right),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _unload() {
    AppDeps.of(context).controller.unload();
    setState(() {
      _output.clear();
      _exported = false;
      _error = null;
    });
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.controller, required this.onUnload});

  final EditorController controller;
  final VoidCallback onUnload;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final loaded = controller.hasSave;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: loaded ? p.panel : p.paperAlt,
        border: Border.all(color: p.border, width: PixelSize.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 620;
          final icon = PixelGlyph(
            loaded ? PixelIcons.check : PixelIcons.warning,
            size: 16,
            color: loaded ? p.success : p.goldDeep,
            accent: loaded ? p.success : p.gold,
          );
          final text = Text(
            loaded
                ? '存档已载入 · 可以前往总览 / 角色 / 背包 / 进度编辑'
                : '尚未载入存档 · 在下方粘贴游戏 EXPORT 得到的字符串',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: loaded ? p.ink : p.inkSoft,
              fontWeight: FontWeight.w700,
            ),
          );
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PixelBadge(
                'User ID ${controller.userId}',
                tone: PixelBadgeTone.neutral,
              ),
              const SizedBox(width: 8),
              PixelButton(
                label: '卸载',
                icon: PixelIcons.close,
                size: PixelButtonSize.small,
                tone: PixelButtonTone.ghost,
                onPressed: onUnload,
              ),
            ],
          );
          if (!loaded) {
            return Row(
              children: [
                icon,
                const SizedBox(width: 8),
                Expanded(child: text),
              ],
            );
          }
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    icon,
                    const SizedBox(width: 8),
                    Expanded(child: text),
                  ],
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }
          return Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Expanded(child: text),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _ImportPanel extends StatelessWidget {
  const _ImportPanel({
    required this.controller,
    required this.input,
    required this.error,
    required this.onClearError,
    required this.onPaste,
    required this.onSample,
    required this.onDecode,
  });

  final EditorController controller;
  final TextEditingController input;
  final String? error;
  final VoidCallback onClearError;
  final VoidCallback onPaste;
  final VoidCallback onSample;
  final VoidCallback onDecode;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return PixelPanel(
      title: '① 导入存档',
      subtitle: '在游戏中点击 EXPORT 复制存档字符串，粘贴到下方后解析',
      icon: PixelIcons.download,
      accent: p.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelTextField(
            controller: input,
            hint: '粘贴存档字符串…',
            maxLines: 6,
            mono: true,
            onChanged: (_) => onClearError(),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            PixelCallout(
              message: error!,
              icon: PixelIcons.warning,
              tone: PixelBadgeTone.danger,
              title: '解析失败',
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PixelButton(
                label: '粘贴剪贴板',
                icon: PixelIcons.copy,
                onPressed: onPaste,
              ),
              PixelButton(
                label: '示例存档',
                icon: PixelIcons.spark,
                onPressed: onSample,
              ),
              PixelButton(
                label: '解析存档',
                icon: PixelIcons.unlock,
                tone: PixelButtonTone.primary,
                onPressed: onDecode,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportPanel extends StatelessWidget {
  const _ExportPanel({
    required this.controller,
    required this.output,
    required this.exported,
    required this.onExport,
  });

  final EditorController controller;
  final TextEditingController output;
  final bool exported;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return PixelPanel(
      title: '② 导出存档',
      subtitle: '在其他页面编辑存档后生成新存档',
      icon: PixelIcons.upload,
      accent: p.gold,
      trailing: PixelButton(
        label: '生成新存档',
        icon: PixelIcons.spark,
        tone: PixelButtonTone.primary,
        size: PixelButtonSize.small,
        onPressed: controller.hasSave ? onExport : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelTextField(
            controller: output,
            hint: '生成的新存档字符串将显示在这里…',
            maxLines: 6,
            readOnly: true,
            mono: true,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              PixelButton(
                label: '复制到剪贴板',
                icon: PixelIcons.copy,
                onPressed: output.text.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: output.text),
                        );
                        if (context.mounted) {
                          showAppSnackBar(context, '已复制到剪贴板，回游戏 IMPORT 即可');
                        }
                      },
              ),
            ],
          ),
          if (exported) ...[
            const SizedBox(height: 10),
            PixelCallout(
              message: '修改存档前请务必备份原始字符串，编辑风险自负。',
              icon: PixelIcons.warning,
              tone: PixelBadgeTone.gold,
            ),
          ],
        ],
      ),
    );
  }
}

class _ArchiveInfobox extends StatelessWidget {
  const _ArchiveInfobox({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final loaded = controller.hasSave;
    return PixelPanel(
      title: '存档档案',
      icon: PixelIcons.book,
      accent: p.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelInfoTable(
            rows: [
              PixelInfoRow(
                '状态',
                loaded ? '已载入' : '未载入',
                valueColor: loaded ? p.success : p.inkFaint,
              ),
              PixelInfoRow(
                'User ID',
                loaded ? controller.userId : '—',
                mono: true,
              ),
              PixelInfoRow(
                '密文长度',
                loaded ? '${controller.sourceString?.length ?? 0} 字符' : '—',
                mono: true,
              ),
              PixelInfoRow(
                '数据值',
                loaded ? '${controller.rawData?.length ?? 0} 个' : '—',
                mono: true,
              ),
              PixelInfoRow(
                '金币',
                loaded ? formatInt(controller.gold) : '—',
                mono: true,
                valueColor: p.goldDeep,
              ),
              PixelInfoRow(
                '等级',
                loaded ? '${controller.level}' : '—',
                mono: true,
              ),
              PixelInfoRow(
                '当前关卡',
                loaded ? '${controller.stage}' : '—',
                mono: true,
              ),
            ],
          ),
          if (controller.decodeWarning != null) ...[
            const SizedBox(height: 10),
            PixelCallout(
              message: controller.decodeWarning!,
              icon: PixelIcons.info,
              tone: PixelBadgeTone.link,
            ),
          ],
        ],
      ),
    );
  }
}

class _GuidePanel extends StatelessWidget {
  const _GuidePanel();

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    const steps = [
      ('01', '导出', '在游戏中打开 IMPORT / EXPORT，复制存档字符串。'),
      ('02', '导入', '粘贴到「导入存档」并解析，随后编辑各页面。'),
      ('03', '回写', '生成新存档并复制，回到游戏 IMPORT。'),
    ];
    return PixelPanel(
      title: '使用说明',
      icon: PixelIcons.info,
      dense: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (no, title, body) in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.ink,
                      border: Border.all(color: p.border, width: 2),
                    ),
                    child: Text(
                      no,
                      style: TextStyle(
                        fontFamily: PixelFont.mono,
                        fontFamilyFallback: PixelFont.fallback,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.panel,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          body,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: p.inkSoft, height: 1.55),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          PixelDivider(color: p.border.withValues(alpha: 0.35)),
          const SizedBox(height: 8),
          Text(
            '提示：物品在背包中以等级记录，0 级表示未获取。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: p.inkSoft, height: 1.6),
          ),
        ],
      ),
    );
  }
}
