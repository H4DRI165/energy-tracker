import 'package:energy_tracker/ui/components/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

base class CrashlyticsProviderObserver extends ProviderObserver {
  const CrashlyticsProviderObserver();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (error is ProviderException) {
      return;
    }

    AppLogger.error(
      'Provider failed: '
      '${context.provider.name ?? context.provider.runtimeType}',
      error,
      stackTrace,
    );
  }
}
