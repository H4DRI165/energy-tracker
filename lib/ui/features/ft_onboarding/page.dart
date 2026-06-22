import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_onboarding/notifier/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    ref.listen(onboardingProvider, (previous, next) {
      if (previous?.currentStep != next.currentStep &&
          _pageController.hasClients) {
        unawaited(
          _pageController.animateToPage(
            next.currentStep,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && notifier.canGoBack) {
          notifier.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _OnboardingHeader(
                state: state,
                onBack: notifier.canGoBack ? notifier.goBack : null,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StepTariff(
                      state: state,
                      notifier: notifier,
                    ),
                    _StepBudget(
                      state: state,
                      notifier: notifier,
                    ),
                    _StepComplete(
                      state: state,
                      notifier: notifier,
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
    await ref.read(onboardingProvider.notifier).completeOnboarding();

    if (!mounted) return;
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
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16.r,
                      color: AppColors.text2,
                    ),
                  ),
                )
              else
                SizedBox(width: 36.w),
              Text(
                '${state.currentStep + 1} of ${OnboardingPageState.totalSteps}',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
              ),
              SizedBox(width: 36.w),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: state.progressValue,
              backgroundColor: AppColors.surface3,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 3,
            ),
          ),
          SizedBox(height: 28.h),
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
      padding: EdgeInsets.symmetric(horizontal: 20.w),
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
          SizedBox(height: 16.h),
          Text('Select Tariff Type', style: AppTextStyles.titleLg),
          SizedBox(height: 8.h),
          Text(
            'Choose your TNB account category',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
          ),
          SizedBox(height: 24.h),
          ...TariffType.values.map((tariff) {
            final isSelected = state.selectedTariff == tariff;
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _TariffOption(
                tariff: tariff,
                isSelected: isSelected,
                onTap: () => notifier.selectTariff(tariff),
              ),
            );
          }),
          SizedBox(height: 28.h),
          GradientButton(
            label: 'Continue',
            isLoading: false,
            onTap: notifier.nextFromTariff,
          ),
          SizedBox(height: 24.h),
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
        padding: EdgeInsets.all(16.r),
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
                  SizedBox(height: 2.h),
                  Text(
                    tariff.subtitle,
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20.r,
              height: 20.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 13.r,
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
      padding: EdgeInsets.symmetric(horizontal: 20.w),
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
          SizedBox(height: 16.h),
          Text('Set Monthly Target', style: AppTextStyles.titleLg),
          SizedBox(height: 8.h),
          Text(
            "We'll alert you before you overspend",
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
          ),
          SizedBox(height: 24.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20.w, horizontal: 16.h),
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
                SizedBox(height: 4.h),
                Text(
                  'RM ${state.monthlyBudget.toStringAsFixed(0)}',
                  style: AppTextStyles.displayLg.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  state.estimatedKwh,
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
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
            padding: EdgeInsets.symmetric(horizontal: 4.w),
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
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text('💡', style: TextStyle(fontSize: 14.sp)),
                SizedBox(width: 8.w),
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
          SizedBox(height: 28.h),
          GradientButton(
            label: 'Continue',
            isLoading: false,
            onTap: notifier.nextFromBudget,
          ),
          SizedBox(height: 24.h),
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
      padding: EdgeInsets.symmetric(horizontal: 20.w),
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
          SizedBox(height: 16.h),
          Text("You're All Set!", style: AppTextStyles.titleLg),
          SizedBox(height: 8.h),
          Text(
            'Energy Tracker is ready to track your usage',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
          ),
          SizedBox(height: 24.h),
          _SummaryItem(
            icon: '✅',
            title: 'Tariff configured',
            subtitle: state.selectedTariff.label,
          ),
          SizedBox(height: 10.h),
          _SummaryItem(
            icon: '✅',
            title: 'Budget set',
            subtitle: 'RM ${state.monthlyBudget.toStringAsFixed(0)} / month',
          ),
          SizedBox(height: 10.h),
          const _SummaryItem(
            icon: '🔔',
            title: 'Alerts enabled',
            subtitle: '80% & 100% notifications',
          ),
          if (state.errorMessage != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
                      state.errorMessage!,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 28.h),
          GradientButton(
            label: 'Start Tracking ⚡',
            isLoading: state.isLoading,
            onTap: onStartTracking,
          ),
          SizedBox(height: 24.h),
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
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ),
          SizedBox(width: 12.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              Text(subtitle, style: AppTextStyles.bodySm),
            ],
          ),
        ],
      ),
    );
  }
}
