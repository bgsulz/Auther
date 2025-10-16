import 'package:json_annotation/json_annotation.dart';
import '../services/auth_service.dart';

part 'person.g.dart';

@JsonSerializable()
class Person {
  final String personHash;
  final String name;
  final bool isBroken;

  const Person({
    required this.personHash,
    required this.name,
    this.isBroken = false,
  });

  Person copyWith({String? personHash, String? name, bool? isBroken}) {
    return Person(
      personHash: personHash ?? this.personHash,
      name: name ?? this.name,
      isBroken: isBroken ?? this.isBroken,
    );
  }

  String hearAuthCode(String userHash, int seed) {
    return AutherAuth.getOTP(userHash, personHash, seed);
  }

  String sayAuthCode(String userHash, int seed) {
    return AutherAuth.getOTP(personHash, userHash, seed);
  }

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
  Map<String, dynamic> toJson() => _$PersonToJson(this);
}
