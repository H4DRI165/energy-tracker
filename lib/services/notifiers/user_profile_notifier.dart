import 'package:energy_tracker/constants/tariff_types.dart';
import 'package:energy_tracker/services/app_user_notifier.dart';
import 'package:energy_tracker/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final userProfileProvider = ChangeNotifierProvider<AppUserNotifier>((ref) {
  return AuthService().userNotifier;
});

final tariffTypeProvider = Provider<TariffType>((ref) {
  final user = ref.watch(userProfileProvider);
  return user.profile?.tariffType ?? TariffType.domestic;
});
