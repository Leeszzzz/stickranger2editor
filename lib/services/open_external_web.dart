/// Web 实现：直接 window.open 新标签，不经过 url_launcher 插件链路。
@JS()
library;

import 'dart:js_interop';

@JS('open')
external JSAny? _windowOpen(JSString url, JSString target);

Future<bool> openExternal(String url) async {
  final result = _windowOpen(url.toJS, '_blank'.toJS);
  return result != null;
}
