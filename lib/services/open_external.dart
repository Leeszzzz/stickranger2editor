/// 打开外部链接的平台实现切换：Web 用 window.open 新标签，
/// IO 平台（Windows/Android）走系统默认浏览器（url_launcher）。
library;

export 'open_external_io.dart'
    if (dart.library.html) 'open_external_web.dart';
