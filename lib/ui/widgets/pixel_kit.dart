/// 像素百科组件库：硬边框面板、像素按钮、表格、标签页、滑块、对话框。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/pixel_theme.dart';
import 'pixel_icons.dart';

abstract final class PixelLayout {
  /// 宽屏（显示侧边栏）。
  static const wide = 960.0;

  /// 双栏内容断点。
  static const twoColumn = 720.0;

  static const contentMax = 1080.0;
  static const gutter = 20.0;
  static const gutterCompact = 12.0;
}

/// 页面底纹：旧纸网格 + 稀疏抖动点。
class PixelPaperBackground extends StatelessWidget {
  const PixelPaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return CustomPaint(
      painter: _PaperPainter(
        base: p.paper,
        grid: p.ink.withValues(alpha: 0.035),
        dot: p.ink.withValues(alpha: 0.055),
      ),
      child: child,
    );
  }
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter({
    required this.base,
    required this.grid,
    required this.dot,
  });

  final Color base;
  final Color grid;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    canvas.drawRect(Offset.zero & size, paint..color = base);

    paint
      ..color = grid
      ..style = PaintingStyle.fill;
    for (var x = 0.0; x < size.width; x += 24) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 24) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }

    paint.color = dot;
    const step = 48.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        final ix = (x / step).round();
        final iy = (y / step).round();
        if ((ix * 7 + iy * 13) % 5 != 0) continue;
        canvas.drawRect(Rect.fromLTWH(x + 14, y + 26, 2, 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PaperPainter oldDelegate) =>
      oldDelegate.base != base ||
      oldDelegate.grid != grid ||
      oldDelegate.dot != dot;
}

