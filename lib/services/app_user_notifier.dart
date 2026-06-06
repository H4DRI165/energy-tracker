import 'package:flutter/foundation.dart';

class AppUserNotifier extends ChangeNotifier {
  bool? _onboardingCompleted;

  bool? get onboardingCompleted => _onboardingCompleted;

  void setOnboardingCompleted(bool value) {
    _onboardingCompleted = value;
    notifyListeners();
  }

  void reset() {
    _onboardingCompleted = null;
    notifyListeners();
  }
}
