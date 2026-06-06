import 'dart:async';

import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/buttons.dart';
import 'package:energy_tracker/ui/components/icons.dart';
import 'package:energy_tracker/ui/components/text.dart';
import 'package:energy_tracker/ui/ft_auth/ft_forgot_password/notifier/forgot_password_notifier.dart';
import 'package:energy_tracker/ui/ft_auth/ft_forgot_password/notifier/forgot_password_state.dart';
import 'package:energy_tracker/ui/routes/routes.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
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
                const Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenPaddingH,
                      vertical: AppDimensions.screenPaddingV,
                    ),
                    child: Column(
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
                  padding: const EdgeInsets.symmetric(
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
        const SizedBox(height: 20),
        Text('Reset Password', style: AppTextStyles.displayMd),
        const SizedBox(height: 8),
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

class _BodyContent extends StatefulWidget {
  const _BodyContent();

  @override
  State<_BodyContent> createState() => _BodyContentState();
}

class _BodyContentState extends State<_BodyContent> {
  final _emailController = TextEditingController();
  late final ForgotPasswordNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ForgotPasswordNotifier();
    _emailController.addListener(() {
      _notifier.setEmail(_emailController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _notifier,
      builder: (context, child) {
        final state = _notifier.state;

        if (state.step == ForgotPasswordStep.emailSent) {
          return ForgotPasswordSuccess(
            email: state.email,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              labelText: 'Email',
              hintText: 'Enter your email',
              border: AppFormFieldBorder.roundedOutlined,
              prefixIcon: const Icon(
                Icons.email_outlined,
                size: 20,
                color: AppColors.text3,
              ),
              errorText: state.emailError,
              clearable: true,
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: state.errorMessage!),
            ],
            const SizedBox(height: 28),
            GradientButton(
              label: 'Send Reset Link',
              isLoading: state.isLoading,
              onTap: _notifier.sendResetEmail,
            ),
            const SizedBox(height: 20),
            const _InfoCard(
              icon: Icons.info_outline_rounded,
              text: "Check your spam folder if you don't "
                  'see the email within a few minutes.',
            ),
          ],
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.text3),
          const SizedBox(width: 10),
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
        const SizedBox(height: 40),
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(0xFF00C853),
                AppColors.accent,
              ],
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 52,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Reset Link Sent',
          style: AppTextStyles.displayMd,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          "We've sent a password reset link to",
          style: AppTextStyles.bodyLg.copyWith(color: AppColors.text2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          email,
          style: AppTextStyles.titleMd.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
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