/// 页面 / 页签切换时的淡入与轻微上移。
///
/// 所有子页面保持在树中，以保留各页面的滚动位置与筛选状态；
/// 非当前页会被忽略指针、排除语义并暂停 ticker。
class PixelPageSwitcher extends StatelessWidget {
  const PixelPageSwitcher({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 180),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: AnimatedOpacity(
              opacity: i == index ? 1 : 0,
              duration: duration,
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: i == index ? Offset.zero : const Offset(0, 0.012),
                duration: duration,
                curve: Curves.easeOutCubic,
                child: TickerMode(
                  enabled: i == index,
                  child: ExcludeFocus(
                    excluding: i != index,
                    child: ExcludeSemantics(
                      excluding: i != index,
                      child: RepaintBoundary(child: children[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// 面板
// ============================================================================

/// 像素面板：2px 墨线 + 4px 硬投影 + 可选表头。
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.iconWidget,
    this.trailing,
    this.padding,
    this.shadow = true,
    this.accent,
    this.headerColor,
    this.bodyColor,
    this.borderColor,
    this.dense = false,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final PixelGlyphData? icon;
  final Widget? iconWidget;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final bool shadow;
  final Color? accent;
  final Color? headerColor;
  final Color? bodyColor;
  final Color? borderColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final border = borderColor ?? p.border;
    final hasHeader = title != null;
    return Container(
      decoration: BoxDecoration(
        color: bodyColor ?? p.panel,
        border: Border.all(color: border, width: PixelSize.border),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: p.shadow,
                  offset: const Offset(
                    PixelSize.shadowOffset,
                    PixelSize.shadowOffset,
                  ),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader)
            Container(
              decoration: BoxDecoration(
                color: headerColor ?? p.panelAlt,
                border: Border(
                  bottom: BorderSide(color: border, width: PixelSize.border),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                10,
                dense ? 6 : 8,
                trailing == null ? 10 : 6,
                dense ? 6 : 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (accent != null) ...[
                    Container(width: 4, height: dense ? 16 : 24, color: accent),
                    const SizedBox(width: 8),
                  ],
                  if (iconWidget != null) ...[
                    iconWidget!,
                    const SizedBox(width: 8),
                  ] else if (icon != null) ...[
                    PixelGlyph(icon!, size: dense ? 16 : 24),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: dense
                              ? Theme.of(context).textTheme.titleSmall
                              : Theme.of(context).textTheme.titleLarge,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: p.inkSoft),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          Padding(
            padding:
                padding ?? EdgeInsets.all(dense ? 10 : (hasHeader ? 14 : 12)),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// 页面大标题 + 面包屑 + 快捷操作。
class WikiPageHeader extends StatelessWidget {
  const WikiPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumb = const ['SR2 EDITOR'],
    this.icon,
    this.tags = const [],
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<String> breadcrumb;
  final PixelGlyphData? icon;
  final List<Widget> tags;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 640;
    final titleSize = compact
        ? PixelSize.pageTitleCompact
        : PixelSize.pageTitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            for (var i = 0; i < breadcrumb.length; i++) ...[
              if (i > 0)
                Text(
                  '/',
                  style: theme.textTheme.bodySmall?.copyWith(color: p.inkFaint),
                ),
              Text(
                breadcrumb[i],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: i == breadcrumb.length - 1 ? p.inkSoft : p.inkFaint,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              PixelGlyph(icon!, size: compact ? 32 : 48),
              SizedBox(width: compact ? 10 : 14),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: PixelFont.family,
                  fontFamilyFallback: PixelFont.fallback,
                  fontSize: titleSize,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 12),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: p.inkSoft,
                height: 1.75,
              ),
            ),
          ),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: tags),
        ],
        const SizedBox(height: 14),
        const PixelRule(),
        const SizedBox(height: 18),
      ],
    );
  }
}

/// 金色短横 + 墨线：页眉下的分节线。
class PixelRule extends StatelessWidget {
  const PixelRule({super.key, this.color, this.width = 56});

  final Color? color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return SizedBox(
      height: 4,
      child: Row(
        children: [
          Container(width: width, height: 4, color: color ?? p.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(height: 2, color: p.border),
            ),
          ),
        ],
      ),
    );
  }
}

/// 小号分节标签：金色方块 + 大写感标题。
class PixelSectionLabel extends StatelessWidget {
  const PixelSectionLabel(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return Row(
      children: [
        Container(width: 4, height: 12, color: p.gold),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: p.inkSoft,
            letterSpacing: 1.2,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

// ============================================================================
// 按钮 / 标签
// ============================================================================

enum PixelButtonTone { primary, secondary, ghost, danger, gold }

enum PixelButtonSize { small, regular, large }

class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.tone = PixelButtonTone.secondary,
    this.size = PixelButtonSize.regular,
    this.expanded = false,
    this.iconOnly = false,
    this.tooltip,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final PixelGlyphData? icon;
  final PixelButtonTone tone;
  final PixelButtonSize size;
  final bool expanded;
  final bool iconOnly;
  final String? tooltip;
  final PixelGlyphData? trailingIcon;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _hover = false;
  bool _focus = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  double get _height => switch (widget.size) {
    PixelButtonSize.small => 26,
    PixelButtonSize.regular => 32,
    PixelButtonSize.large => 40,
  };

  EdgeInsets get _padding => switch (widget.size) {
    PixelButtonSize.small => const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    PixelButtonSize.regular => const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    PixelButtonSize.large => const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final (bg, fg, border) = _colors(p);
    final glyphSize = widget.size == PixelButtonSize.large ? 24.0 : 16.0;
    final content = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          PixelGlyph(widget.icon!, size: glyphSize, color: fg, accent: fg),
          if (!widget.iconOnly && widget.label.isNotEmpty)
            const SizedBox(width: 8),
        ],
        if (!widget.iconOnly)
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: PixelFont.family,
                fontFamilyFallback: PixelFont.fallback,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: fg,
              ),
            ),
          ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          PixelGlyph(
            widget.trailingIcon!,
            size: glyphSize,
            color: fg,
            accent: fg,
          ),
        ],
      ],
    );

    final lift = _hover && _enabled && !_pressed;
    Widget box = Transform.translate(
      offset: _pressed && _enabled
          ? const Offset(2, 2)
          : (lift ? const Offset(-1, -1) : Offset.zero),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        height: _height,
        width: widget.iconOnly ? _height : null,
        padding: widget.iconOnly ? EdgeInsets.zero : _padding,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: _focus ? p.gold : border,
            width: PixelSize.border,
          ),
          boxShadow: _enabled && !_pressed
              ? [
                  BoxShadow(
                    color: p.shadow,
                    offset: Offset(lift ? 4 : 3, lift ? 4 : 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: content,
      ),
    );

    if (widget.expanded) {
      box = SizedBox(width: double.infinity, child: box);
    }

    box = Opacity(opacity: _enabled ? 1 : 0.42, child: box);

    box = InkWell(
      onTap: widget.onPressed,
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
      onHover: _enabled ? (v) => setState(() => _hover = v) : null,
      onFocusChange: (v) => setState(() => _focus = v),
      canRequestFocus: _enabled,
      mouseCursor: _enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: box,
    );

    if (widget.tooltip != null) {
      box = Tooltip(message: widget.tooltip!, child: box);
    }
    return box;
  }

  (Color, Color, Color) _colors(PixelPalette p) {
    switch (widget.tone) {
      case PixelButtonTone.primary:
        return _hover ? (p.ink, p.gold, p.gold) : (p.ink, p.panel, p.border);
      case PixelButtonTone.danger:
        return _hover
            ? (p.danger, p.panel, p.gold)
            : (p.danger, p.panel, p.border);
      case PixelButtonTone.gold:
        return _hover ? (p.gold, p.ink, p.ink) : (p.goldSoft, p.ink, p.border);
      case PixelButtonTone.ghost:
        return (
          _hover ? p.paperAlt : Colors.transparent,
          p.ink,
          _hover ? p.inkFaint : Colors.transparent,
        );
      case PixelButtonTone.secondary:
        return (_hover ? p.goldSoft : p.panel, p.ink, p.border);
    }
  }
}

class PixelIconButton extends StatelessWidget {
  const PixelIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.tone = PixelButtonTone.secondary,
    this.size = PixelButtonSize.regular,
  });

