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

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  @override
  Widget build(BuildContext context) {
    return const AuthPageScaffold(
      topSpacing: 0,
      header: _Header(),
      footer: _BackToLoginRow(),
      child: _BodyContent(),
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
        AuthBackButton(
          onTap: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.login),
        ),
        SizedBox(height: 4.h),
        StringIcon(
          icon: '🔑',
          gradient: const LinearGradient(
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
          textInputAction: TextInputAction.done,
          onSubmitted: (_) =>
              ref.read(forgotPasswordProvider.notifier).sendResetEmail(),
        ),
        if (state.errorMessage != null) ...[
          SizedBox(height: 16.h),
          AuthErrorBanner(message: state.errorMessage!),
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
          text:
              "Check your spam folder if you don't "
              'see the email within a few minutes.',
        ),
      ],
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

class ForgotPasswordSuccess extends ConsumerWidget {
  const ForgotPasswordSuccess({
    required this.email,
    super.key,
  });

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forgotPasswordProvider);
    final notifier = ref.read(forgotPasswordProvider.notifier);

    return Column(
      children: [
        SizedBox(height: 24.h),
        Container(
          width: 96.r,
          height: 96.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.accent,
                AppColors.accent2,
              ],
            ),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 52.r,
            color: AppColors.onAccent,
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
        if (state.errorMessage != null) ...[
          SizedBox(height: 20.h),
          AuthErrorBanner(message: state.errorMessage!),
        ],
        SizedBox(height: 28.h),
        GradientButton(
          label: 'Resend email',
          isLoading: state.isLoading,
          onTap: notifier.resendResetEmail,
        ),
        SizedBox(height: 8.h),
        TextButton(
          onPressed: notifier.editEmail,
          style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
          child: Text(
            'Use a different email',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.accent),
          ),
        ),
        SizedBox(height: 8.h),
        const _InfoCard(
          icon: Icons.mark_email_read_outlined,
          text: "Didn't receive the email? Check your spam folder first.",
        ),
      ],
    );
  }
}

class _BackToLoginRow extends StatelessWidget {
  const _BackToLoginRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Remember your password? ',
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
