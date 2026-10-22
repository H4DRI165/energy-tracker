import 'dart:async';

import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';

/// Groups skeleton placeholders under one shimmer animation.
class Skeleton extends StatefulWidget {
  const Skeleton({
    required this.child,
    this.semanticsLabel = 'Loading',
    super.key,
  });

  final Widget child;
  final String semanticsLabel;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ExcludeSemantics(child: widget.child);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final base = AppColors.surface3;
    final highlight = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.18),
      base,
    );

    return Semantics(
      label: widget.semanticsLabel,
      container: true,
      child: reduceMotion
          ? content
          : AnimatedBuilder(
              animation: _controller,
              child: content,
              builder: (context, child) {
                final shift = -1.5 + (_controller.value * 3);
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment(shift, 0),
                    end: Alignment(shift + 1.2, 0),
                    colors: [base, highlight, base],
                    stops: const [0.25, 0.5, 0.75],
                  ).createShader(bounds),
                  child: child,
                );
              },
            ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.height,
    this.width,
    this.borderRadius,
    super.key,
  });

  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    this.width,
    this.height = 10,
    super.key,
  });

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(height / 2),
    );
  }
}
