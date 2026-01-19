import 'package:json_annotation/json_annotation.dart';

part 'person.g.dart';

/// Pure data class representing a person in the user's contact list.
/// Use AutherAuth.getSayCode/getHearCode for code generation.
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

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
  Map<String, dynamic> toJson() => _$PersonToJson(this);
}
