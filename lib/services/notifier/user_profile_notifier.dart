import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/services/auth/auth_service.dart';
import 'package:energy_tracker/services/notifier/app_user_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final userProfileProvider = ChangeNotifierProvider<AppUserNotifier>((ref) {
  return AuthService().userNotifier;
});

final tariffTypeProvider = Provider<TariffType>((ref) {
  final user = ref.watch(userProfileProvider);
  return user.profile?.tariffType ?? TariffType.domestic;
});

final isProfileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider).isLoading;
});
