import 'package:energy_tracker/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUidProvider = StreamProvider<String?>((ref) {
  return AuthService().uidChanges;
});
