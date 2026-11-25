/// 像素方块（blocky pixel）设计系统。
///
/// 视觉语言：泰拉瑞亚地表 —— 土棕为主色，苔绿作强调，草绿随机洒在土壤表面；
/// 2px 墨线边框、硬投影、12px 像素字体（Fusion Pixel）与 12 的整数倍标题字号。
library;

import 'package:flutter/material.dart';

/// 字体家族名。
abstract final class PixelFont {
  /// Fusion Pixel 12px 比例字体（正文 / 标题）。
  static const family = 'FusionPixel';

  /// Fusion Pixel 12px 等宽字体（存档串 / 数值表格）。
  static const mono = 'FusionPixelMono';

  static const fallback = <String>[
    'Microsoft YaHei UI',
    'Microsoft YaHei',
    'Noto Sans CJK SC',
    'PingFang SC',
    'sans-serif',
  ];
}

/// 像素风调色板（ThemeExtension，深浅两套）。
@immutable
class PixelPalette extends ThemeExtension<PixelPalette> {
  const PixelPalette({
    required this.paper,
    required this.paperAlt,
    required this.panel,
    required this.panelAlt,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.border,
    required this.shadow,
    required this.accent,
    required this.accentDeep,
    required this.accentSoft,
    required this.link,
    required this.danger,
    required this.success,
    required this.info,
    required this.topBar,
    required this.topBarInk,
    required this.topBarSoft,
    required this.selection,
  });

  /// 页面底色（旧纸）。
  final Color paper;

  /// 次级底色（侧栏 / 表头）。
  final Color paperAlt;

  /// 面板内部。
  final Color panel;

  /// 面板表头 / 嵌套块。
  final Color panelAlt;

  /// 主墨色（正文 / 边框）。
  final Color ink;

  /// 次级文字。
  final Color inkSoft;

  /// 弱化文字 / 未激活。
  final Color inkFaint;

  /// 面板边框。
  final Color border;

  /// 硬投影。
  final Color shadow;

  /// 苔绿强调（填充）：草方块顶面。
  final Color accent;

  /// 苔绿强调（可读文字）：深草绿。
  final Color accentDeep;

  /// 苔绿浅底：草叶高光。
  final Color accentSoft;

  /// 百科链接蓝。
  final Color link;

  final Color danger;
  final Color success;
  final Color info;

  /// 顶栏木牌底色。
  final Color topBar;
  final Color topBarInk;
  final Color topBarSoft;

  /// 文本选中色。
  final Color selection;

  static const light = PixelPalette(
    paper: Color(0xFFC9B99A),
    paperAlt: Color(0xFFDCCCB0),
    panel: Color(0xFFE8DCC0),
    panelAlt: Color(0xFFD6C5A6),
    ink: Color(0xFF2E2318),
    inkSoft: Color(0xFF6B5540),
    inkFaint: Color(0xFF9C8768),
    border: Color(0xFF3A2E1E),
    shadow: Color(0x66201308),
    accent: Color(0xFF5C9A3F),
    accentDeep: Color(0xFF356B22),
    accentSoft: Color(0xFFA8CE84),
    link: Color(0xFF2F638D),
    danger: Color(0xFFA83E30),
    success: Color(0xFF4E7C3C),
    info: Color(0xFF3D708F),
    topBar: Color(0xFF2A3B1C),
    topBarInk: Color(0xFFF0E8D4),
    topBarSoft: Color(0xFF9BAF7E),
    selection: Color(0x555C9A3F),
  );

  static const dark = PixelPalette(
    paper: Color(0xFF14100B),
    paperAlt: Color(0xFF1D1811),
    panel: Color(0xFF251E16),
    panelAlt: Color(0xFF302719),
    ink: Color(0xFFEDE3CB),
    inkSoft: Color(0xFFBAA886),
    inkFaint: Color(0xFF827154),
    border: Color(0xFF6B573A),
    shadow: Color(0xCC000000),
    accent: Color(0xFF7CB342),
    accentDeep: Color(0xFFA5D46A),
    accentSoft: Color(0xFF33431F),
    link: Color(0xFF89BFE5),
    danger: Color(0xFFE07A6A),
    success: Color(0xFF93C77F),
    info: Color(0xFF80B7D4),
    topBar: Color(0xFF101508),
    topBarInk: Color(0xFFEDE3CB),
    topBarSoft: Color(0xFF8A9A6A),
    selection: Color(0x557CB342),
  );

  static PixelPalette of(BuildContext context) =>
      Theme.of(context).extension<PixelPalette>() ?? light;

