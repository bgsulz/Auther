// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Person _$PersonFromJson(Map<String, dynamic> json) => Person(
      personHash: json['personHash'] as String,
      name: json['name'] as String,
      isBroken: json['isBroken'] as bool? ?? false,
    );

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
      'personHash': instance.personHash,
      'name': instance.name,
      'isBroken': instance.isBroken,
    };
