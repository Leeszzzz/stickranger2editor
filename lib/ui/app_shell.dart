import 'package:flutter/material.dart';

import '../main.dart';
import 'screens/characters_screen.dart';
import 'screens/data_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/save_screen.dart';

class NavDestination {
  const NavDestination(this.label, this.icon, this.selectedIcon, this.builder);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static final List<NavDestination> _destinations = [
    NavDestination('存档', Icons.save_outlined, Icons.save, (_) => const SaveScreen()),
    NavDestination('总览', Icons.dashboard_outlined, Icons.dashboard, (_) => const OverviewScreen()),
    NavDestination('角色', Icons.person_outline, Icons.person, (_) => const CharactersScreen()),
    NavDestination('背包', Icons.backpack_outlined, Icons.backpack, (_) => const InventoryScreen()),
    NavDestination('进度', Icons.emoji_events_outlined, Icons.emoji_events, (_) => const ProgressScreen()),
    NavDestination('数据', Icons.cloud_sync_outlined, Icons.cloud_sync, (_) => const DataScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deps = AppDeps.of(context);
    final controller = deps.controller;
    final wide = MediaQuery.sizeOf(context).width >= 880;

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

          final appBar = _ShellAppBar(
            deps: deps,
            title: _destinations[index].label,
            showLoadChip: index != 0,
          );

          final body = Scaffold(
            appBar: appBar,
            body: wide
                ? Row(
                    children: [
                      ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: NavigationRail(
                          selectedIndex: index,
                          // 导航与空态跳转共用 navIndex 单一数据源。
                          onDestinationSelected: (i) => deps.navIndex.value = i,
                          labelType: NavigationRailLabelType.all,
                          destinations: [
                            for (final d in _destinations)
                              NavigationRailDestination(
                                icon: Icon(d.icon),
                                selectedIcon: Icon(d.selectedIcon),
                                label: Text(d.label),
                              ),
                          ],
                        ),
                      ),
                      VerticalDivider(width: 1, color: theme.dividerTheme.color),
                      Expanded(child: content),
                    ],
                  )
                : content,
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    selectedIndex: index,
                    onDestinationSelected: (i) => deps.navIndex.value = i,
                    destinations: [
                      for (final d in _destinations)
                        NavigationDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: d.label,
                        ),
                    ],
                  ),
          );
          return body;
        },
      ),
    );
  }
}

class _ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ShellAppBar({
    required this.deps,
    required this.title,
    required this.showLoadChip,
  });

  final AppDeps deps;
  final String title;
  final bool showLoadChip;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = deps.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videogame_asset_rounded,
                color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style:
                  theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          if (!controller.hasSave && showLoadChip)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: Icon(Icons.upload_file_outlined,
                    size: 16, color: theme.colorScheme.primary),
                label: const Text('载入存档'),
                onPressed: () => deps.navIndex.value = 0,
              ),
            ),
          const _ThemeMenu(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ThemeMenu extends StatelessWidget {
  const _ThemeMenu();

  @override
  Widget build(BuildContext context) {
    final settings = AppDeps.of(context).settings;
    return PopupMenuButton<ThemeMode>(
      tooltip: '主题模式',
      icon: const Icon(Icons.contrast),
      onSelected: settings.setThemeMode,
      itemBuilder: (context) => [
        _item(context, ThemeMode.light, '浅色模式', Icons.light_mode_outlined),
        _item(context, ThemeMode.dark, '深色模式', Icons.dark_mode_outlined),
        _item(context, ThemeMode.system, '跟随系统', Icons.settings_suggest_outlined),
      ],
    );
  }

  PopupMenuItem<ThemeMode> _item(
      BuildContext context, ThemeMode mode, String label, IconData icon) {
    final current = AppDeps.of(context).settings.themeMode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color:
                  current == mode ? Theme.of(context).colorScheme.primary : null),
          const SizedBox(width: 10),
          Text(label),
          if (current == mode) ...[
            const Spacer(),
            Icon(Icons.check,
                size: 16, color: Theme.of(context).colorScheme.primary),
          ],
        ],
      ),
    );
  }
}
