import 'package:flutter/foundation.dart';

enum OnboardingStatus { loading, complete, incomplete, error }

class AppUserNotifier extends ChangeNotifier {
  OnboardingStatus _status = OnboardingStatus.loading;

  OnboardingStatus get status => _status;

  bool get isLoading => _status == OnboardingStatus.loading;
  bool get isComplete => _status == OnboardingStatus.complete;
  bool get isIncomplete => _status == OnboardingStatus.incomplete;
  bool get isError => _status == OnboardingStatus.error;

  void setComplete() {
    _status = OnboardingStatus.complete;
    notifyListeners();
  }

  void setIncomplete() {
    _status = OnboardingStatus.incomplete;
    notifyListeners();
  }

  void setError() {
    _status = OnboardingStatus.error;
    notifyListeners();
  }

  void reset() {
    _status = OnboardingStatus.loading;
    notifyListeners();
  }
}
