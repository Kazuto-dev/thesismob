import 'dart:typed_data';

import 'files_stub.dart'
    if (dart.library.js_interop) 'files_web.dart'
    as platform;

/// Saves [bytes] as a download called [name]. Returns false where saving
/// files is not supported.
Future<bool> saveFile(String name, Uint8List bytes, String mimeType) =>
    platform.saveFile(name, bytes, mimeType);

/// Lets the user pick a file and returns its text, or null when they
/// cancel or picking is not supported.
Future<String?> pickTextFile({String accept = '.json'}) =>
    platform.pickTextFile(accept: accept);
