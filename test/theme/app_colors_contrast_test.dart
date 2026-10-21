import 'dart:math';

import 'package:energy_tracker/services/theme/theme_mode_provider.dart';
import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _contrast(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

double _luminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('palette contrast', () {
    for (final palette in [AppPalette.light, AppPalette.dark]) {
      final name = palette.isDark ? 'dark' : 'light';

      test('$name text and semantic colors meet WCAG AA on background', () {
        final pairs = <String, Color>{
          'text': palette.text,
          'text2': palette.text2,
          'text3': palette.text3,
          'accent': palette.accent,
          'accent2': palette.accent2,
          'accent3': palette.accent3,
          'warn': palette.warn,
          'danger': palette.danger,
        };

        for (final entry in pairs.entries) {
          for (final background in [
            palette.bg,
            palette.surface,
            palette.surface2,
            palette.surface3,
          ]) {
            expect(
              _contrast(entry.value, background),
              greaterThanOrEqualTo(4.5),
              reason: '${entry.key} on $name background',
            );
          }
        }
      });

      test('$name accent text is readable on accent fills', () {
        for (final color in [
          palette.accent,
          palette.accent2,
          palette.accent3,
          palette.warn,
          palette.danger,
        ]) {
          expect(
            _contrast(palette.onAccent, color),
            greaterThanOrEqualTo(4.5),
          );
        }
      });
    }
  });

  group('theme mode', () {
    test('defaults to light and persists the selected mode', () async {
      SharedPreferences.setMockInitialValues({});
      ThemeModeNotifier.initialIsDark = null;
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), isFalse);

      await container.read(themeModeProvider.notifier).setDark(value: true);
      expect(container.read(themeModeProvider), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(ThemeModeNotifier.prefsKey), isTrue);
    });
  });
}
