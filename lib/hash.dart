import 'dart:convert';
import '../customization/words.dart';
import 'package:crypto/crypto.dart';

class AutherHash {
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
}
