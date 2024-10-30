import 'package:flutter/material.dart';

class Style {
  static TextStyle serif() {
    return TextStyle(
      fontFamily: 'Roboto-Serif',
      fontVariations: [FontVariation("wght", 500), FontVariation("wdth", 50)],
    );
  }
}
