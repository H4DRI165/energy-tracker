import 'package:energy_tracker/services/auth/auth_service.dart';
import 'package:energy_tracker/services/notifier/app_user_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final userProfileProvider = ChangeNotifierProvider<AppUserNotifier>((ref) {
  return AuthService().userNotifier;
});

final isProfileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider).isLoading;
});
