/// IO 平台（Windows / Android）实现：调起系统默认浏览器。
library;

import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternal(String url) async {
  try {
    return await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}
