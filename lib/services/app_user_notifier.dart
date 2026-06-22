import 'package:energy_tracker/models/user_profile.dart';
import 'package:flutter/foundation.dart';

enum OnboardingStatus { loading, complete, incomplete, error }

class AppUserNotifier extends ChangeNotifier {
  OnboardingStatus _status = OnboardingStatus.loading;
  UserProfile? _profile;

  OnboardingStatus get status => _status;
  UserProfile? get profile => _profile;

  bool get isLoading => _status == OnboardingStatus.loading;
  bool get isComplete => _status == OnboardingStatus.complete;
  bool get isIncomplete => _status == OnboardingStatus.incomplete;
  bool get isError => _status == OnboardingStatus.error;

  void setProfile(UserProfile profile) {
    _profile = profile;
    _status = profile.onboardingCompleted
        ? OnboardingStatus.complete
        : OnboardingStatus.incomplete;
    notifyListeners();
  }

  void setComplete() {
    _status = OnboardingStatus.complete;
    notifyListeners();
  }

  void setIncomplete() {
    _profile = null;
    _status = OnboardingStatus.incomplete;
    notifyListeners();
  }

  void setError() {
    _status = OnboardingStatus.error;
    notifyListeners();
  }

  void reset() {
    _profile = null;
    _status = OnboardingStatus.loading;
    notifyListeners();
  }
}
