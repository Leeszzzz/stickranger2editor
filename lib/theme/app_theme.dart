/// 应用主题入口：像素百科设计系统。
library;

import 'package:flutter/material.dart';

import 'pixel_theme.dart';

abstract final class AppTheme {
  static ThemeData get light => PixelTheme.light;
  static ThemeData get dark => PixelTheme.dark;

  /// 兼容旧代码的圆角常量：像素风统一为直角。
  static const double radius = 0;
}
