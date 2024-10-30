import 'package:auther/customization/config.dart';
import 'package:flutter/material.dart';

class Style {
  static TextStyle? _serif;
  static TextStyle get serif => _serif ??= TextStyle(
        fontFamily: 'Roboto-Serif',
        fontVariations: [
          FontVariation("wght", 500),
          FontVariation("wdth", 50),
        ],
      );

  static Text autherTitle(BuildContext context) {
    var style = Theme.of(context).textTheme.headlineLarge;
    return Text(
      Config.autherName,
      style: style!.copyWith(
        fontSize: 64,
      ),
    );
  }
}
