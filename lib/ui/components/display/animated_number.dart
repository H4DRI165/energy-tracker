import 'package:flutter/material.dart';

/// Text that eases between numeric values instead of snapping on rebuild.
///
/// The first build shows the final value without animating. Later changes
/// animate from the currently displayed value to the new one.
class AnimatedNumberText extends StatelessWidget {
  const AnimatedNumberText({
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 420),
    this.curve = Curves.easeOutCubic,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final double value;
  final String Function(double value) formatter;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : duration;

    return Semantics(
      label: formatter(value),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: value, end: value),
        duration: effectiveDuration,
        curve: curve,
        builder: (context, animatedValue, _) {
          return Text(
            formatter(animatedValue),
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          );
        },
      ),
    );
  }
}
