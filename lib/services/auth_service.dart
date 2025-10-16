import 'dart:convert';
import '../../customization/words.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'dart:typed_data';

class AutherAuth {
  static const int refreshIntervalSeconds = 30;

  static String hashPassphrase(String value) {
    return sha256.convert(Utf8Encoder().convert(value)).toString();
  }

  static String qrFromHash(String userHash) => "AutherCode_$userHash";
  static String hashFromQr(String value) =>
      value.replaceFirst("AutherCode_", "");

  static bool isPlausibleQr(String value) => isPlausibleHash(hashFromQr(value));
  static bool isPlausibleHash(String value) =>
      value.length == 64 && RegExp(r'^[0-9a-f]+$').hasMatch(value);

  static String getOTP(String myHash, String theirHash, int seed) {
    var utf = Utf8Encoder().convert(myHash + theirHash + seed.toString());
    var sha = sha256.convert(utf).toString();
    var code =
        BigInt.parse(sha, radix: 16).toString().padLeft(9, '0').substring(0, 9);
    var indices = [
      int.parse(code.substring(0, 3)),
      int.parse(code.substring(3, 6)),
      int.parse(code.substring(6))
    ];
    return indices.map((index) => Words.wordAt(index)).join(' ');
  }

  static bool compareAuthcodes(String truth, String entered) {
    var truthNoWhitespace = truth.replaceAll(' ', '');
    var enteredNoWhitespace = entered.replaceAll(' ', '');
    return truthNoWhitespace.toLowerCase() == enteredNoWhitespace.toLowerCase();
  }

  static const int kdfIterations = 200000;
  static const int kdfKeyLength = 32;
  static const String kdfAlgo = 'pbkdf2-hmac-sha256';
  static const int kdfVersion = 1;

  static Uint8List _hmacSha256(Uint8List key, Uint8List data) {
    final h = Hmac(sha256, key);
    final digest = h.convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  static Uint8List _int32be(int i) {
    final b = ByteData(4);
    b.setUint32(0, i, Endian.big);
    return b.buffer.asUint8List();
  }

  static Uint8List _pbkdf2(Uint8List password, Uint8List salt, int iterations, int dkLen) {
    final hLen = 32;
    final l = (dkLen / hLen).ceil();
    final r = dkLen - (l - 1) * hLen;
    final out = BytesBuilder();
    for (int i = 1; i <= l; i++) {
      final si = BytesBuilder();
      si.add(salt);
      si.add(_int32be(i));
      Uint8List u = _hmacSha256(password, si.toBytes());
      Uint8List t = Uint8List.fromList(u);
      for (int c = 1; c < iterations; c++) {
        u = _hmacSha256(password, u);
        for (int k = 0; k < t.length; k++) {
          t[k] ^= u[k];
        }
      }
      out.add(t);
    }
    final outBytes = out.toBytes();
    return Uint8List.fromList(outBytes.sublist(0, dkLen == 0 ? outBytes.length : (l == 1 ? r : dkLen)));
  }

  static Uint8List _genSalt(int length) {
    final rnd = Random.secure();
    final b = List<int>.generate(length, (_) => rnd.nextInt(256));
    return Uint8List.fromList(b);
  }

  static Map<String, dynamic> deriveCredentials(String passphrase) {
    final salt = _genSalt(16);
    final dk = _pbkdf2(Uint8List.fromList(utf8.encode(passphrase)), salt, kdfIterations, kdfKeyLength);
    final record = <String, dynamic>{
      'algo': kdfAlgo,
      'iterations': kdfIterations,
      'saltB64': base64Encode(salt),
      'derivedKeyHex': sha256.convert(dk).toString(),
      'version': kdfVersion,
    };
    return record;
  }

  static bool _ctEq(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int r = 0;
    for (int i = 0; i < a.length; i++) {
      r |= a[i] ^ b[i];
    }
    return r == 0;
  }

  static bool verifyPassphrase(String passphrase, Map<String, dynamic> record) {
    if (record['algo'] != kdfAlgo) return false;
    final iterations = record['iterations'] as int;
    final salt = base64Decode(record['saltB64'] as String);
    final expectedHex = record['derivedKeyHex'] as String;
    final dk = _pbkdf2(Uint8List.fromList(utf8.encode(passphrase)), Uint8List.fromList(salt), iterations, kdfKeyLength);
    final actualHex = sha256.convert(dk).toString();
    return _ctEq(Uint8List.fromList(utf8.encode(actualHex)), Uint8List.fromList(utf8.encode(expectedHex)));
  }
}
