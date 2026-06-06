import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/ft_auth/ft_login/notifier/login_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
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
                        SizedBox(height: 8),
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
                    vertical: 16,
                  ),
                  child: _RegisterAccountRow(),
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
        Text('Welcome back', style: AppTextStyles.overline),
        const SizedBox(height: 8),
        Text('Sign In', style: AppTextStyles.displayMd),
        const SizedBox(height: 6),
        Text(
          'Track your TNB energy usage',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
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
  final _passwordController = TextEditingController();
  late final LoginNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = LoginNotifier();
    _emailController.addListener(() {
      _notifier.setEmail(_emailController.text);
    });
    _passwordController.addListener(() {
      _notifier.setPassword(_passwordController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
              border: AppFormFieldBorder.roundedOutlined,
              prefixIcon: const Icon(
                Icons.lock_outlined,
                size: 20,
                color: AppColors.text3,
              ),
              errorText: state.passwordError,
              obscureText: state.obscurePassword,
              suffixIcon: IconButton(
                onPressed: _notifier.toggleObscure,
                icon: Icon(
                  state.obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.text3,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.pushNamed(AppRoutes.forgotPassword),
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
            const SizedBox(height: 24),
            if (state.authError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.danger,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.authError!,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            GradientButton(
              label: 'Sign In',
              isLoading: _notifier.state.isLoading,
              onTap: _notifier.login,
            ),
            const SizedBox(height: 20),
            const AppDivider(middleText: 'or continue with'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed:
                  _notifier.state.isLoading ? null : _notifier.loginWithGoogle,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _notifier.state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.text),
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
                        const SizedBox(width: 10),
                        Text(
                          'Continue with Google',
                          style: AppTextStyles.bodyLg
                              .copyWith(color: AppColors.text),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
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
          onTap: () => context.pushNamed(AppRoutes.register),
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
