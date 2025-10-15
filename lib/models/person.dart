import 'package:auther/services/auth_service.dart';

class Person {
  Person({
    required this.personHash,
    this.name = "Default Title",
  });

  final String personHash;
  String name;
  bool _isBroken = false;
  bool get isBroken => _isBroken;

  String hearAuthCode(String userHash, int seed) {
    return AutherAuth.getOTP(userHash, personHash, seed);
  }

  String sayAuthCode(String userHash, int seed) {
    return AutherAuth.getOTP(personHash, userHash, seed);
  }

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        personHash = json['personHash'] as String,
        _isBroken = json['isBroken'] as bool;

  Map<String, dynamic> toJson() => {
        'name': name,
        'personHash': personHash,
        'isBroken': isBroken,
      };

  void breakConnection() {
    print("BREAKING CONNECTION FOR $name");
    _isBroken = true;
  }
}
