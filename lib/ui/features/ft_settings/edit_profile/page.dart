import 'dart:async';
import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/errors.dart';
import 'package:energy_tracker/ui/components/text.dart';
import 'package:energy_tracker/ui/features/ft_settings/edit_profile/notifier/notifier.dart';
import 'package:energy_tracker/ui/features/ft_settings/settings/notifier/settings_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _tnbController;
  bool _controllersPopulated = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _tnbController = TextEditingController();

    _fullNameController.addListener(
      () => ref.read(editProfileProvider.notifier).setFullName(
            _fullNameController.text,
          ),
    );
    _tnbController.addListener(
      () => ref
          .read(editProfileProvider.notifier)
          .setTnbAccountNo(_tnbController.text),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _tnbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileProvider);
    ref.listen(editProfileProvider, (previous, next) {
      if (!_controllersPopulated) {
        next.whenData((s) {
          if (!_controllersPopulated) {
            _fullNameController.text = s.fullName;
            _tnbController.text = s.tnbAccountNo;
            _controllersPopulated = true;
          }
        });
      }
    });

    final hasChanges = state.value?.hasChanges ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              isSaving: state.value?.isSaving ?? false,
              hasChanges: hasChanges,
              onSave: _handleSave,
            ),
            Expanded(
              child: state.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (_, __) => ErrorView(
                  onRetry: () => ref.invalidate(editProfileProvider),
                  message: 'Failed to load profile',
                ),
                data: (state) => _BodyContent(
                  state: state,
                  fullNameController: _fullNameController,
                  tnbController: _tnbController,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final success = await ref.read(editProfileProvider.notifier).save();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.accent,
                size: 18,
              ),
              SizedBox(width: 10.w),
              Text('Profile updated successfully', style: AppTextStyles.bodyMd),
            ],
          ),
          backgroundColor: AppColors.surface2,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
      );

      if (context.mounted) {
        ref.invalidate(settingsProvider);
        context.pop();
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isSaving,
    required this.hasChanges,
    required this.onSave,
  });

  final bool isSaving;
  final bool hasChanges;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.screenPaddingH,
        12.h,
        AppDimensions.screenPaddingH,
        16.h,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.r,
                color: AppColors.text2,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text('Edit Profile', style: AppTextStyles.titleMd),
          ),
          GestureDetector(
            onTap: (isSaving || !hasChanges) ? null : onSave,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 8.h,
              ),
              decoration: BoxDecoration(
                gradient: hasChanges ? AppColors.primaryGradient : null,
                color: hasChanges ? null : AppColors.surface2,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: hasChanges ? null : Border.all(color: AppColors.border),
                boxShadow: hasChanges ? AppColors.btnPrimaryShadow : null,
              ),
              child: isSaving
                  ? SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: hasChanges ? Colors.black : AppColors.text3,
                      ),
                    )
                  : Text(
                      'Save',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: hasChanges ? Colors.black : AppColors.text3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyContent extends StatelessWidget {
  const _BodyContent({
    required this.state,
    required this.fullNameController,
    required this.tnbController,
  });

  final EditProfilePageState state;
  final TextEditingController fullNameController;
  final TextEditingController tnbController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingH,
        vertical: 8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarSection(initials: state.initials),
          SizedBox(height: 32.h),
          AppTextField(
            label: 'Full Name',
            controller: fullNameController,
            hintText: 'Enter your full name',
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            prefixIcon: Icons.person_outline_rounded,
            errorText: state.fullNameError,
            maxLength: 60,
            inputFormatters: [
              LengthLimitingTextInputFormatter(60),
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s'\-\.]")),
            ],
          ),
          SizedBox(height: 16.h),
          AppTextField(
            label: 'Email Address',
            controller: TextEditingController(text: state.email),
            hintText: 'Email address',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            readOnly: true,
            trailingWidget: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 4.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'Cannot edit',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.text3,
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Email address cannot be changed here. Contact support if needed.',
            style: AppTextStyles.caption,
          ),
          SizedBox(height: 16.h),
          AppTextField(
            label: 'TNB Account No.',
            controller: tnbController,
            hintText: 'e.g. 1234567890',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.receipt_long_outlined,
            errorText: state.tnbAccountError,
            maxLength: 12,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Found on your TNB electricity bill.',
            style: AppTextStyles.caption,
          ),
          SizedBox(height: 28.h),
          if (state.errorMessage != null) ...[
            _StatusBanner(
              message: state.errorMessage!,
              isError: true,
            ),
            SizedBox(height: 16.h),
          ],
          _AccountInfoCard(state: state),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 88.r,
            height: 88.r,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.titleLg.copyWith(
                  color: Colors.black,
                  fontSize: 28.sp,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28.r,
              height: 28.r,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 14.r,
                color: AppColors.text2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.state});
  final EditProfilePageState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16.r,
                color: AppColors.accent,
              ),
              SizedBox(width: 8.w),
              Text(
                'Account Information',
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _InfoRow(
            label: 'Display Name',
            value: state.fullName.isNotEmpty ? state.fullName : '—',
          ),
          SizedBox(height: 8.h),
          _InfoRow(
            label: 'Email',
            value: state.email.isNotEmpty ? state.email : '—',
          ),
          SizedBox(height: 8.h),
          _InfoRow(
            label: 'TNB Account',
            value: state.tnbAccountNo.isNotEmpty ? state.tnbAccountNo : '—',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100.w,
          child: Text(label, style: AppTextStyles.bodySm),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.isError,
  });
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.accent;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 16.r,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
