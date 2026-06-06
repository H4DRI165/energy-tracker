import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_onboarding/notifier/onboarding_notifier.dart';
import 'package:energy_tracker/ui/features/ft_onboarding/notifier/onboarding_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final OnboardingNotifier _notifier;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _notifier = OnboardingNotifier();
    _pageController = PageController();
    _notifier.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (_pageController.hasClients) {
      unawaited(
        _pageController.animateToPage(
          _notifier.state.currentStep,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        ),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _notifier
      ..removeListener(_onStateChanged)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _notifier.state;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _notifier.canGoBack) _notifier.goBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _OnboardingHeader(
                state: state,
                onBack: _notifier.canGoBack ? _notifier.goBack : null,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StepTariff(
                      state: state,
                      notifier: _notifier,
                    ),
                    _StepBudget(
                      state: state,
                      notifier: _notifier,
                    ),
                    _StepComplete(
                      state: state,
                      notifier: _notifier,
                      onStartTracking: _handleComplete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleComplete() async {
    final success = await _notifier.completeOnboarding();
    if (success && mounted) {
      context.go(AppRoutes.dashboard);
    }
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.state,
    this.onBack,
  });

  final OnboardingPageState state;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onBack != null)
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: AppColors.text2,
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),
              Text(
                '${state.currentStep + 1} of ${OnboardingPageState.totalSteps}',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
              ),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: state.progressValue,
              backgroundColor: AppColors.surface3,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _StepTariff extends StatelessWidget {
  const _StepTariff({
    required this.state,
    required this.notifier,
  });

  final OnboardingPageState state;
  final OnboardingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const StringIcon(
            icon: '🏠',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x2600D4AA), Color(0x1A0099FF)],
            ),
            border: AppColors.borderAccent,
          ),
          const SizedBox(height: 16),
          Text('Select Tariff Type', style: AppTextStyles.titleLg),
          const SizedBox(height: 8),
          Text(
            'Choose your TNB account category',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
          ),
          const SizedBox(height: 24),
          ...TariffType.values.map((tariff) {
            final isSelected = state.selectedTariff == tariff;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TariffOption(
                tariff: tariff,
                isSelected: isSelected,
                onTap: () => notifier.selectTariff(tariff),
              ),
            );
          }),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Continue',
            isLoading: false,
            onTap: notifier.nextFromTariff,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TariffOption extends StatelessWidget {
  const _TariffOption({
    required this.tariff,
    required this.isSelected,
    required this.onTap,
  });

  final TariffType tariff;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.06)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tariff.icon} ${tariff.label}',
                    style: AppTextStyles.bodyLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tariff.subtitle,
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.black,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBudget extends StatelessWidget {
  const _StepBudget({
    required this.state,
    required this.notifier,
  });

  final OnboardingPageState state;
  final OnboardingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const StringIcon(
            icon: '🎯',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x26FFB020), Color(0x1AFF6B35)],
            ),
            border: Color(0x4DFFB020),
          ),
          const SizedBox(height: 16),
          Text('Set Monthly Target', style: AppTextStyles.titleLg),
          const SizedBox(height: 8),
          Text(
            "We'll alert you before you overspend",
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x2600D4AA), Color(0x140099FF)],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.borderAccent),
            ),
            child: Column(
              children: [
                Text(
                  'MONTHLY BUDGET (RM)',
                  style: AppTextStyles.caption.copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  'RM ${state.monthlyBudget.toStringAsFixed(0)}',
                  style: AppTextStyles.displayLg.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.estimatedKwh,
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surface3,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayColor: AppColors.accent.withValues(alpha: 0.15),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              value: state.monthlyBudget,
              min: OnboardingPageState.minBudget,
              max: OnboardingPageState.maxBudget,
              divisions: 50, // RM 5 increments
              onChanged: notifier.setBudget,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RM 50',
                  style: AppTextStyles.caption.copyWith(color: AppColors.text3),
                ),
                Text(
                  'RM 300',
                  style: AppTextStyles.caption.copyWith(color: AppColors.text3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodySm,
                      children: const [
                        TextSpan(text: 'Average Malaysian household spends '),
                        TextSpan(
                          text: 'RM 120–180',
                          style: TextStyle(
                            color: AppColors.warn,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: '/month on electricity'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Continue',
            isLoading: false,
            onTap: notifier.nextFromBudget,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StepComplete extends StatelessWidget {
  const _StepComplete({
    required this.state,
    required this.notifier,
    required this.onStartTracking,
  });

  final OnboardingPageState state;
  final OnboardingNotifier notifier;
  final VoidCallback onStartTracking;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const StringIcon(
            icon: '🎉',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x260099FF), Color(0x1A00D4AA)],
            ),
            border: Color(0x400099FF),
          ),
          const SizedBox(height: 16),
          Text("You're All Set!", style: AppTextStyles.titleLg),
          const SizedBox(height: 8),
          Text(
            'Energy Tracker is ready to track your usage',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
          ),
          const SizedBox(height: 24),
          _SummaryItem(
            icon: '✅',
            title: 'Tariff configured',
            subtitle: state.selectedTariff.label,
          ),
          const SizedBox(height: 10),
          _SummaryItem(
            icon: '✅',
            title: 'Budget set',
            subtitle: 'RM ${state.monthlyBudget.toStringAsFixed(0)} / month',
          ),
          const SizedBox(height: 10),
          const _SummaryItem(
            icon: '🔔',
            title: 'Alerts enabled',
            subtitle: '80% & 100% notifications',
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
                      state.errorMessage!,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          GradientButton(
            label: 'Start Tracking ⚡',
            isLoading: state.isLoading,
            onTap: onStartTracking,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.bodySm),
            ],
          ),
        ],
      ),
    );
  }
}
