import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/ft_auth/ft_register/notifier/register_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
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
    )..forward();

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideIn = Tween<Offset>(
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
            child: const Column(
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
                        SizedBox(height: 24),
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
                  child: _LoginAccountRow(),
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
        const SizedBox(height: 8),
        Text(
          'Create Account',
          style: AppTextStyles.displayMd,
        ),
        const SizedBox(height: 6),
        const Text(
          'Track your TNB energy usage & bills',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.text2,
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
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _tnbAccountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmedPasswordController = TextEditingController();

  late final RegisterNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = RegisterNotifier();

    _fullNameController.addListener(() {
      _notifier.setFullName(_fullNameController.text);
    });
    _emailController.addListener(() {
      _notifier.setEmail(_emailController.text);
    });
    _tnbAccountController.addListener(() {
      _notifier.setTnbAccount(_tnbAccountController.text);
    });
    _passwordController.addListener(() {
      _notifier.setPassword(_passwordController.text);
    });
    _confirmedPasswordController.addListener(() {
      _notifier.setConfirmedPassword(_confirmedPasswordController.text);
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _tnbAccountController.dispose();
    _passwordController.dispose();
    _confirmedPasswordController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _notifier,
      builder: (context, child) {
        final state = _notifier.state;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _fullNameController,
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              border: AppFormFieldBorder.roundedOutlined,
              prefixIcon: const Icon(
                Icons.person_outline,
                size: 20,
                color: Colors.grey,
              ),
              errorText: state.fullNameError,
              clearable: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              labelText: 'Email Address',
              hintText: 'Enter your email',
              border: AppFormFieldBorder.roundedOutlined,
              prefixIcon: const Icon(
                Icons.email_outlined,
                size: 20,
                color: Colors.grey,
              ),
              errorText: state.emailError,
              clearable: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _tnbAccountController,
              keyboardType: TextInputType.number,
              labelText: 'TNB Account No.',
              hintText: 'e.g. 1234567890',
              border: AppFormFieldBorder.roundedOutlined,
              prefixIcon: const Icon(
                Icons.receipt_long_outlined,
                size: 20,
                color: Colors.grey,
              ),
              errorText: state.tnbAccountError,
              clearable: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Create a strong password',
              border: AppFormFieldBorder.roundedOutlined,
              prefixIcon: const Icon(
                Icons.lock_outlined,
                size: 20,
                color: Colors.grey,
              ),
              errorText: state.passwordError,
              obscureText: state.obscurePassword,
              suffixIcon: IconButton(
                onPressed: _notifier.toggleObscurePassword,
                icon: Icon(
                  state.obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.text3,
                  size: 20,
                ),
              ),
            ),
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _PasswordStrengthBar(
                strength: state.passwordStrength,
                label: state.strengthLabel,
                color: state.strengthColor ?? AppColors.text3,
                password: _passwordController.text,
              ),
            ],
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmedPasswordController,
              labelText: 'Confirm Password',
              hintText: 'Confirm your password',
              border: AppFormFieldBorder.roundedOutlined,
              prefixIcon: const Icon(
                Icons.lock_outline,
                size: 20,
                color: Colors.grey,
              ),
              errorText: state.confirmedPasswordError,
              obscureText: state.obscureConfirmedPassword,
              suffixIcon: IconButton(
                onPressed: _notifier.toggleObscureConfirmedPassword,
                icon: Icon(
                  state.obscureConfirmedPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.text3,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (state.authError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.authError!,
                        style: AppTextStyles.bodySm.copyWith(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _GradientButton(
              label: 'Create Account',
              isLoading: state.isLoading,
              onTap: _handleRegister,
            ),
            const SizedBox(height: 12),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.text3,
                    height: 1.6,
                  ),
                  children: [
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
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Future<void> _handleRegister() async {
    await _notifier.register();

    if (!mounted) return;

    if (_notifier.state.authError == null && !_notifier.state.isLoading) {
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
                height: 4,
                decoration: BoxDecoration(
                  color: i < strength ? color : AppColors.surface3,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: isMet ? AppColors.accent : AppColors.text3,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySm.copyWith(
                fontSize: 13,
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

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: AppColors.btnPrimaryShadow,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Text(
                  label,
                  style: AppTextStyles.button,
                ),
        ),
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
          onTap: () => Navigator.of(context).pop(),
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
