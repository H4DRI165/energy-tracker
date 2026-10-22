import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTheme {
  static ThemeData get current => _build(
    AppColors.isDark ? Brightness.dark : Brightness.light,
  );

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.accent,
        onPrimary: AppColors.onAccent,
        secondary: AppColors.accent2,
        onSecondary: AppColors.onAccent,
        tertiary: AppColors.accent3,
        onTertiary: AppColors.onAccent,
        error: AppColors.danger,
        onError: AppColors.onAccent,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        surfaceContainerHighest: AppColors.surface2,
        outline: AppColors.border,
        outlineVariant: AppColors.borderAccent,
      ),

      scaffoldBackgroundColor: AppColors.bg,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: brightness == Brightness.dark
              ? Brightness.dark
              : Brightness.light,
          statusBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarColor: AppColors.bg,
          systemNavigationBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
        titleTextStyle: AppTextStyles.titleMd,
        iconTheme: IconThemeData(color: AppColors.text, size: 22),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: BorderSide(
            color: AppColors.border,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyLg.copyWith(color: AppColors.text3),
        labelStyle: AppTextStyles.label,
        floatingLabelStyle: AppTextStyles.label.copyWith(
          color: AppColors.accent,
        ),
        prefixIconColor: AppColors.text3,
        suffixIconColor: AppColors.text3,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.accent),
          foregroundColor: WidgetStatePropertyAll(AppColors.onAccent),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: WidgetStatePropertyAll(AppColors.text),
          side: WidgetStatePropertyAll(
            BorderSide(color: AppColors.border),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            AppTextStyles.button.copyWith(color: AppColors.text),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(AppColors.accent),
          textStyle: WidgetStatePropertyAll(
            AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bg.withValues(alpha: 0.95),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.text3,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bg.withValues(alpha: 0.95),
        elevation: 0,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.accent, size: 24);
          }
          return IconThemeData(color: AppColors.text3, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.navLabel.copyWith(color: AppColors.accent);
          }
          return AppTextStyles.navLabel;
        }),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.onAccent;
          return AppColors.text3;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.text3.withValues(alpha: 0.22);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return AppColors.text3.withValues(alpha: 0.5);
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(AppColors.onAccent),
        side: BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.border;
        }),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.surface3,
        circularTrackColor: AppColors.surface3,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2,
        selectedColor: AppColors.accent.withValues(alpha: 0.15),
        labelStyle: AppTextStyles.tag,
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface2,
        contentTextStyle: AppTextStyles.bodyMd,
        actionTextColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: BorderSide(color: AppColors.border),
        ),
        titleTextStyle: AppTextStyles.titleMd,
        contentTextStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: AppColors.text,
        iconColor: AppColors.text2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),

      iconTheme: IconThemeData(color: AppColors.text2, size: 22),
      primaryIconTheme: IconThemeData(color: AppColors.accent, size: 22),

      textTheme:
          GoogleFonts.dmSansTextTheme(
            brightness == Brightness.dark
                ? ThemeData.dark().textTheme
                : ThemeData.light().textTheme,
          ).copyWith(
            displayLarge: AppTextStyles.displayXl,
            displayMedium: AppTextStyles.displayLg,
            displaySmall: AppTextStyles.displayMd,
            headlineLarge: AppTextStyles.titleLg,
            headlineMedium: AppTextStyles.titleMd,
            titleLarge: AppTextStyles.titleMd,
            titleMedium: AppTextStyles.bodyLg.copyWith(
              fontWeight: FontWeight.w600,
            ),
            titleSmall: AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: AppTextStyles.bodyLg,
            bodyMedium: AppTextStyles.bodyMd,
            bodySmall: AppTextStyles.bodySm,
            labelLarge: AppTextStyles.button,
            labelMedium: AppTextStyles.label,
            labelSmall: AppTextStyles.caption,
          ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
