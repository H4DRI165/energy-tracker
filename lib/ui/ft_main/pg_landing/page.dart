import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _bgFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _heroFade;
  late final Animation<double> _featureTopFade;
  late final Animation<double> _featureBottomFade;
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

    _heroSlide =
        Tween<Offset>(
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

    _featureTopFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
    );

    _featureBottomFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );

    _bottomFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1, curve: Curves.easeOut),
    );

    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
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
              decoration: BoxDecoration(
                gradient: AppColors.splashGradient,
              ),
            ),
          ),
          FadeTransition(
            opacity: _bgFade,
            child: Align(
              alignment: const Alignment(0, -0.3),
              child: Container(
                width: 300.w,
                height: 300.h,
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
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingH,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 48.h),
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
                        SizedBox(height: 16.h),
                        FadeTransition(
                          opacity: _heroFade,
                          child: SlideTransition(
                            position: _heroSlide,
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.displayLg.copyWith(
                                  height: 1.15,
                                ),
                                children: [
                                  const TextSpan(text: 'Track your\n'),
                                  TextSpan(
                                    text: 'TNB energy',
                                    style: TextStyle(color: AppColors.accent),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
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
                        SizedBox(height: 36.h),
                        FadeTransition(
                          opacity: _featureTopFade,
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _FeatureCard(
                                    icon: Icons.query_stats_rounded,
                                    title: 'Usage trends',
                                    subtitle: 'Based on meter readings',
                                    color: AppColors.accent,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: _FeatureCard(
                                    icon: Icons.notifications_active_rounded,
                                    title: 'Budget alerts',
                                    subtitle: '80% and 100% warnings',
                                    color: AppColors.accent2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        FadeTransition(
                          opacity: _featureBottomFade,
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _FeatureCard(
                                    icon: Icons.receipt_long_rounded,
                                    title: 'Bill estimate',
                                    subtitle: 'Every charge explained',
                                    color: AppColors.accent3,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: _FeatureCard(
                                    icon: Icons.electrical_services_rounded,
                                    title: 'Appliance costs',
                                    subtitle: 'Running-cost estimates',
                                    color: AppColors.warn,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        FadeTransition(
                          opacity: _bottomFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GradientButton(
                                label: 'Get started',
                                isLoading: false,
                                onTap: () => context.go(AppRoutes.login),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Sign in or create an account to start '
                                'tracking.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.text3,
                                ),
                              ),
                              SizedBox(height: 24.h),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17.r, color: color),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            style: AppTextStyles.bodySm.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.text3,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}