  final PixelGlyphData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final PixelButtonTone tone;
  final PixelButtonSize size;

  @override
  Widget build(BuildContext context) {
    return PixelButton(
      label: '',
      icon: icon,
      iconOnly: true,
      tooltip: tooltip,
      onPressed: onPressed,
      tone: tone,
      size: size,
    );
  }
}

enum PixelBadgeTone { neutral, gold, link, danger, success, ink }

class PixelBadge extends StatelessWidget {
  const PixelBadge(
    this.text, {
    super.key,
    this.tone = PixelBadgeTone.neutral,
    this.icon,
    this.dot = false,
  });

  final String text;
  final PixelBadgeTone tone;
  final PixelGlyphData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final (fg, bg, border) = switch (tone) {
      PixelBadgeTone.gold => (p.goldDeep, p.goldSoft, p.goldDeep),
      PixelBadgeTone.link => (p.link, p.panel, p.link),
      PixelBadgeTone.danger => (p.danger, p.panel, p.danger),
      PixelBadgeTone.success => (p.success, p.panel, p.success),
      PixelBadgeTone.ink => (p.panel, p.ink, p.ink),
      PixelBadgeTone.neutral => (p.inkSoft, p.panelAlt, p.border),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 6, height: 6, color: fg),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            PixelGlyph(icon!, size: 16, color: fg, accent: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: PixelFont.family,
              fontFamilyFallback: PixelFont.fallback,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class PixelDivider extends StatelessWidget {
  const PixelDivider({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return CustomPaint(
      size: const Size(double.infinity, 8),
      painter: _DashedRulePainter(
        color: color ?? p.border.withValues(alpha: 0.55),
        diamond: p.gold,
      ),
    );
  }
}

class _DashedRulePainter extends CustomPainter {
  const _DashedRulePainter({required this.color, required this.diamond});

  final Color color;
  final Color diamond;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..color = color;
    final y = (size.height / 2).floorToDouble();
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawRect(Rect.fromLTWH(x, y - 1, 4, 2), paint);
    }
    final cx = size.width / 2;
    paint.color = diamond;
    canvas.drawRect(Rect.fromLTWH(cx - 3, y - 3, 6, 6), paint);
    canvas.drawRect(Rect.fromLTWH(cx - 1, y - 5, 2, 10), paint);
    canvas.drawRect(Rect.fromLTWH(cx - 5, y - 1, 10, 2), paint);
  }

  @override
  bool shouldRepaint(_DashedRulePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.diamond != diamond;
}

class PixelChip extends StatefulWidget {
  const PixelChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final PixelGlyphData? icon;
  final bool dense;

  @override
  State<PixelChip> createState() => _PixelChipState();
}

class _PixelChipState extends State<PixelChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final fg = widget.selected ? p.panel : p.ink;
    final bg = widget.selected ? p.ink : (_hover ? p.goldSoft : p.panel);
    final border = widget.selected || _hover ? p.ink : p.border;
    return InkWell(
      onTap: widget.onTap,
      onHover: (v) => setState(() => _hover = v),
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          _hover && !widget.selected ? -1 : 0,
          0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: widget.dense ? 6 : 8,
          vertical: widget.dense ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: PixelSize.border),
          boxShadow: widget.selected || _hover
              ? [
                  BoxShadow(
                    color: p.shadow,
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              PixelGlyph(widget.icon!, size: 16, color: fg, accent: fg),
              const SizedBox(width: 5),
            ],
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 100),
              style: TextStyle(
                fontFamily: PixelFont.family,
                fontFamilyFallback: PixelFont.fallback,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}

class PixelSegment<T> {
  const PixelSegment(this.value, this.label, {this.icon});
  final T value;
  final String label;
  final PixelGlyphData? icon;
}

/// 连体分段选择器（队伍人数 / 角色 / 图鉴等级）。
class PixelSegmented<T> extends StatelessWidget {
  const PixelSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expanded = true,
  });

