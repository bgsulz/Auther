import 'package:flutter/material.dart';
import 'package:auther/services/auth_service.dart';

class ColorStrip extends StatelessWidget {
  final int slot;
  final double height;
  final int count;

  const ColorStrip({super.key, required this.slot, this.height = 8, this.count = 4});

  @override
  Widget build(BuildContext context) {
    final colors = AutherAuth.colorsForSlot(slot, count: count);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Row(
        children: List.generate(colors.length, (i) {
          return Expanded(
            child: Container(
              height: height,
              color: colors[i],
            ),
          );
        }),
      ),
    );
  }
}
