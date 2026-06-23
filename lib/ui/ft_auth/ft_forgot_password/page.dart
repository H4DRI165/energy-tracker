import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/ft_auth/ft_forgot_password/notifier/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    unawaited(_animationController.forward());

    _fadeIn =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideIn,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenPaddingH,
                      vertical: AppDimensions.screenPaddingV,
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(),
                        SizedBox(height: 32),
                        _BodyContent(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingH,
                    vertical: 24,
                  ),
                  child: _BackToLoginRow(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StringIcon(
          icon: '🔑',
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x2600D4AA), Color(0x1A0099FF)],
          ),
          border: AppColors.borderAccent,
        ),
        SizedBox(height: 20.h),
        Text('Reset Password', style: AppTextStyles.displayMd),
        SizedBox(height: 8.h),
        Text(
          "Enter your registered email and we'll send you a "
          'link to reset your password.',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.text2,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _BodyContent extends ConsumerStatefulWidget {
  const _BodyContent();

  @override
  ConsumerState<_BodyContent> createState() => _BodyContentState();
}

class _BodyContentState extends ConsumerState<_BodyContent> {
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      ref.read(forgotPasswordProvider.notifier).setEmail(_emailController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);

    if (state.step == ForgotPasswordStep.emailSent) {
      return ForgotPasswordSuccess(
        email: state.email,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextFloatingLabelField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          labelText: 'Email',
          hintText: 'Enter your email',
          border: AppFormFieldBorder.roundedOutlined,
          prefixIcon: Icon(
            Icons.email_outlined,
            size: 20.r,
            color: AppColors.text3,
          ),
          errorText: state.emailError,
          clearable: true,
        ),
        if (state.errorMessage != null) ...[
          SizedBox(height: 16.h),
          _ErrorBanner(message: state.errorMessage!),
        ],
        SizedBox(height: 28.h),
        GradientButton(
          label: 'Send Reset Link',
          isLoading: state.isLoading,
          onTap: ref.read(forgotPasswordProvider.notifier).sendResetEmail,
        ),
        SizedBox(height: 20.h),
        const _InfoCard(
          icon: Icons.info_outline_rounded,
          text: "Check your spam folder if you don't "
              'see the email within a few minutes.',
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 18.r,
          ),
          SizedBox(width: 10.w),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.text,
  });
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.r, color: AppColors.text3),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySm),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordSuccess extends StatelessWidget {
  const ForgotPasswordSuccess({
    required this.email,
    super.key,
  });

  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 40.h),
        Container(
          width: 96.r,
          height: 96.r,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(0xFF00C853),
                AppColors.accent,
              ],
            ),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 52.r,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 32.h),
        Text(
          'Reset Link Sent',
          style: AppTextStyles.displayMd,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.h),
        Text(
          "We've sent a password reset link to",
          style: AppTextStyles.bodyLg.copyWith(color: AppColors.text2),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          email,
          style: AppTextStyles.titleMd.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 40.h),
        const _InfoCard(
          icon: Icons.mark_email_read_outlined,
          text: "Didn't receive the email? Check spam or try again.",
        ),
      ],
    );
  }
}

class _BackToLoginRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Remember your password? ',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.text2,
          ),
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.login),
          child: Text(
            'Sign In',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