  final List<PixelSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final children = <Widget>[];
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      final isSelected = s.value == selected;
      children.add(
        Expanded(
          flex: expanded ? 1 : 0,
          child: InkWell(
            onTap: () => onChanged(s.value),
            mouseCursor: SystemMouseCursors.click,
            hoverColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? p.ink : p.panel,
                border: i == segments.length - 1
                    ? null
                    : Border(
                        right: BorderSide(
                          color: p.border,
                          width: PixelSize.border,
                        ),
                      ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (s.icon != null) ...[
                    PixelGlyph(
                      s.icon!,
                      size: 16,
                      color: isSelected ? p.panel : p.ink,
                      accent: isSelected ? p.gold : p.gold,
                    ),
                    const SizedBox(width: 5),
                  ],
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 120),
                    style: TextStyle(
                      fontFamily: PixelFont.family,
                      fontFamilyFallback: PixelFont.fallback,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? p.panel : p.ink,
                    ),
                    child: Text(
                      s.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: p.border, width: PixelSize.border),
      ),
      child: Row(children: children),
    );
  }
}

class PixelCheckbox extends StatefulWidget {
  const PixelCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 18,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

  @override
  State<PixelCheckbox> createState() => _PixelCheckboxState();
}

class _PixelCheckboxState extends State<PixelCheckbox> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final enabled = widget.onChanged != null;
    return Semantics(
      checked: widget.value,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? () => widget.onChanged!(!widget.value) : null,
        onHover: enabled ? (v) => setState(() => _hover = v) : null,
        canRequestFocus: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        hoverColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.value ? p.ink : p.panel,
            border: Border.all(
              color: _hover ? p.gold : p.border,
              width: PixelSize.border,
            ),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: widget.value ? 1 : 0),
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            builder: (context, progress, _) => CustomPaint(
              painter: _CheckPainter(color: p.panel, progress: progress),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.color, this.progress = 1});
  final Color color;
  final double progress;

  static const _points = [
    (2, 6),
    (3, 7),
    (4, 8),
    (5, 7),
    (6, 6),
    (7, 5),
    (8, 4),
    (9, 3),
    (10, 2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 12;
    final paint = Paint()
      ..isAntiAlias = false
      ..color = color;
    final count = (_points.length * progress.clamp(0.0, 1.0)).ceil().clamp(
      0,
      _points.length,
    );
    for (var i = 0; i < count; i++) {
      final (x, y) = _points[i];
      canvas.drawRect(Rect.fromLTWH(x * unit, y * unit, unit, unit), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}

class PixelSwitch extends StatefulWidget {
  const PixelSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 42,
    this.height = 22,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;
  final double height;

  @override
  State<PixelSwitch> createState() => _PixelSwitchState();
}

class _PixelSwitchState extends State<PixelSwitch> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final enabled = widget.onChanged != null;
    final knob = widget.height - 8;
    return Semantics(
      toggled: widget.value,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? () => widget.onChanged!(!widget.value) : null,
        onHover: enabled ? (v) => setState(() => _hover = v) : null,
        canRequestFocus: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        hoverColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: widget.value ? p.gold : p.panelAlt,
            border: Border.all(
              color: _hover ? p.ink : p.border,
              width: PixelSize.border,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 110),
            curve: Curves.linear,
            alignment: widget.value
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOut,
              width: knob,
              height: knob,
              color: widget.value ? p.ink : p.inkFaint,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 滑块 / 进度
// ============================================================================

class PixelSlider extends StatelessWidget {
  const PixelSlider({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    this.min = 0,
    this.divisions,
    this.color,
  });

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 10,
        trackShape: _PixelTrackShape(
          border: p.border,
          active: color ?? p.gold,
          inactive: p.panelAlt,
        ),
        thumbShape: _PixelThumbShape(border: p.ink, fill: color ?? p.gold),
        overlayShape: SliderComponentShape.noOverlay,
        tickMarkShape: _PixelTickMarkShape(color: p.inkFaint),
        activeTickMarkColor: p.goldSoft,
        inactiveTickMarkColor: p.inkFaint,
      ),
      child: SizedBox(
        height: 34,
        child: Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PixelTrackShape extends SliderTrackShape {
  const _PixelTrackShape({
    required this.border,
    required this.active,
    required this.inactive,
  });

  final Color border;
  final Color active;
  final Color inactive;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final height = sliderTheme.trackHeight ?? 10;
    return Rect.fromLTWH(
      offset.dx + 2,
      offset.dy + (parentBox.size.height - height) / 2,
      parentBox.size.width - 4,
      height,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final paint = Paint()..isAntiAlias = false;
    canvasFill(context.canvas, rect, border);
    final inner = rect.deflate(PixelSize.border);
    canvasFill(context.canvas, inner, inactive);
    final activeRect = Rect.fromLTRB(
      inner.left,
      inner.top,
      thumbCenter.dx.clamp(inner.left, inner.right),
      inner.bottom,
    );
    canvasFill(context.canvas, activeRect, active);
    // 轨道上的刻度（10px 一格）。
    paint.color = border.withValues(alpha: 0.18);
    for (var x = inner.left + 10; x < inner.right; x += 10) {
      context.canvas.drawRect(
        Rect.fromLTWH(x, inner.top, 1, inner.height),
        paint,
      );
    }
  }

  void canvasFill(Canvas canvas, Rect rect, Color color) {
    canvas.drawRect(
      rect,
      Paint()
        ..isAntiAlias = false
        ..color = color,
    );
  }

  @override
  bool get isRounded => false;
}

class _PixelThumbShape extends SliderComponentShape {
  const _PixelThumbShape({required this.border, required this.fill});

  final Color border;
  final Color fill;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(12, 20);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final rect = Rect.fromCenter(center: center, width: 12, height: 20);
    final paint = Paint()..isAntiAlias = false;
    paint.color = border;
    context.canvas.drawRect(rect, paint);
    paint.color = fill;
    context.canvas.drawRect(rect.deflate(2), paint);
    paint.color = Colors.white.withValues(alpha: 0.35);
    context.canvas.drawRect(
      Rect.fromLTWH(rect.left + 2, rect.top + 2, 2, 4),
      paint,
    );
  }
}

class _PixelTickMarkShape extends SliderTickMarkShape {
  const _PixelTickMarkShape({required this.color});

  final Color color;

  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
  }) => const Size(1, 1);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isEnabled = false,
  }) {
    context.canvas.drawRect(
      Rect.fromLTWH(center.dx.floorToDouble(), center.dy - 1, 1, 2),
      Paint()
        ..isAntiAlias = false
        ..color = color.withValues(alpha: 0.65),
    );
  }
}

