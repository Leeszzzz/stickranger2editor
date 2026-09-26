import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/data_repository.dart';
import 'state/editor_controller.dart';
import 'theme/app_theme.dart';
import 'ui/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repo = DataRepository(prefs);
  final catalog = await repo.load();
  final settings = SettingsController(prefs)..load();
  runApp(
    SR2EditorApp(
      controller: EditorController(catalog: catalog),
      settings: settings,
      repository: repo,
    ),
  );
}

class AppDeps extends InheritedWidget {
  AppDeps({
    super.key,
    required this.controller,
    required this.settings,
    required this.repository,
    required super.child,
  }) : navIndex = ValueNotifier(0);

  final EditorController controller;
  final SettingsController settings;
  final DataRepository repository;

  /// 当前导航页索引（供空态按钮跳转到「存档」页）。
  final ValueNotifier<int> navIndex;

  static AppDeps of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppDeps>()!;

  @override
  bool updateShouldNotify(AppDeps oldWidget) => false;
}

/// 订阅编辑器状态变化（InheritedNotifier）。
class EditorScope extends InheritedNotifier<EditorController> {
  const EditorScope({super.key, required EditorController controller, required super.child})
      : super(notifier: controller);

  static EditorController watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EditorScope>()!.notifier!;

  /// 只读取不订阅。
  static EditorController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<EditorScope>()!.notifier!;
}

class SR2EditorApp extends StatelessWidget {
  const SR2EditorApp({
    super.key,
    required this.controller,
    required this.settings,
    required this.repository,
  });

  final EditorController controller;
  final SettingsController settings;
  final DataRepository repository;

  @override
  Widget build(BuildContext context) {
    return AppDeps(
      controller: controller,
      settings: settings,
      repository: repository,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: 'SR2 存档编辑器',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          home: AppShell(),
        ),
      ),
    );
  }
}
