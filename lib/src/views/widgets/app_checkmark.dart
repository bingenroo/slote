import 'package:flutter/material.dart';

class AppCheckmark extends StatelessWidget {
  final Color? color;
  final Color? iconColor;
  final double size;
  const AppCheckmark({super.key, this.color, this.iconColor, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.check,
          color: iconColor ?? Colors.white,
          size: size * 0.7,
        ),
      ),
    );
  }
}