class PixelProgressBar extends StatelessWidget {
  const PixelProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 10,
  });

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: value.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => CustomPaint(
          painter: _ProgressPainter(
            value: animated,
            border: p.border,
            track: p.panelAlt,
            fill: color ?? p.gold,
          ),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter({
    required this.value,
    required this.border,
    required this.track,
    required this.fill,
  });

  final double value;
  final Color border;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    canvas.drawRect(Offset.zero & size, paint..color = border);
    final inner = (Offset.zero & size).deflate(2);
    canvas.drawRect(inner, paint..color = track);
    if (value > 0) {
      canvas.drawRect(
        Rect.fromLTWH(inner.left, inner.top, inner.width * value, inner.height),
        paint..color = fill,
      );
    }
    paint.color = border.withValues(alpha: 0.18);
    for (var x = inner.left + 6; x < inner.right; x += 6) {
      canvas.drawRect(Rect.fromLTWH(x, inner.top, 1, inner.height), paint);
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.border != border ||
      oldDelegate.track != track ||
      oldDelegate.fill != fill;
}

// ============================================================================
// 文本 / 表格
// ============================================================================

class PixelInfoRow {
  const PixelInfoRow(
    this.label,
    this.value, {
    this.icon,
    this.mono = false,
    this.valueColor,
    this.trailing,
  });

  final String label;
  final String value;
  final PixelGlyphData? icon;
  final bool mono;
  final Color? valueColor;
  final Widget? trailing;
}

/// 百科信息框的键值行。
class PixelInfoTable extends StatelessWidget {
  const PixelInfoTable({super.key, required this.rows, this.labelWidth = 86});

  final List<PixelInfoRow> rows;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rows[i].icon != null) ...[
                  PixelGlyph(rows[i].icon!, size: 16),
                  const SizedBox(width: 6),
                ],
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    rows[i].label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: p.inkSoft,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rows[i].value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: rows[i].mono
                          ? PixelFont.mono
                          : PixelFont.family,
                      fontFamilyFallback: PixelFont.fallback,
                      fontSize: 12,
                      height: 1.45,
                      color: rows[i].valueColor ?? p.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (rows[i].trailing != null) ...[
                  const SizedBox(width: 6),
                  rows[i].trailing!,
                ],
              ],
            ),
          ),
          if (i != rows.length - 1)
            Container(height: 1, color: p.border.withValues(alpha: 0.18)),
        ],
      ],
    );
  }
}

