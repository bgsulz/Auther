import 'dart:convert';
import 'package:auther/words.dart';
import 'package:crypto/crypto.dart';
import 'package:otp/otp.dart';

class AutherHash {
  static const int refreshIntervalSeconds = 30;

  static String hashPassphrase(String value) {
    return sha256.convert(Utf8Encoder().convert(value)).toString();
  }

  static String getOTP(String myHash, String theirHash) {
    var code = OTP.generateTOTPCode(myHash + theirHash, DateTime.now().millisecondsSinceEpoch,
          interval: refreshIntervalSeconds,
          length: 9)
          .toString()
          .padLeft(9, '0');
    var indices = [
      int.parse(code.substring(0, 3)),
      int.parse(code.substring(3, 6)),
      int.parse(code.substring(6))
    ];
    return indices.map((index) => Words.getWord(index)).join(' ');
  }
  
  static String getRef() => getOTP("ref", "ref");
  static int getSecondsUntilChange() => OTP.remainingSeconds(interval: refreshIntervalSeconds);
  static int getMillisUntilChange() => getSecondsUntilChange() * 1000;
  static double getProgressUntilChange() => 1 - (AutherHash.getSecondsUntilChange() / AutherHash.refreshIntervalSeconds);

  static bool compareCodewords(String truth, String entered)
  {
    var truthNoWhitespace = truth.replaceAll(' ', '');
    var enteredNoWhitespace = entered.replaceAll(' ', '');
    return truthNoWhitespace.toLowerCase() == enteredNoWhitespace.toLowerCase();
  }
}
