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

  // UI: Color strip settings
  static const int colorStripCount = 4;
  static const List<int> colorPalette = [
    0xFF1F77B4,
    0xFFFF7F0E,
    0xFF2CA02C,
    0xFFD62728,
    0xFF9467BD,
    0xFF8C564B,
    0xFFE377C2,
    0xFF7F7F7F,
    0xFFBCBD22,
    0xFF17BECF,
    0xFF003F5C,
    0xFFFFA600,
  ];
}
