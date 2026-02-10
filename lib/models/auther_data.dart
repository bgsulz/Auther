import 'dart:convert';
import 'package:auther/models/person.dart';

class AutherData {
  AutherData.empty() : this(userHash: '', codes: []);
  bool get isEmpty => userHash.isEmpty && codes.isEmpty;

  String userHash = '';
  List<Person> codes = [];

  AutherData({
    this.userHash = '',
    required this.codes,
  });

  factory AutherData.fromJson(Map<String, dynamic> json, String hash) {
    final codesJson = json['codes'];
    if (codesJson == null || codesJson is! List) {
      return AutherData(userHash: hash, codes: []);
    }
    return AutherData(
      userHash: hash,
      codes: List<Person>.from(codesJson.map((x) => Person.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() => {
        'codes': List<dynamic>.from(codes.map((x) => x.toJson())),
      };

  String toJsonString() => jsonEncode(toJson());

  List<Person> getVisibleCodes(String text) {
    if (text.isEmpty) {
      return codes;
    } else {
      final textClean = text.toLowerCase().trim();
      return codes
          .where((e) => e.name.toLowerCase().contains(textClean))
          .toList();
    }
  }
}
