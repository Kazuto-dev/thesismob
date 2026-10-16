import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

final _random = Random.secure();

/// Crockford's base 32: no I, L, O or U, so a code read aloud or typed
/// from an email is hard to get wrong.
const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// A new activation code such as `BQ-7K2M-9QXD-4HTR-W8NC`: 80 random bits
/// in four groups of four.
String newActivationCode() {
  final b = StringBuffer('BQ');
  for (var group = 0; group < 4; group++) {
    b.write('-');
    for (var i = 0; i < 4; i++) {
      b.write(_alphabet[_random.nextInt(32)]);
    }
  }
  return b.toString();
}

/// [code] as typed, reduced to its 16 characters: case, spaces, dashes
/// and the `BQ` prefix ignored, and O, I and L read as 0, 1 and 1.
/// Null when it cannot be a code.
String? normalizeActivationCode(String code) {
  var s = code.toUpperCase().replaceAll(RegExp(r'[\s\-_]'), '');
  if (s.startsWith('BQ')) s = s.substring(2);
  s = s.replaceAll('O', '0').replaceAll('I', '1').replaceAll('L', '1');
  if (s.length != 16) return null;
  for (final c in s.split('')) {
    if (!_alphabet.contains(c)) return null;
  }
  return s;
}

/// What is stored for a code or session token: its SHA-256, so a copy of
/// the database does not give away codes that still work.
Uint8List hashSecret(String secret) =>
    Uint8List.fromList(sha256.convert(utf8.encode(secret)).bytes);

/// A new session token: 256 random bits, base64url.
String newSessionToken() => base64Url
    .encode(List<int>.generate(32, (_) => _random.nextInt(256)))
    .replaceAll('=', '');
