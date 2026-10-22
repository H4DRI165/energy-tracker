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

class _RegisterPageState extends ConsumerState<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    return const AuthPageScaffold(
      topSpacing: 0,
      header: AuthHeader(
        title: 'Create your account',
        subtitle: 'Start tracking your TNB usage and bills.',
      ),
      footer: _LoginAccountRow(),
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
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _tnbAccountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmedPasswordController = TextEditingController();

  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _tnbAccountFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmedPasswordFocusNode = FocusNode();

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
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _tnbAccountFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmedPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerProvider);
    final fieldScrollPadding = EdgeInsets.only(bottom: 80.h);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextFloatingLabelField(
          controller: _fullNameController,
          focusNode: _fullNameFocusNode,
          labelText: 'Full Name',
          hintText: 'e.g. Ahmad Faiz bin Ali',
          border: AppFormFieldBorder.roundedOutlined,
          prefixIcon: Icon(
            Icons.person_outline,
            size: 20.r,
            color: AppColors.text3,
          ),
          errorText: state.fullNameError,
          autofillHints: const [AutofillHints.name],
          clearable: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _emailFocusNode.requestFocus(),
          scrollPadding: fieldScrollPadding,
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
        ),
        SizedBox(height: 16.h),
        AppTextFloatingLabelField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          labelText: 'Email Address',
          hintText: 'name@example.com',
          border: AppFormFieldBorder.roundedOutlined,
          prefixIcon: Icon(
            Icons.email_outlined,
            size: 20.r,
            color: AppColors.text3,
          ),
          errorText: state.emailError,
          autofillHints: const [AutofillHints.email],
          enableSuggestions: false,
          autocorrect: false,
          clearable: true,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _tnbAccountFocusNode.requestFocus(),
          scrollPadding: fieldScrollPadding,
        ),
        SizedBox(height: 16.h),
        AppTextFloatingLabelField(
          controller: _tnbAccountController,
          focusNode: _tnbAccountFocusNode,
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
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passwordFocusNode.requestFocus(),
          scrollPadding: fieldScrollPadding,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          'Used to match your TNB account. Must be 12 digits.',
          style: AppTextStyles.caption.copyWith(color: AppColors.text3),
        ),
        SizedBox(height: 16.h),
        AppTextFloatingLabelField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          autofillHints: const [AutofillHints.newPassword],
          enableSuggestions: false,
          autocorrect: false,
          labelText: 'Password',
          hintText: '8+ characters with uppercase, number and symbol',
          border: AppFormFieldBorder.roundedOutlined,
          prefixIcon: Icon(
            Icons.lock_outlined,
            size: 20.r,
            color: AppColors.text3,
          ),
          errorText: state.passwordError,
          obscureText: state.obscurePassword,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _confirmedPasswordFocusNode.requestFocus(),
          scrollPadding: fieldScrollPadding,
          suffixIcon: IconButton(
            tooltip: state.obscurePassword ? 'Show password' : 'Hide password',
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
          focusNode: _confirmedPasswordFocusNode,
          labelText: 'Confirm Password',
          border: AppFormFieldBorder.roundedOutlined,
          prefixIcon: Icon(
            Icons.lock_outline,
            size: 20.r,
            color: AppColors.text3,
          ),
          errorText: state.confirmedPasswordError,
          autofillHints: const [AutofillHints.newPassword],
          enableSuggestions: false,
          autocorrect: false,
          obscureText: state.obscureConfirmedPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleRegister(),
          scrollPadding: fieldScrollPadding,
          suffixIcon: IconButton(
            tooltip: state.obscureConfirmedPassword
                ? 'Show password'
                : 'Hide password',
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
          AuthErrorBanner(message: state.authError!),
          SizedBox(height: 16.h),
        ],
        GradientButton(
          label: 'Create Account',
          isLoading: state.isLoading,
          onTap: _handleRegister,
        ),
      ],
    );
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
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
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.text2,
          ),
        ),
        TextButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.login),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            minimumSize: const Size(48, 44),
          ),
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
