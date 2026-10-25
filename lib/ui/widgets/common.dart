/// 通用像素组件：统计卡 / 区块卡 / 数字编辑器 / 空态 / 小工具。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/pixel_theme.dart';
import 'pixel_icons.dart';
import 'pixel_kit.dart';

/// 千分位格式化。
String formatInt(int v) {
  final s = '$v';
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final remain = s.length - i;
    buf.write(s[i]);
    if (remain > 1 && remain % 3 == 1) buf.write(',');
  }
  return buf.toString();
}

const tabularFigures = [FontFeature.tabularFigures()];

/// 大数值统计卡：像素面板 + 硬投影 + 可点击编辑。
class StatCard extends StatefulWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.max,
    this.onTap,
  });

  final String label;
  final String value;
  final PixelGlyphData icon;
  final Color color;
  final String? max;
  final VoidCallback? onTap;

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: widget.onTap,
      onHover: widget.onTap == null ? null : (v) => setState(() => _hover = v),
      mouseCursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hover ? p.panelAlt : p.panel,
          border: Border.all(
            color: _hover ? p.gold : p.border,
            width: PixelSize.border,
          ),
          boxShadow: [
            BoxShadow(
              color: p.shadow,
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                PixelGlyph(
                  widget.icon,
                  size: 16,
                  color: widget.color,
                  accent: widget.color,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: p.inkSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (widget.onTap != null)
                  Text(
                    _hover ? '编辑 →' : '编辑',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _hover ? p.goldDeep : p.inkFaint,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.value,
              style: TextStyle(
                fontFamily: PixelFont.family,
                fontFamilyFallback: PixelFont.fallback,
                fontSize: PixelSize.value,
                height: 1.05,
                fontWeight: FontWeight.w700,
                fontFeatures: tabularFigures,
                color: widget.color,
              ),
            ),
            if (widget.max != null) ...[
              const SizedBox(height: 4),
              Text(
                '上限 ${widget.max}',
                style: theme.textTheme.bodySmall?.copyWith(color: p.inkFaint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 兼容旧 API 的区块卡（内部为 PixelPanel）。
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.iconWidget,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final PixelGlyphData? icon;
  final Widget? iconWidget;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PixelPanel(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconWidget: iconWidget,
      trailing: trailing,
      child: child,
    );
  }
}

/// 数字编辑行：[-] 值 [+] ＋点击数值精确输入。
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.color,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final Color? color;

  Future<void> _showDialog(BuildContext context) async {
    final p = PixelPalette.of(context);
    final text = TextEditingController(text: '$value');
    final result = await showPixelDialog<int>(
      context: context,
      title: '设置$label',
      icon: PixelIcons.gear,
      maxWidth: 380,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$min — $max',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: p.inkSoft),
          ),
          const SizedBox(height: 10),
          PixelTextField(
            controller: text,
            autofocus: true,
            mono: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (v) {
              final n = int.tryParse(v);
              if (n != null) Navigator.of(context).pop(n.clamp(min, max));
            },
          ),
        ],
      ),
      actions: [
        PixelButton(label: '取消', onPressed: () => Navigator.of(context).pop()),
        PixelButton(
          label: '拉满 $max',
          icon: PixelIcons.chevronUp,
          onPressed: () => Navigator.of(context).pop(max),
        ),
        PixelButton(
          label: '确定',
          tone: PixelButtonTone.primary,
          onPressed: () {
            final n = int.tryParse(text.text);
            Navigator.of(context).pop((n ?? value).clamp(min, max));
          },
        ),
      ],
    );
    text.dispose();
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = PixelPalette.of(context);
    final accent = color ?? p.goldDeep;
    return InkWell(
      onTap: () => _showDialog(context),
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: p.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatInt(value),
                    style: TextStyle(
                      fontFamily: PixelFont.family,
                      fontFamilyFallback: PixelFont.fallback,
                      fontSize: PixelSize.valueCompact,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      fontFeatures: tabularFigures,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            PixelIconButton(
              icon: PixelIcons.minus,
              tooltip: '减少',
              size: PixelButtonSize.small,
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            const SizedBox(width: 6),
            PixelIconButton(
              icon: PixelIcons.plus,
              tooltip: '增加',
              size: PixelButtonSize.small,
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// 未载入存档时的空态：像素插图 + 引导按钮。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final PixelGlyphData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: PixelPanel(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.panelAlt,
                    border: Border.all(
                      color: p.border,
                      width: PixelSize.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: p.shadow,
                        offset: const Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: PixelGlyph(icon, size: 64),
                ),
                const SizedBox(height: 18),
                Text(
                  'NO DATA',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: p.goldDeep,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.inkSoft,
                    height: 1.75,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 18),
                  PixelButton(
                    label: actionLabel!,
                    icon: PixelIcons.save,
                    tone: PixelButtonTone.primary,
                    size: PixelButtonSize.large,
                    onPressed: onAction,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 换行内嵌信息徽章（保留旧 API）。
class InfoBadge extends StatelessWidget {
  const InfoBadge(this.text, {super.key, this.color, this.background});

  final String text;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background ?? p.panelAlt,
        border: Border.all(color: p.border.withValues(alpha: 0.7), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: PixelFont.family,
          fontFamilyFallback: PixelFont.fallback,
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w700,
          fontFeatures: tabularFigures,
          color: color ?? p.inkSoft,
        ),
      ),
    );
  }
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  showPixelToast(context, message, error: error);
}
