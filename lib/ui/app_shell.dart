import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_info.dart';
import '../main.dart';
import '../state/editor_controller.dart';
import '../theme/pixel_theme.dart';
import 'screens/characters_screen.dart';
import 'screens/data_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/save_screen.dart';
import 'widgets/common.dart';
import 'widgets/pixel_icons.dart';
import 'widgets/pixel_kit.dart';

class NavDestination {
  const NavDestination(this.label, this.shortLabel, this.icon, this.builder);

  final String label;
  final String shortLabel;
  final PixelGlyphData icon;
  final WidgetBuilder builder;
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static final List<NavDestination> _destinations = [
    NavDestination('存档工坊', '存档', PixelIcons.save, (_) => const SaveScreen()),
    NavDestination('总览', '总览', PixelIcons.grid, (_) => const OverviewScreen()),
    NavDestination(
      '角色档案',
      '角色',
      PixelIcons.person,
      (_) => const CharactersScreen(),
    ),
    NavDestination(
      '物品数据库',
      '背包',
      PixelIcons.bag,
      (_) => const InventoryScreen(),
    ),
    NavDestination(
      '进度档案',
      '进度',
      PixelIcons.trophy,
      (_) => const ProgressScreen(),
    ),
    NavDestination('数据源', '数据', PixelIcons.book, (_) => const DataScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final deps = AppDeps.of(context);
    final controller = deps.controller;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= PixelLayout.wide;

    return EditorScope(
      controller: controller,
      child: ListenableBuilder(
        listenable: deps.navIndex,
        builder: (context, _) {
          final index = deps.navIndex.value.clamp(0, _destinations.length - 1);

          final content = IndexedStack(
            index: index,
            children: [
              for (final d in _destinations)
                Builder(key: ValueKey(d.label), builder: d.builder),
            ],
          );

          return Scaffold(
            backgroundColor: PixelPalette.of(context).paper,
            body: PixelPaperBackground(
              child: Column(
                children: [
                  _TopBar(deps: deps, compact: !wide),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Sidebar(
                                destinations: _destinations,
                                index: index,
                                onSelect: (i) => deps.navIndex.value = i,
                              ),
                              Expanded(child: content),
                            ],
                          )
                        : content,
                  ),
                  if (!wide)
                    _BottomNav(
                      destinations: _destinations,
                      index: index,
                      onSelect: (i) => deps.navIndex.value = i,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// 顶栏：木牌 + 徽标 + 主题切换
// ============================================================================

class _TopBar extends StatelessWidget {
  const _TopBar({required this.deps, required this.compact});

  final AppDeps deps;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: p.paper,
        systemNavigationBarIconBrightness:
            Theme.of(context).brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
      child: Container(
        padding: EdgeInsets.only(top: topInset),
        decoration: BoxDecoration(
          color: p.topBar,
          border: Border(bottom: BorderSide(color: p.gold, width: 4)),
          boxShadow: [
            BoxShadow(
              color: p.shadow,
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: SizedBox(
          height: compact ? 56 : 68,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
            child: Row(
              children: [
                Container(
                  width: compact ? 36 : 44,
                  height: compact ? 36 : 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.topBar,
                    border: Border.all(color: p.topBarSoft, width: 2),
                  ),
                  child: PixelGlyph(
                    PixelIcons.logo,
                    size: compact ? 24 : 32,
                    color: p.topBarInk,
                    accent: p.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SR2 EDITOR',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: PixelFont.family,
                          fontFamilyFallback: PixelFont.fallback,
                          fontSize: compact ? 24 : 24,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: compact ? 1.0 : 2.0,
                          color: p.topBarInk,
                        ),
                      ),
                      if (!compact)
                        Text(
                          'STICK RANGER 2 · 存档编辑器',
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: PixelFont.family,
                            fontFamilyFallback: PixelFont.fallback,
                            fontSize: 12,
                            height: 1.4,
                            letterSpacing: 1.4,
                            color: p.topBarSoft,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ListenableBuilder(
                  listenable: deps.controller,
                  builder: (context, _) => _SaveStatus(
                    loaded: deps.controller.hasSave,
                    compact: compact,
                  ),
                ),
                const SizedBox(width: 8),
                const _ThemeMenu(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveStatus extends StatelessWidget {
  const _SaveStatus({required this.loaded, required this.compact});

  final bool loaded;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final color = loaded ? p.success : p.topBarSoft;
    final label = loaded ? '已载入' : '未载入';
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, color: color),
        if (!compact) ...[
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: PixelFont.family,
              fontFamilyFallback: PixelFont.fallback,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: p.topBarInk,
            ),
          ),
        ],
      ],
    );
    return Tooltip(
      message: loaded ? '存档已载入' : '尚未载入存档',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 7, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: p.topBarSoft, width: 1),
        ),
        child: content,
      ),
    );
  }
}

class _ThemeMenu extends StatelessWidget {
  const _ThemeMenu();

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final settings = AppDeps.of(context).settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final icon = switch (settings.themeMode) {
          ThemeMode.light => PixelIcons.sun,
          ThemeMode.dark => PixelIcons.moon,
          ThemeMode.system => PixelIcons.monitor,
        };
        return PopupMenuButton<ThemeMode>(
          tooltip: '主题模式',
          position: PopupMenuPosition.under,
          offset: const Offset(0, 8),
          color: p.panel,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: p.border, width: 2),
          ),
          onSelected: settings.setThemeMode,
          itemBuilder: (context) => [
            _themeItem(context, ThemeMode.light, '浅色模式', PixelIcons.sun),
            _themeItem(context, ThemeMode.dark, '深色模式', PixelIcons.moon),
            _themeItem(context, ThemeMode.system, '跟随系统', PixelIcons.monitor),
          ],
          child: Container(
            width: 36,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.topBar,
              border: Border.all(color: p.topBarSoft, width: 2),
            ),
            child: PixelGlyph(
              icon,
              size: 16,
              color: p.topBarInk,
              accent: p.gold,
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<ThemeMode> _themeItem(
    BuildContext context,
    ThemeMode mode,
    String label,
    PixelGlyphData icon,
  ) {
    final p = PixelPalette.of(context);
    final current = AppDeps.of(context).settings.themeMode;
    final selected = current == mode;
    return PopupMenuItem<ThemeMode>(
      value: mode,
      height: 36,
      child: Row(
        children: [
          PixelGlyph(
            icon,
            size: 16,
            color: selected ? p.goldDeep : p.inkSoft,
            accent: selected ? p.gold : p.inkSoft,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: PixelFont.family,
              fontFamilyFallback: PixelFont.fallback,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? p.ink : p.inkSoft,
            ),
          ),
          const Spacer(),
          if (selected)
            PixelGlyph(PixelIcons.check, size: 16, color: p.goldDeep),
        ],
      ),
    );
  }
}

// ============================================================================
// 左侧导航
// ============================================================================

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.index,
    required this.onSelect,
  });

  final List<NavDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final controller = AppDeps.of(context).controller;
    final repo = AppDeps.of(context).repository;
    return Container(
      width: 228,
      decoration: BoxDecoration(
        color: p.paperAlt,
        border: Border(right: BorderSide(color: p.border, width: 2)),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PixelSectionLabel('导 航'),
              const SizedBox(height: 8),
              for (var i = 0; i < destinations.length; i++) ...[
                _NavItem(
                  destination: destinations[i],
                  selected: i == index,
                  onTap: () => onSelect(i),
                  trailing: _navTrailing(context, i, controller),
                ),
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 12),
              PixelDivider(color: p.border.withValues(alpha: 0.35)),
              const SizedBox(height: 12),
              const PixelSectionLabel('档 案'),
              const SizedBox(height: 8),
              PixelInfoTable(
                labelWidth: 52,
                rows: [
                  PixelInfoRow(
                    '状态',
                    controller.hasSave ? '已载入' : '未载入',
                    icon: controller.hasSave
                        ? PixelIcons.check
                        : PixelIcons.warning,
                    valueColor: controller.hasSave ? p.success : p.inkFaint,
                  ),
                  if (controller.hasSave)
                    PixelInfoRow('金币', formatInt(controller.gold), mono: true),
                  if (controller.hasSave)
                    PixelInfoRow('等级', '${controller.level}', mono: true),
                  PixelInfoRow(
                    '数据源',
                    controller.catalog.sourceLabel,
                    mono: false,
                  ),
                  if (controller.catalog.sourceLabel == '官网更新' &&
                      repo.updatedAtLabel != null)
                    PixelInfoRow('更新于', repo.updatedAtLabel!, mono: true),
                  const PixelInfoRow('版本', kAppVersion, mono: true),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: p.border.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PixelGlyph(PixelIcons.lock, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '本地离线',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '存档不会上传，除官网数据更新外全程离线。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: p.inkSoft,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: p.border.withValues(alpha: 0.3)),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PixelGlyph(
                      PixelIcons.info,
                      size: 16,
                      color: p.inkFaint,
                      accent: p.gold,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '仅供学习与逆向研究，请支持正版游戏。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: p.inkFaint,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _navTrailing(
    BuildContext context,
    int i,
    EditorController controller,
  ) {
    if (i == 3 && controller.hasSave) {
      return Text(
        '${controller.itemsTotal}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: PixelPalette.of(context).inkFaint,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return null;
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    final selected = widget.selected;
    final fg = selected ? p.panel : p.ink;
    return InkWell(
      onTap: widget.onTap,
      onHover: (v) => setState(() => _hover = v),
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 38,
        decoration: BoxDecoration(
          color: selected ? p.ink : (_hover ? p.goldSoft : Colors.transparent),
          border: Border.all(
            color: selected ? p.ink : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 38,
              color: selected ? p.gold : Colors.transparent,
            ),
            const SizedBox(width: 8),
            PixelGlyph(
              widget.destination.icon,
              size: 16,
              color: selected ? p.gold : p.inkSoft,
              accent: selected ? p.gold : p.inkSoft,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: PixelFont.family,
                  fontFamilyFallback: PixelFont.fallback,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: fg,
                ),
              ),
            ),
            if (widget.trailing != null) ...[
              widget.trailing!,
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 底部导航（窄屏）
// ============================================================================

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.destinations,
    required this.index,
    required this.onSelect,
  });

  final List<NavDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.paperAlt,
        border: Border(top: BorderSide(color: p.border, width: 2)),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            offset: const Offset(0, -2),
            blurRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _BottomItem(
                    destination: destinations[i],
                    selected: i == index,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = PixelPalette.of(context);
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: selected ? p.gold : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PixelGlyph(
              destination.icon,
              size: 16,
              color: selected ? p.goldDeep : p.inkSoft,
              accent: selected ? p.gold : p.inkSoft,
            ),
            const SizedBox(height: 4),
            Text(
              destination.shortLabel,
              style: TextStyle(
                fontFamily: PixelFont.family,
                fontFamilyFallback: PixelFont.fallback,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: selected ? p.ink : p.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
