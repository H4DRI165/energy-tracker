import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:energy_tracker/ui/features/ft_settings/pg_edit_profile/notifier/notifier.dart';
import 'package:energy_tracker/ui/features/ft_settings/pg_settings/notifier/settings_notifier.dart';
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
  bool _allowPop = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileProvider);
    final hasChanges = state.value?.hasChanges ?? false;
    final errorMessage = state.value?.errorMessage;

    return PopScope(
      canPop: _allowPop || !hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleSystemBack());
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  isSaving: state.value?.isSaving ?? false,
                  hasChanges: hasChanges,
                  onBack: _handleBack,
                  onSave: _handleSave,
                ),
                if (errorMessage != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppDimensions.screenPaddingH,
                      0,
                      AppDimensions.screenPaddingH,
                      12.h,
                    ),
                    child: _StatusBanner(
                      message: errorMessage,
                      isError: true,
                    ),
                  ),
                Expanded(
                  child: state.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                    error: (_, _) => ErrorView(
                      onRetry: () => ref.invalidate(editProfileProvider),
                      message: 'Failed to load profile',
                    ),
                    data: (state) => const _BodyContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBack() async {
    final state = ref.read(editProfileProvider).value;
    if (state?.isSaving ?? false) return;
    if (!(state?.hasChanges ?? false)) {
      context.pop();
      return;
    }
    if (await _confirmDiscard() && mounted) {
      context.pop();
    }
  }

  Future<void> _handleSystemBack() async {
    final state = ref.read(editProfileProvider).value;
    if (state?.isSaving ?? false) return;
    if (!(state?.hasChanges ?? false)) {
      context.pop();
      return;
    }
    if (await _confirmDiscard() && mounted) {
      context.pop();
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await ConfirmDialog.show(
      context,
      title: 'Discard changes?',
      message: 'Your profile changes have not been saved.',
      confirmLabel: 'Discard',
      confirmColor: AppColors.danger,
    );
    if (!discard || !mounted) return false;
    setState(() => _allowPop = true);
    return true;
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final hadChanges = ref.read(editProfileProvider).value?.hasChanges ?? false;
    final success = await ref.read(editProfileProvider.notifier).save();

    if (!success) return;
    if (!mounted) return;

    final message =
        ref.read(editProfileProvider).value?.successMessage ??
        'Profile updated successfully';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.accent,
              size: 18.r,
            ),
            SizedBox(width: 10.w),
            Text(message, style: AppTextStyles.bodyMd),
          ],
        ),
        backgroundColor: AppColors.surface2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
    );

    if (!hadChanges) return;

    final refresh = Future.wait([
      ref.read(dashboardProvider.notifier).refresh(),
      ref.read(settingsProvider.notifier).refresh(),
    ]);

    if (mounted) {
      setState(() => _allowPop = true);
      context.pop();
    }

    unawaited(
      refresh.then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {},
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isSaving,
    required this.hasChanges,
    required this.onBack,
    required this.onSave,
  });

  final bool isSaving;
  final bool hasChanges;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final canSave = hasChanges && !isSaving;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.screenPaddingH,
        12.h,
        AppDimensions.screenPaddingH,
        16.h,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isSaving ? null : onBack,
            tooltip: 'Back',
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16.r,
            ),
            style: IconButton.styleFrom(
              minimumSize: Size(44.r, 44.r),
              maximumSize: Size(44.r, 44.r),
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.surface2,
              foregroundColor: AppColors.text2,
              disabledForegroundColor: AppColors.text3,
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text('Edit Profile', style: AppTextStyles.titleMd),
          ),
          Semantics(
            button: true,
            enabled: canSave,
            label: isSaving ? 'Saving profile' : 'Save profile',
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: hasChanges ? AppColors.primaryGradient : null,
                  color: hasChanges ? null : AppColors.surface2,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: hasChanges
                      ? null
                      : Border.all(color: AppColors.border),
                  boxShadow: hasChanges ? AppColors.btnPrimaryShadow : null,
                ),
                child: InkWell(
                  onTap: canSave ? onSave : null,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Container(
                    constraints: BoxConstraints(minHeight: 44.r),
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    alignment: Alignment.center,
                    child: isSaving
                        ? SizedBox(
                            width: 16.r,
                            height: 16.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: hasChanges
                                  ? AppColors.onAccent
                                  : AppColors.text3,
                            ),
                          )
                        : Text(
                            'Save',
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: hasChanges
                                  ? AppColors.onAccent
                                  : AppColors.text3,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyContent extends ConsumerStatefulWidget {
  const _BodyContent();

  @override
  ConsumerState<_BodyContent> createState() => _BodyContentState();
}

class _BodyContentState extends ConsumerState<_BodyContent> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _tnbController;
  late final TextEditingController _emailController;
  bool _controllersPopulated = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _tnbController = TextEditingController();
    _emailController = TextEditingController();

    _fullNameController.addListener(_onFullNameChanged);
    _tnbController.addListener(_onTnbChanged);
  }

  void _onFullNameChanged() => ref
      .read(editProfileProvider.notifier)
      .setFullName(_fullNameController.text);

  void _onTnbChanged() => ref
      .read(editProfileProvider.notifier)
      .setTnbAccountNo(_tnbController.text);

  @override
  void dispose() {
    _fullNameController.dispose();
    _tnbController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileProvider).value;

    if (!_controllersPopulated && state != null) {
      _fullNameController.removeListener(_onFullNameChanged);
      _tnbController.removeListener(_onTnbChanged);
      _fullNameController.text = state.fullName;
      _tnbController.text = state.tnbAccountNo;
      _emailController.text = state.email;
      _fullNameController.addListener(_onFullNameChanged);
      _tnbController.addListener(_onTnbChanged);
      _controllersPopulated = true;
    }

    if (state == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingH,
        vertical: 8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AvatarSection(),
          SizedBox(height: 32.h),
          AppTextField(
            label: 'Full Name',
            controller: _fullNameController,
            hintText: 'Enter your full name',
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            prefixIcon: Icons.person_outline_rounded,
            errorText: state.fullNameError,
            enabled: !state.isSaving,
            maxLength: 60,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
          ),
          SizedBox(height: 16.h),
          AppTextField(
            label: 'Email Address',
            controller: _emailController,
            hintText: 'Email address',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            readOnly: true,
            enabled: !state.isSaving,
          ),
          SizedBox(height: 4.h),
          Text(
            'Email is managed by your sign-in and cannot be changed here.',
            style: AppTextStyles.caption,
          ),
          SizedBox(height: 16.h),
          AppTextField(
            label: 'TNB Account No. (optional)',
            controller: _tnbController,
            hintText: 'e.g. 123456789012',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.receipt_long_outlined,
            errorText: state.tnbAccountError,
            enabled: !state.isSaving,
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
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

class _AvatarSection extends ConsumerWidget {
  const _AvatarSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editProfileProvider).value;

    if (state == null) {
      return const SizedBox.shrink();
    }

    final hasAnyImage =
        state.localPhotoFile != null || state.displayPhotoUrl != null;

    return Column(
      children: [
        Semantics(
          button: true,
          enabled: !state.isSaving,
          label: hasAnyImage
              ? 'Change or remove profile photo'
              : 'Add profile photo',
          child: GestureDetector(
            onTap: state.isSaving
                ? null
                : () => _showAvatarOptions(
                    context,
                    ref,
                    hasImage: hasAnyImage,
                  ),
            child: Center(
              child: Stack(
                children: [
                  Container(
                    width: 88.r,
                    height: 88.r,
                    decoration: BoxDecoration(
                      gradient: hasAnyImage ? null : AppColors.primaryGradient,
                      color: hasAnyImage ? AppColors.surface2 : null,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.30),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(child: _AvatarImage(state: state)),
                  ),

                  if (state.isSaving && state.localPhotoFile != null)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 22.r,
                            height: 22.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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
                        border: Border.all(
                          color: AppColors.border,
                          width: 2,
                        ),
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
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          state.isSaving
              ? 'Saving changes…'
              : hasAnyImage
              ? 'Tap to change photo'
              : 'Tap to add a photo',
          style: AppTextStyles.caption.copyWith(color: AppColors.text3),
        ),
      ],
    );
  }
}

void _showAvatarOptions(
  BuildContext context,
  WidgetRef ref, {
  required bool hasImage,
}) {
  unawaited(
    showAppBottomSheet<void>(
      context: context,
      builder: (sheetContext) => AppBottomSheet(
        header: Text(
          'Profile photo',
          style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.photo_library_outlined,
                color: AppColors.accent,
              ),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(
                  ref.read(editProfileProvider.notifier).pickAvatar(),
                );
              },
            ),
            if (hasImage)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                ),
                title: Text(
                  'Remove photo',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ref.read(editProfileProvider.notifier).removePhoto();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.state});
  final EditProfilePageState state;

  @override
  Widget build(BuildContext context) {
    if (state.localPhotoFile != null) {
      return FutureBuilder<Uint8List>(
        future: state.localPhotoFile!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return state.displayPhotoUrl != null
                ? CachedNetworkImage(
                    imageUrl: state.displayPhotoUrl!,
                    fit: BoxFit.cover,
                    width: 88,
                    height: 88,
                    placeholder: (_, _) => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, _, _) => _InitialsFallback(state.initials),
                  )
                : _InitialsFallback(state.initials);
          }

          if (snapshot.connectionState != ConnectionState.done ||
              !snapshot.hasData) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            width: 88,
            height: 88,
          );
        },
      );
    }

    if (state.displayPhotoUrl != null) {
      return CachedNetworkImage(
        imageUrl: state.displayPhotoUrl!,
        fit: BoxFit.cover,
        width: 88,
        height: 88,
        placeholder: (_, _) => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, _, _) => _InitialsFallback(state.initials),
      );
    }

    return _InitialsFallback(state.initials);
  }
}

class _InitialsFallback extends StatelessWidget {
  const _InitialsFallback(this.initials);
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: AppTextStyles.titleLg.copyWith(
          color: AppColors.onAccent,
          fontSize: 28.sp,
        ),
      ),
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
