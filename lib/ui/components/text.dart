import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AppFormFieldBorder {
  underlined,
  outlined,
  outlinedWithAlwaysFloatingLabel,
  roundedOutlined,
}

class AppTextFloatingLabelField extends StatelessWidget {
  // ------------------------------- CONSTRUCTORS ------------------------------
  const AppTextFloatingLabelField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.labelTextColor,
    this.labelTextFontSize,
    this.hintText,
    this.hintTextColor,
    this.hintTextFontStyle,
    this.floatingLabelTextFontSize,
    this.border,
    this.borderColor,
    this.focusedBorderColor,
    this.prefix,
    this.prefixIcon,
    this.suffix,
    this.suffixIcon,
    this.errorText,
    this.errorTextColor,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.textColor,
    this.textSize,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled = true,
    this.clearable = false,
    this.readonly = false,
    this.padding,
  });

  // ---------------------------------- FIELDS ---------------------------------
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final Color? labelTextColor;
  final double? labelTextFontSize;
  final String? hintText;
  final Color? hintTextColor;
  final FontStyle? hintTextFontStyle;
  final double? floatingLabelTextFontSize;
  final AppFormFieldBorder? border;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffix;
  final Widget? suffixIcon;
  final String? errorText;
  final Color? errorTextColor;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final Color? textColor;
  final double? textSize;
  final TextAlign textAlign;
  final int? maxLines;
  final int? maxLength;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool clearable;
  final bool readonly;
  final EdgeInsets? padding;

  // --------------------------------- METHODS ---------------------------------
  @override
  Widget build(BuildContext context) {
    InputBorder createBorder(Color borderColor, {required bool isFocused}) {
      switch (border) {
        case AppFormFieldBorder.underlined:
          return UnderlineInputBorder(
            borderSide: BorderSide(
              color: borderColor,
              width: isFocused ? 1.0 : 0.5,
            ),
          );
        case AppFormFieldBorder.outlined:
        case AppFormFieldBorder.outlinedWithAlwaysFloatingLabel:
          return OutlineInputBorder(
            borderSide: BorderSide(
              color: borderColor,
              width: isFocused ? 1.0 : 0.5,
            ),
          );
        case AppFormFieldBorder.roundedOutlined:
          return OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: borderColor,
              width: isFocused ? 1.0 : 0.5,
            ),
          );
        case null:
          return OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: borderColor,
              width: isFocused ? 1.0 : 0.5,
            ),
          );
      }
    }

    final hasError = errorText?.isNotEmpty ?? false;
    var suffixIcon = this.suffixIcon;

    if (controller != null) {
      final controllerText = controller!.text;
      if (enabled && !readonly && clearable && controllerText.isNotEmpty) {
        suffixIcon = IconButton(
          icon: const Icon(Icons.cancel),
          color: enabled && hasError ? errorTextColor : borderColor,
          onPressed: () {
            controller!.clear();
            onChanged?.call('');
          },
        );
      }
    }

    return MouseRegion(
      cursor: !enabled ? SystemMouseCursors.forbidden : MouseCursor.defer,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  floatingLabelBehavior: border ==
                          AppFormFieldBorder.outlinedWithAlwaysFloatingLabel
                      ? FloatingLabelBehavior.always
                      : null,
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontStyle: hintTextFontStyle,
                    color: enabled && hasError ? errorTextColor : hintTextColor,
                  ),
                  labelText: labelText,
                  labelStyle: TextStyle(
                    color:
                        enabled && hasError ? errorTextColor : labelTextColor,
                    fontSize: labelTextFontSize,
                  ),
                  floatingLabelStyle: TextStyle(
                    color:
                        enabled && hasError ? errorTextColor : labelTextColor,
                    fontSize: floatingLabelTextFontSize,
                  ),
                  border: createBorder(
                    borderColor ?? Colors.grey,
                    isFocused: false,
                  ),
                  enabledBorder: createBorder(
                    borderColor ?? Colors.grey,
                    isFocused: false,
                  ),
                  focusedBorder: createBorder(
                    focusedBorderColor ?? Colors.blue,
                    isFocused: true,
                  ),
                  errorBorder: createBorder(
                    errorTextColor ?? Colors.red,
                    isFocused: false,
                  ),
                  focusedErrorBorder: createBorder(
                    errorTextColor ?? Colors.red,
                    isFocused: true,
                  ),
                  errorText: enabled ? errorText : null,
                  errorStyle: TextStyle(color: errorTextColor ?? Colors.red),
                  prefixIcon: prefixIcon,
                  suffixIcon: suffixIcon,
                  prefix: prefix,
                  suffix: suffix,
                ),
                keyboardType: keyboardType,
                textCapitalization: textCapitalization,
                textInputAction: textInputAction,
                style: TextStyle(
                  color: textColor,
                  fontSize: textSize,
                ),
                textAlign: textAlign,
                maxLines: maxLines,
                maxLength: readonly ? null : maxLength,
                obscureText: obscureText,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                inputFormatters: inputFormatters,
                enabled: enabled,
                readOnly: readonly,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.errorText,
    this.readOnly = false,
    this.trailingWidget,
    this.maxLength,
    this.inputFormatters,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? errorText;
  final bool readOnly;
  final Widget? trailingWidget;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(
            color: readOnly
                ? AppColors.surface3.withValues(alpha: 0.5)
                : AppColors.surface2,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: errorText != null ? AppColors.danger : AppColors.border,
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 14.w),
              Icon(
                prefixIcon,
                size: 18.r,
                color: readOnly ? AppColors.text3 : AppColors.text2,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                  readOnly: readOnly,
                  maxLength: maxLength,
                  inputFormatters: inputFormatters,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: readOnly ? AppColors.text3 : AppColors.text,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: AppTextStyles.bodyLg.copyWith(
                      color: AppColors.text3,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                    counterText: '',
                  ),
                ),
              ),
              if (trailingWidget != null) ...[
                trailingWidget!,
                SizedBox(width: 10.w),
              ],
            ],
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 12.r,
                color: AppColors.danger,
              ),
              SizedBox(width: 4.w),
              Text(
                errorText!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
