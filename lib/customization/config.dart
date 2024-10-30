class Config {
  static const int intervalSec = 30;
  static const int intervalMillis = intervalSec * 1000;

  static const String autherName = 'Auther';

  static const String autherSubtitle =
      "Auther is a codeword generator to protect against identity cloning scams.";

  static const String autherDescription =
      "When you're in-person with people close to you, exchange QR codes to "
      "register yourself on each other's device.\n\n"
      "Then, when you chat remotely with that person, exchange codewords to "
      "verify each other's identity.";

  static const String passphraseEnter = "Enter a secret passphrase.";

  static const String passphraseGuidelines =
      "Choose something easy to remember and hard to guess.";

  static const String passphraseKey = 'passphrase';
}