class PixelCallout extends StatelessWidget {
  const PixelCallout({
    super.key,
    required this.message,
    this.icon = PixelIcons.info,
    this.tone = PixelBadgeTone.link,
    this.title,
  });

  final String message;
  final PixelGlyphData icon;
  final PixelBadgeTone tone;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final accent = switch (tone) {
      PixelBadgeTone.gold => p.goldDeep,
      PixelBadgeTone.link => p.link,
      PixelBadgeTone.danger => p.danger,
      PixelBadgeTone.success => p.success,
      PixelBadgeTone.ink => p.ink,
      PixelBadgeTone.neutral => p.inkSoft,
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        border: Border(
          left: BorderSide(color: accent, width: 4),
          top: BorderSide(color: accent.withValues(alpha: 0.35), width: 1),
          right: BorderSide(color: accent.withValues(alpha: 0.35), width: 1),
          bottom: BorderSide(color: accent.withValues(alpha: 0.35), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PixelGlyph(icon, size: 16, color: accent, accent: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      fontFamily: PixelFont.family,
                      fontFamilyFallback: PixelFont.fallback,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                if (title != null) const SizedBox(height: 2),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: p.ink, height: 1.65),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PixelLink extends StatefulWidget {
  const PixelLink(this.label, {super.key, this.onTap, this.color});

  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  State<PixelLink> createState() => _PixelLinkState();
}

class _PixelLinkState extends State<PixelLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final c = _hover ? p.goldDeep : (widget.color ?? p.link);
    return Semantics(
      link: true,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (v) => setState(() => _hover = v),
        mouseCursor: SystemMouseCursors.click,
        hoverColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 100),
          style: TextStyle(
            fontFamily: PixelFont.family,
            fontFamilyFallback: PixelFont.fallback,
            fontSize: 12,
            color: c,
            decoration: TextDecoration.underline,
            decorationColor: c.withValues(alpha: 0.45),
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

// ============================================================================
// 折叠 / 标签页
// ============================================================================

class PixelExpansion extends StatefulWidget {
  const PixelExpansion({
    super.key,
    required this.header,
    required this.child,
    this.initiallyExpanded = false,
    this.headerColor,
  });

  final Widget header;
  final Widget child;
  final bool initiallyExpanded;
  final Color? headerColor;

  @override
  State<PixelExpansion> createState() => _PixelExpansionState();
}

class _PixelExpansionState extends State<PixelExpansion> {
  late bool _open = widget.initiallyExpanded;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          onHover: (v) => setState(() => _hover = v),
          mouseCursor: SystemMouseCursors.click,
          hoverColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            color: _hover ? p.goldSoft : (widget.headerColor ?? p.panelAlt),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(child: widget.header),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: PixelGlyph(
                    PixelIcons.chevronDown,
                    size: 16,
                    color: p.inkSoft,
                    accent: p.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _open
              ? Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: p.border, width: 1)),
                  ),
                  child: widget.child,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class PixelTab {
  const PixelTab(this.label, {this.icon});
  final String label;
  final PixelGlyphData? icon;
}

/// 百科页签（MediaWiki 风格）。
class PixelTabs extends StatelessWidget {
  const PixelTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
    this.expanded = false,
  });

  final List<PixelTab> tabs;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final row = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < tabs.length; i++)
          if (expanded) Expanded(child: _tab(context, i)) else _tab(context, i),
      ],
    );
    final strip = Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.border, width: 2)),
      ),
      child: expanded
          ? row
          : SingleChildScrollView(scrollDirection: Axis.horizontal, child: row),
    );
    return strip;
  }

  Widget _tab(BuildContext context, int i) {
    final p = PixelPalette.of(context);
    final selectedNow = i == selected;
    return InkWell(
      onTap: () => onChanged(i),
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedNow ? p.panel : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: selectedNow ? p.gold : Colors.transparent,
              width: 3,
            ),
            left: BorderSide(
              color: selectedNow ? p.border : Colors.transparent,
              width: 2,
            ),
            right: BorderSide(
              color: selectedNow ? p.border : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tabs[i].icon != null) ...[
              PixelGlyph(
                tabs[i].icon!,
                size: 16,
                color: selectedNow ? p.ink : p.inkSoft,
              ),
              const SizedBox(width: 6),
            ],
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 120),
              style: TextStyle(
                fontFamily: PixelFont.family,
                fontFamilyFallback: PixelFont.fallback,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: selectedNow ? p.ink : p.inkSoft,
              ),
              child: Text(tabs[i].label),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 输入
