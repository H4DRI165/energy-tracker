import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets('theme fonts load from bundled assets without internet', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppColors.setDark(value: false);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          theme: AppTheme.current,
          home: const Scaffold(body: Text('Offline font check')),
        ),
      ),
    );

    await GoogleFonts.pendingFonts();
  });
}