  @override
  PixelPalette copyWith({
    Color? paper,
    Color? paperAlt,
    Color? panel,
    Color? panelAlt,
    Color? ink,
    Color? inkSoft,
    Color? inkFaint,
    Color? border,
    Color? shadow,
    Color? accent,
    Color? accentDeep,
    Color? accentSoft,
    Color? link,
    Color? danger,
    Color? success,
    Color? info,
    Color? topBar,
    Color? topBarInk,
    Color? topBarSoft,
    Color? selection,
  }) {
    return PixelPalette(
      paper: paper ?? this.paper,
      paperAlt: paperAlt ?? this.paperAlt,
      panel: panel ?? this.panel,
      panelAlt: panelAlt ?? this.panelAlt,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkFaint: inkFaint ?? this.inkFaint,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      accent: accent ?? this.accent,
      accentDeep: accentDeep ?? this.accentDeep,
      accentSoft: accentSoft ?? this.accentSoft,
      link: link ?? this.link,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      info: info ?? this.info,
      topBar: topBar ?? this.topBar,
      topBarInk: topBarInk ?? this.topBarInk,
      topBarSoft: topBarSoft ?? this.topBarSoft,
      selection: selection ?? this.selection,
    );
  }

  @override
  PixelPalette lerp(ThemeExtension<PixelPalette>? other, double t) {
    if (other is! PixelPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return PixelPalette(
      paper: mix(paper, other.paper),
      paperAlt: mix(paperAlt, other.paperAlt),
      panel: mix(panel, other.panel),
      panelAlt: mix(panelAlt, other.panelAlt),
      ink: mix(ink, other.ink),
      inkSoft: mix(inkSoft, other.inkSoft),
      inkFaint: mix(inkFaint, other.inkFaint),
      border: mix(border, other.border),
      shadow: mix(shadow, other.shadow),
      accent: mix(accent, other.accent),
      accentDeep: mix(accentDeep, other.accentDeep),
      accentSoft: mix(accentSoft, other.accentSoft),
      link: mix(link, other.link),
      danger: mix(danger, other.danger),
      success: mix(success, other.success),
      info: mix(info, other.info),
      topBar: mix(topBar, other.topBar),
      topBarInk: mix(topBarInk, other.topBarInk),
      topBarSoft: mix(topBarSoft, other.topBarSoft),
      selection: mix(selection, other.selection),
    );
  }
}

/// 文中常用的字号（全部为 12 的整数倍，保证像素字体清晰）。
abstract final class PixelSize {
  static const pageTitle = 48.0;
  static const pageTitleCompact = 36.0;
  static const sectionTitle = 24.0;
  static const value = 36.0;
  static const valueCompact = 24.0;
  static const body = 12.0;
  static const label = 12.0;
  static const border = 2.0;
  static const radius = 0.0;
  static const shadowOffset = 4.0;
}

abstract final class PixelTheme {
  static ThemeData get light => _build(Brightness.light, PixelPalette.light);
  static ThemeData get dark => _build(Brightness.dark, PixelPalette.dark);

  static TextTheme _textTheme(PixelPalette p) {
    TextStyle s(
      double size,
      double height,
      FontWeight weight, {
      double spacing = 0,
    }) => TextStyle(
      fontSize: size,
      height: height,
      fontWeight: weight,
      letterSpacing: spacing,
      color: p.ink,
      fontFamily: PixelFont.family,
      fontFamilyFallback: PixelFont.fallback,
    );

    return TextTheme(
      displayLarge: s(48, 1.15, FontWeight.w700),
      displayMedium: s(36, 1.2, FontWeight.w700),
      displaySmall: s(24, 1.3, FontWeight.w700),
      headlineLarge: s(36, 1.2, FontWeight.w700),
      headlineMedium: s(24, 1.3, FontWeight.w700),
      headlineSmall: s(24, 1.3, FontWeight.w700),
      titleLarge: s(24, 1.3, FontWeight.w700),
      titleMedium: s(12, 1.6, FontWeight.w700, spacing: 0.4),
      titleSmall: s(12, 1.5, FontWeight.w700),
      bodyLarge: s(12, 1.85, FontWeight.w400),
      bodyMedium: s(12, 1.7, FontWeight.w400),
      bodySmall: s(12, 1.6, FontWeight.w400),
      labelLarge: s(12, 1.4, FontWeight.w700, spacing: 0.8),
      labelMedium: s(12, 1.4, FontWeight.w700, spacing: 0.5),
      labelSmall: s(12, 1.4, FontWeight.w400, spacing: 0.3),
    );
  }

  static ThemeData _build(Brightness brightness, PixelPalette p) {
    final base = ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: brightness,
    );
    final scheme = base.copyWith(
      primary: p.ink,
      onPrimary: p.panel,
      primaryContainer: p.accentSoft,
      onPrimaryContainer: p.ink,
      secondary: p.accentDeep,
      onSecondary: p.panel,
      secondaryContainer: p.accentSoft,
      onSecondaryContainer: p.ink,
      tertiary: p.link,
      onTertiary: p.panel,
      error: p.danger,
      onError: p.panel,
      surface: p.panel,
      onSurface: p.ink,
      surfaceContainerHighest: p.panelAlt,
      surfaceContainerHigh: p.paperAlt,
      surfaceContainerLow: p.panel,
      onSurfaceVariant: p.inkSoft,
      outline: p.border,
      outlineVariant: p.inkFaint,
      shadow: p.shadow,
      scrim: Colors.black54,
      inverseSurface: p.ink,
      onInverseSurface: p.paper,
      inversePrimary: p.accent,
      surfaceTint: Colors.transparent,
    );

