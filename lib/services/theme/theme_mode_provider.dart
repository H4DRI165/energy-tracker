import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final NotifierProvider<ThemeModeNotifier, bool> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, bool>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<bool> {
  static const String prefsKey = 'darkModeEnabled';

  /// Read once in main() before runApp so the first frame uses the saved mode.
  static bool? initialIsDark;

  @override
  bool build() {
    if (initialIsDark == null) unawaited(_load());
    return initialIsDark ?? false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(prefsKey) ?? false;
    initialIsDark = value;
    if (ref.mounted && value != state) state = value;
  }

  Future<void> setDark({required bool value}) async {
    if (value == state) return;
    state = value;
    initialIsDark = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, value);
  }

  Future<void> toggle() => setDark(value: !state);
}
