import 'dart:async';
import 'dart:convert';
import 'package:auther/models/person.dart';
import 'package:auther/ui/widgets/codes.dart';
import 'package:auther/customization/config.dart';
import 'package:auther/state/auther_state.dart';

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
    try {
      return AutherData(
        userHash: hash,
        codes: List<Person>.from(json['codes'].map((x) => Person.fromJson(x))),
      );
    } catch (e) {
      return AutherData.empty();
    }
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
