import 'package:flutter/material.dart';

class StringIcon extends StatelessWidget {
  const StringIcon({
    required this.icon,
    required this.gradient,
    required this.border,
    super.key,
  });

  final String icon;
  final LinearGradient gradient;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Text(
          icon,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
