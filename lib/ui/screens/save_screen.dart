import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../../state/editor_controller.dart';
import '../widgets/common.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final controller = EditorScope.watch(context);
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            _HeroCard(controller: controller),
            const SizedBox(height: 12),
            SectionCard(
              title: '导入存档',
              icon: Icons.download_rounded,
              subtitle: '在游戏中点击 EXPORT 复制存档字符串，粘贴到下方后解析',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _input,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: '粘贴 .rng2 存档字符串…',
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: theme.colorScheme.onErrorContainer, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _paste,
                        icon: const Icon(Icons.content_paste, size: 18),
                        label: const Text('粘贴'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _input.text = kSampleSave),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('示例存档'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _decode(controller),
                        icon: const Icon(Icons.lock_open_rounded, size: 18),
                        label: const Text('解析存档'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _StatusCard(controller: controller),
            const SizedBox(height: 12),
            SectionCard(
              title: '导出存档',
              icon: Icons.ios_share_rounded,
              subtitle: '编码使用随机盐，同一状态每次生成的密文不同，游戏均可正常识别',
              trailing: FilledButton.icon(
                onPressed: controller.hasSave ? () => _export(controller) : null,
                icon: const Icon(Icons.enhanced_encryption_rounded, size: 18),
                label: const Text('生成新存档'),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _output,
                    maxLines: 4,
                    readOnly: true,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: '生成的新存档字符串将显示在这里…',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _output.text.isEmpty
                            ? null
                            : () async {
                                await Clipboard.setData(
                                    ClipboardData(text: _output.text));
                                if (context.mounted) {
                                  showAppSnackBar(context, '已复制到剪贴板，回游戏 IMPORT 即可');
                                }
                              },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('复制到剪贴板'),
                      ),
                    ],
                  ),
                  if (_exported) ...[
                    const SizedBox(height: 8),
                    Text(
                      '⚠ 修改存档前请务必备份原始字符串，编辑风险自负。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.terrain_rounded,
                  size: 30, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stick Ranger 2 存档编辑器',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!controller.hasSave) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.hourglass_empty_rounded,
                  color: theme.colorScheme.onSurfaceVariant, size: 20),
              const SizedBox(width: 10),
              Text(
                '尚未载入存档',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final warn = controller.decodeWarning;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      size: 16, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 10),
                Text('已解析',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                InfoBadge('User ID  ${controller.userId}'),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoBadge('密文 ${controller.sourceString?.length ?? 0} 字符'),
                InfoBadge('数据 ${controller.rawData?.length ?? 0} 值'),
                InfoBadge(
                    '金币 ${formatInt(controller.gold)}',
                    color: theme.colorScheme.tertiary),
                InfoBadge('等级 ${controller.level}'),
                InfoBadge('关卡 ${controller.stage}'),
              ],
            ),
            if (warn != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      warn,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
