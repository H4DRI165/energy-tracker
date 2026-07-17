import 'package:energy_tracker/services/notification/notification_prefs_state.dart';
import 'package:energy_tracker/services/notification/notifier/notification_prefs_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<NotificationPrefsNotifier, NotificationPrefsState>
notificationPrefsProvider =
    NotifierProvider.autoDispose<
      NotificationPrefsNotifier,
      NotificationPrefsState
    >(
      NotificationPrefsNotifier.new,
    );