// ============================================================================

class PixelTextField extends StatelessWidget {
  const PixelTextField({
    super.key,
    this.controller,
    this.hint,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.mono = false,
    this.prefixIcon,
    this.suffix,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.style,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? hint;
  final int maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool mono;
  final PixelGlyphData? prefixIcon;
  final Widget? suffix;
  final bool readOnly;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      readOnly: readOnly,
      autofocus: autofocus,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlignVertical: maxLines > 1
          ? TextAlignVertical.top
          : TextAlignVertical.center,
      style:
          style ??
          TextStyle(
            fontFamily: mono ? PixelFont.mono : PixelFont.family,
            fontFamilyFallback: PixelFont.fallback,
            fontSize: 12,
            height: maxLines > 1 ? 1.55 : 1.4,
            color: p.ink,
          ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 10, right: 6),
                child: PixelGlyph(prefixIcon!, size: 16),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

// ============================================================================
// 对话框 / 底部抽屉 / 提示
// ============================================================================

class PixelDialog extends StatelessWidget {
  const PixelDialog({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
    this.actions = const [],
    this.onClose,
    this.maxWidth = 460,
  });

  final String title;
  final Widget child;
  final PixelGlyphData? icon;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: PixelPanel(
          title: title,
          subtitle: subtitle,
          icon: icon ?? PixelIcons.scroll,
          trailing: PixelIconButton(
            icon: PixelIcons.close,
            tooltip: '关闭',
            size: PixelButtonSize.small,
            onPressed: onClose ?? () => Navigator.of(context).pop(),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(child: SingleChildScrollView(child: child)),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showPixelDialog<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  String? subtitle,
  PixelGlyphData? icon,
  List<Widget> actions = const [],
  double maxWidth = 460,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black54,
    barrierLabel: '关闭对话框',
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (dialogContext, animation, secondaryAnimation) => PixelDialog(
      title: title,
      subtitle: subtitle,
      icon: icon,
      maxWidth: maxWidth,
      onClose: () => Navigator.of(dialogContext).pop(),
      actions: actions,
      child: child,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Future<T?> showPixelSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
  double maxWidth = 640,
}) {
  final p = PixelPalette.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (sheetContext) => Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: p.paper,
            border: Border(
              top: BorderSide(color: p.gold, width: 4),
              left: BorderSide(color: p.border, width: 2),
              right: BorderSide(color: p.border, width: 2),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: p.inkFaint,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void showPixelToast(
  BuildContext context,
  String message, {
  bool error = false,
  PixelGlyphData? icon,
}) {
  final p = PixelPalette.of(context);
  final bg = error ? p.danger : p.ink;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: bg,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: p.gold, width: PixelSize.border),
        ),
        content: Row(
          children: [
            PixelGlyph(
              icon ?? (error ? PixelIcons.warning : PixelIcons.check),
              size: 16,
              color: p.panel,
              accent: p.gold,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: PixelFont.family,
                  fontFamilyFallback: PixelFont.fallback,
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  color: p.panel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
