import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/ft_auth/ft_register/notifier/register_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
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

    unawaited(_controller.forward());

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideIn =
        Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24.h),
                        const _Header(),
                        SizedBox(height: 32.h),
                        const _BodyContent(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingH,
                    vertical: 24.h,
                  ),
                  child: const _LoginAccountRow(),
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
        Text(
          'Get Started',
          style: AppTextStyles.overline.copyWith(color: AppColors.accent),
        ),
        SizedBox(height: 8.h),
        Text(
          'Create Account',
          style: AppTextStyles.displayMd,
        ),
        SizedBox(height: 6.h),
        Text(
          'Track your TNB energy usage & bills',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.text2,
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
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _tnbAccountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmedPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final state = ref.read(registerProvider.notifier);

    _fullNameController.addListener(() {
      state.setFullName(_fullNameController.text);
    });
    _emailController.addListener(() {
      state.setEmail(_emailController.text);
    });
    _tnbAccountController.addListener(() {
      state.setTnbAccount(_tnbAccountController.text);
    });
    _passwordController.addListener(() {
      state.setPassword(_passwordController.text);
    });
    _confirmedPasswordController.addListener(() {
      state.setConfirmedPassword(_confirmedPasswordController.text);
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _tnbAccountController.dispose();
    _passwordController.dispose();
    _confirmedPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextFloatingLabelField(
          controller: _fullNameController,
          labelText: 'Full Name',
          hintText: 'Enter your full name',
          border: AppFormFieldBorder.roundedOutlined,
          prefixIcon: Icon(
            Icons.person_outline,
            size: 20.r,
            color: AppColors.text3,
          ),
          errorText: state.fullNameError,
          clearable: true,
          maxLength: 60,
          inputFormatters: [
            LengthLimitingTextInputFormatter(60),
            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s'\-\.]")),
          ],
        ),
        SizedBox(height: 16.h),
        AppTextFloatingLabelField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          labelText: 'Email Address',
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
        SizedBox(height: 16.h),
        AppTextFloatingLabelField(
          controller: _tnbAccountController,
          keyboardType: TextInputType.number,
          labelText: 'TNB Account No.',
          hintText: 'e.g. 123456789012',
          border: AppFormFieldBorder.roundedOutlined,
          prefixIcon: Icon(
            Icons.receipt_long_outlined,
            size: 20.r,
            color: AppColors.text3,
          ),
          errorText: state.tnbAccountError,
          clearable: true,
          maxLength: 12,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
        ),
        SizedBox(height: 16.h),
        AppTextFloatingLabelField(
          controller: _passwordController,
          labelText: 'Password',
          hintText: 'Create a strong password',
          border: AppFormFieldBorder.roundedOutlined,
          prefixIcon: Icon(
            Icons.lock_outlined,
            size: 20.r,
            color: AppColors.text3,
          ),
          errorText: state.passwordError,
          obscureText: state.obscurePassword,
          suffixIcon: IconButton(
            onPressed: ref
                .read(registerProvider.notifier)
                .toggleObscurePassword,
            icon: Icon(
              state.obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.text3,
              size: 20.r,
            ),
          ),
        ),
        if (_passwordController.text.isNotEmpty) ...[
          SizedBox(height: 8.h),
          _PasswordStrengthBar(
            strength: state.passwordStrength,
            label: state.strengthLabel,
            color: state.strengthColor ?? AppColors.text3,
            password: _passwordController.text,
          ),
        ],
        SizedBox(height: 16.h),
        AppTextFloatingLabelField(
          controller: _confirmedPasswordController,
          labelText: 'Confirm Password',
          hintText: 'Confirm your password',
          border: AppFormFieldBorder.roundedOutlined,
          prefixIcon: Icon(
            Icons.lock_outline,
            size: 20.r,
            color: AppColors.text3,
          ),
          errorText: state.confirmedPasswordError,
          obscureText: state.obscureConfirmedPassword,
          suffixIcon: IconButton(
            onPressed: ref
                .read(registerProvider.notifier)
                .toggleObscureConfirmedPassword,
            icon: Icon(
              state.obscureConfirmedPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.text3,
              size: 20.r,
            ),
          ),
        ),
        SizedBox(height: 24.h),
        if (state.authError != null) ...[
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.danger,
                  size: 16.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    state.authError!,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
        ],
        GradientButton(
          label: 'Create Account',
          isLoading: state.isLoading,
          onTap: _handleRegister,
        ),
        SizedBox(height: 12.h),
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.text3,
                height: 1.6,
              ),
              children: const [
                TextSpan(text: 'By creating an account you agree to our '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(color: AppColors.accent2),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(color: AppColors.accent2),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 32.h),
      ],
    );
  }

  Future<void> _handleRegister() async {
    final notifier = ref.read(registerProvider.notifier);
    await notifier.register();

    if (!mounted) return;

    final state = ref.read(registerProvider);

    final hasValidationErrors =
        state.fullNameError != null ||
        state.emailError != null ||
        state.tnbAccountError != null ||
        state.passwordError != null ||
        state.confirmedPasswordError != null;

    final shouldNavigate =
        state.authError == null && !state.isLoading && !hasValidationErrors;

    if (shouldNavigate) {
      context.go(AppRoutes.onboarding);
    }
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({
    required this.strength,
    required this.label,
    required this.color,
    required this.password,
  });

  final int strength;
  final String label;
  final Color color;
  final String password;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4.h,
                decoration: BoxDecoration(
                  color: i < strength ? color : AppColors.surface3,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: 12.h),
        _RequirementItem(
          text: 'At least 8 characters',
          isMet: password.length >= 8,
        ),
        _RequirementItem(
          text: 'Contains uppercase letter (A-Z)',
          isMet: password.contains(RegExp('[A-Z]')),
        ),
        _RequirementItem(
          text: 'Contains a number (0-9)',
          isMet: password.contains(RegExp('[0-9]')),
        ),
        _RequirementItem(
          text: r'Contains special character (!@#$&*~%^())',
          isMet: password.contains(RegExp(r'[!@#\$&*~%^()]')),
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  const _RequirementItem({
    required this.text,
    required this.isMet,
  });

  final String text;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: isMet ? AppColors.accent : AppColors.text3,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySm.copyWith(
                fontSize: 13.sp,
                color: isMet ? AppColors.text : AppColors.text2,
                decoration: isMet ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginAccountRow extends StatelessWidget {
  const _LoginAccountRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
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
