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

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return const AuthPageScaffold(
      topSpacing: 0,
      header: AuthHeader(
        title: 'Welcome back',
        subtitle: 'Sign in to track your TNB usage and bills.',
      ),
      footer: _RegisterAccountRow(),
      child: _BodyContent(),
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

  void _submit() {
    FocusScope.of(context).unfocus();
    unawaited(ref.read(loginProvider.notifier).login());
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
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          autofillHints: const [AutofillHints.email],
          enableSuggestions: false,
          autocorrect: false,
          labelText: 'Email',
          hintText: 'name@example.com',
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
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          autofillHints: const [AutofillHints.password],
          enableSuggestions: false,
          autocorrect: false,
          labelText: 'Password',
          border: AppFormFieldBorder.roundedOutlined,
          prefixIcon: Icon(
            Icons.lock_outlined,
            size: 20.r,
            color: AppColors.text3,
          ),
          errorText: state.passwordError,
          obscureText: state.obscurePassword,
          suffixIcon: IconButton(
            tooltip: state.obscurePassword ? 'Show password' : 'Hide password',
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
        SizedBox(height: 8.h),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(AppRoutes.forgotPassword),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              minimumSize: const Size(48, 44),
            ),
            child: Text(
              'Forgot password?',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.accent,
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        if (state.authError != null) ...[
          AuthErrorBanner(message: state.authError!),
          SizedBox(height: 16.h),
        ],
        GradientButton(
          label: 'Sign In',
          isLoading: state.isLoading && !state.isGoogleLoading,
          isEnabled: !state.isLoading,
          onTap: _submit,
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
          child: state.isGoogleLoading
              ? SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.text),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24.r,
                      height: 24.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4285F4),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: Text(
                        'Continue with Google',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLg.copyWith(
                          color: AppColors.text,
                        ),
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
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.text2,
          ),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.register),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            minimumSize: const Size(48, 44),
          ),
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
