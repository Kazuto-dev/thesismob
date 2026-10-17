import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<bool> saveFile(String name, Uint8List bytes, String mimeType) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = name
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  // Give the browser a moment to start the download before releasing it.
  Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
  return true;
}

Future<String?> pickTextFile({String accept = '.json'}) {
  final completer = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept
    ..style.display = 'none';
  input.onchange = (web.Event _) {
    final file = input.files?.item(0);
    input.remove();
    if (file == null) {
      completer.complete(null);
      return;
    }
    file.text().toDart.then(
      (text) => completer.complete(text.toDart),
      onError: (Object _) => completer.complete(null),
    );
  }.toJS;
  input.oncancel = (web.Event _) {
    input.remove();
    if (!completer.isCompleted) completer.complete(null);
  }.toJS;
  web.document.body?.append(input);
  input.click();
  return completer.future;
}

bool openUrl(String url) {
  web.window.open(url, '_blank', 'noopener');
  return true;
}
