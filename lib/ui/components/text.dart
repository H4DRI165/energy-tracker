import 'package:flutter/material.dart';

enum AppFormFieldBorder {
  underlined,
  outlined,
  outlinedWithAlwaysFloatingLabel,
  roundedOutlined,
}

class AppTextField extends StatelessWidget {
  // ------------------------------- CONSTRUCTORS ------------------------------
  const AppTextField({
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
  final bool enabled;
  final bool clearable;
  final bool readonly;
  final EdgeInsets? padding;

  // --------------------------------- METHODS ---------------------------------
  @override
  Widget build(BuildContext context) {
    InputBorder createBorder(Color borderColor, bool isFocused) {
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
        default:
          return const UnderlineInputBorder();
      }
    }

    final hasError = errorText?.isNotEmpty ?? false;
    var suffixIcon = this.suffixIcon;

    if (controller != null) {
      final controllerText = controller!.text;
      if (enabled && clearable && controllerText.isNotEmpty) {
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
                  border: createBorder(borderColor ?? Colors.grey, false),
                  enabledBorder:
                      createBorder(borderColor ?? Colors.grey, false),
                  focusedBorder:
                      createBorder(focusedBorderColor ?? Colors.blue, true),
                  errorBorder:
                      createBorder(errorTextColor ?? Colors.red, false),
                  focusedErrorBorder: createBorder(
                    errorTextColor ?? Colors.red,
                    true,
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
