import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/ft_auth/ft_login/notifier/login_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
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
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenPaddingH,
                        vertical: AppDimensions.screenPaddingV,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8.h),
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
                      vertical: 16.h,
                    ),
                    child: const _RegisterAccountRow(),
                  ),
                ],
              ),
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
        Text('Welcome back', style: AppTextStyles.overline),
        SizedBox(height: 8.h),
        Text('Sign In', style: AppTextStyles.displayMd),
        SizedBox(height: 6.h),
        Text(
          'Track your TNB energy usage',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
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
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(loginProvider.notifier);

    _emailController.addListener(() {
      state.setEmail(_emailController.text);
    });
    _passwordController.addListener(() {
      state.setPassword(_passwordController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);

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
        SizedBox(height: 16.h),
        AppTextFloatingLabelField(
          controller: _passwordController,
          labelText: 'Password',
          hintText: 'Enter your password',
          border: AppFormFieldBorder.roundedOutlined,
          prefixIcon: Icon(
            Icons.lock_outlined,
            size: 20.r,
            color: AppColors.text3,
          ),
          errorText: state.passwordError,
          obscureText: state.obscurePassword,
          suffixIcon: IconButton(
            onPressed: ref.read(loginProvider.notifier).toggleObscure,
            icon: Icon(
              state.obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.text3,
              size: 20.r,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go(AppRoutes.forgotPassword),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot password?',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.accent,
              ),
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
          label: 'Sign In',
          isLoading: state.isLoading,
          onTap: ref.read(loginProvider.notifier).login,
        ),
        SizedBox(height: 20.h),
        const AppDivider(middleText: 'or continue with'),
        SizedBox(height: 16.h),
        OutlinedButton(
          onPressed: state.isLoading
              ? null
              : ref.read(loginProvider.notifier).loginWithGoogle,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
          child: state.isLoading
              ? SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.text),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'G',
                      style: AppTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Continue with Google',
                      style: AppTextStyles.bodyLg.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _RegisterAccountRow extends StatelessWidget {
  const _RegisterAccountRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.text2,
          ),
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.register),
          child: Text(
            'Register',
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
