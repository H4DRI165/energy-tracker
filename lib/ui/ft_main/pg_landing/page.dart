import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  Timer? _redirectTimer;
  late final AnimationController _controller;

  // Staggered reveal animations
  late final Animation<double> _bgFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _heroFade;
  late final Animation<double> _pill1Fade;
  late final Animation<double> _pill2Fade;
  late final Animation<double> _pill3Fade;
  late final Animation<double> _bottomFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bgFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );

    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.55, curve: Curves.easeOut),
      ),
    );

    _heroFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.55, curve: Curves.easeOut),
    );

    _pill1Fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
    );

    _pill2Fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );

    _pill3Fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
    );

    _bottomFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1, curve: Curves.easeOut),
    );

    unawaited(_controller.forward().then((_) => _scheduleRedirect()));
  }

  void _scheduleRedirect() {
    // Skip timer if user has accessibility needs (reduced motion / slow animations)
    final accessibilityFeatures = WidgetsBinding.instance.accessibilityFeatures;
    final mediaQuery = MediaQueryData.fromView(
      WidgetsBinding.instance.platformDispatcher.views.first,
    );
    final prefersReducedMotion =
        mediaQuery.disableAnimations || accessibilityFeatures.reduceMotion;

    if (prefersReducedMotion) {
      // Go immediately — don't force a timed wait on accessibility users
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.login);
      });
      return;
    }

    _redirectTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) context.go(AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _bgFade,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF060912), Color(0xFF0D1A2E)],
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _bgFade,
            child: Align(
              alignment: const Alignment(0, -0.3),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  FadeTransition(
                    opacity: _heroFade,
                    child: SlideTransition(
                      position: _heroSlide,
                      child: Text(
                        '⚡ ENERGY TRACKER',
                        style: AppTextStyles.overline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _heroFade,
                    child: SlideTransition(
                      position: _heroSlide,
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.displayLg.copyWith(height: 1.15),
                          children: const [
                            TextSpan(text: 'Track your\n'),
                            TextSpan(
                              text: 'TNB energy',
                              style: TextStyle(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _heroFade,
                    child: SlideTransition(
                      position: _heroSlide,
                      child: Text(
                        'Monitor usage, set budgets, and\n'
                        'never get surprised by your bill again.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.text2,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _pill1Fade,
                    child: const _FeaturePill(
                      icon: '📊',
                      label: 'Real-time usage tracking',
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _pill2Fade,
                    child: const _FeaturePill(
                      icon: '🎯',
                      label: 'Monthly budget alerts',
                      color: AppColors.accent2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _pill3Fade,
                    child: const _FeaturePill(
                      icon: '📄',
                      label: 'Scan TNB bills instantly',
                      color: AppColors.accent3,
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _bottomFade,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _redirectTimer?.cancel();
                            if (mounted) context.go(AppRoutes.login);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color:
                                      AppColors.accent.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Taking you to sign in...',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.text3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tap to skip',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });
  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: AppColors.text3,
          ),
        ],
      ),
    );
  }
}
