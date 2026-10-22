import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthPageScaffold extends StatefulWidget {
  const AuthPageScaffold({
    required this.header,
    required this.child,
    this.footer,
    this.topSpacing = 8,
    this.footerPadding,
    super.key,
  });

  final Widget header;
  final Widget child;
  final Widget? footer;
  final double topSpacing;
  final EdgeInsetsGeometry? footerPadding;

  @override
  State<AuthPageScaffold> createState() => _AuthPageScaffoldState();
}

class _AuthPageScaffoldState extends State<AuthPageScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF060912),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF060912), Color(0xFF0D1A2E)],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -90,
            child: _AuthGlow(
              size: 360.r,
              color: const Color(0xFF00D4AA).withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -110,
            child: _AuthGlow(
              size: 420.r,
              color: const Color(0xFF0099FF).withValues(alpha: 0.14),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 600;
                    final padding = EdgeInsets.symmetric(
                      horizontal: compact ? 14.w : 32.w,
                      vertical: compact ? 20.h : 32.h,
                    );
                    final minHeight = (constraints.maxHeight - padding.vertical)
                        .clamp(
                          0.0,
                          double.infinity,
                        );

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: padding,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minHeight),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(
                                compact ? 20.r : 28.r,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24.r),
                                border: Border.all(
                                  color: AppColors.borderAccent,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 40,
                                    offset: const Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: widget.topSpacing.h),
                                  widget.header,
                                  SizedBox(height: 32.h),
                                  widget.child,
                                  if (!keyboardOpen && widget.footer != null)
                                    Padding(
                                      padding:
                                          widget.footerPadding ??
                                          EdgeInsets.only(top: 20.h),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: widget.footer,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthGlow extends StatelessWidget {
  const _AuthGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 16.r,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap ?? () => Navigator.of(context).pop(),
      tooltip: 'Back',
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 16.r,
      ),
      style: IconButton.styleFrom(
        minimumSize: Size(44.r, 44.r),
        maximumSize: Size(44.r, 44.r),
        padding: EdgeInsets.zero,
        backgroundColor: AppColors.surface2,
        foregroundColor: AppColors.text2,
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
      ),
    );
  }
}