    final textTheme = _textTheme(
      p,
    ).apply(bodyColor: p.ink, displayColor: p.ink);
    final square = RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
      side: BorderSide(color: p.border, width: PixelSize.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: PixelFont.family,
      fontFamilyFallback: PixelFont.fallback,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: p.paper,
      canvasColor: p.paper,
      cardColor: p.panel,
      dividerColor: p.border,
      shadowColor: p.shadow,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: p.paperAlt,
      focusColor: p.accent.withValues(alpha: 0.16),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [p],
      iconTheme: IconThemeData(color: p.ink, size: 18),
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: PixelSize.border,
        space: PixelSize.border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.paperAlt,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.panel,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.inkFaint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: p.inkSoft),
        helperStyle: textTheme.bodySmall?.copyWith(color: p.inkSoft),
        errorStyle: textTheme.bodySmall?.copyWith(color: p.danger),
        prefixIconColor: p.inkSoft,
        suffixIconColor: p.inkSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: p.border, width: PixelSize.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: p.border, width: PixelSize.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: p.accent, width: PixelSize.border),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: p.danger, width: PixelSize.border),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: p.danger, width: PixelSize.border),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accentDeep,
        selectionColor: p.selection,
        selectionHandleColor: p.accentDeep,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: square,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.panel),
        actionTextColor: p.accent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: p.accent, width: PixelSize.border),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: p.border, width: PixelSize.border),
        ),
        textStyle: textTheme.bodyMedium,
        labelTextStyle: WidgetStatePropertyAll(textTheme.bodyMedium),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        // 边框由 showPixelSheet 自己绘制；这里不能再加边框，
        // 否则 isScrollControlled 的全高 Material 会在抽屉上方多出一条线。
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        dragHandleColor: p.inkFaint,
        dragHandleSize: const Size(40, 4),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.ink,
        unselectedLabelColor: p.inkSoft,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.bodyMedium,
        indicator: BoxDecoration(
          border: Border(bottom: BorderSide(color: p.accent, width: 4)),
        ),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(p.accent.withValues(alpha: 0.1)),
        splashFactory: NoSplash.splashFactory,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 10,
        activeTrackColor: p.accent,
        inactiveTrackColor: p.panelAlt,
        disabledActiveTrackColor: p.inkFaint,
        disabledInactiveTrackColor: p.paperAlt,
        thumbColor: p.ink,
        overlayColor: p.accent.withValues(alpha: 0.14),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 1.5),
        activeTickMarkColor: p.accentSoft,
        inactiveTickMarkColor: p.inkFaint,
        valueIndicatorColor: p.ink,
        valueIndicatorTextStyle: textTheme.bodyMedium?.copyWith(color: p.panel),
        showValueIndicator: ShowValueIndicator.never,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.panel : p.ink,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.panelAlt,
        ),
        trackOutlineColor: WidgetStatePropertyAll(p.border),
        trackOutlineWidth: const WidgetStatePropertyAll(PixelSize.border),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        side: BorderSide(color: p.border, width: PixelSize.border),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.ink : p.panel,
        ),
        checkColor: WidgetStatePropertyAll(p.panel),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.panel,
        selectedColor: p.ink,
        disabledColor: p.paperAlt,
        labelStyle: textTheme.bodyMedium,
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(color: p.panel),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: p.border, width: PixelSize.border),
        ),
        side: BorderSide(color: p.border, width: PixelSize.border),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.panelAlt,
        linearMinHeight: 8,
        refreshBackgroundColor: p.paperAlt,
      ),
      cardTheme: CardThemeData(
        color: p.panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: p.border, width: PixelSize.border),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(p.inkSoft),
        trackColor: WidgetStatePropertyAll(p.paperAlt),
        radius: Radius.zero,
        thickness: WidgetStatePropertyAll(8),
        crossAxisMargin: 2,
        mainAxisMargin: 2,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.ink,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: p.accent, width: PixelSize.border),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: p.panel),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        waitDuration: const Duration(milliseconds: 400),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.link,
          textStyle: textTheme.labelLarge,
          shape: square,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          side: BorderSide(color: p.border, width: PixelSize.border),
          shape: square,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.panel,
          shape: square,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.inkSoft,
        textColor: p.ink,
        titleTextStyle: textTheme.bodyMedium,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: p.inkSoft),
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
