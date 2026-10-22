import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/firebase_options.dart';
import 'package:energy_tracker/services/auth/providers/current_uid_provider.dart';
import 'package:energy_tracker/services/notification/service/provider/notification_service_provider.dart';
import 'package:energy_tracker/services/observers/crashlytics_provider_observer.dart';
import 'package:energy_tracker/services/tariff/tariff_repository.dart';
import 'package:energy_tracker/services/theme/theme_mode_provider.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:energy_tracker/ui/features/ft_devices/pg_devices/notifier/devices_notifier.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_notifier.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final prefs = await SharedPreferences.getInstance();
  ThemeModeNotifier.initialIsDark =
      prefs.getBool(ThemeModeNotifier.prefsKey) ?? false;

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
  );

  FlutterError.onError = (details) {
    unawaited(FirebaseCrashlytics.instance.recordFlutterFatalError(details));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
    );
    return true;
  };

  // exclude crashes from local dev
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  // Start immediately with the bundled schedule. The published schedule is
  // fetched in the background so a slow/offline network never delays launch.
  final tariffRepository = TariffRepository();
  TariffRates.configure(await tariffRepository.loadBundled());

  final container = ProviderContainer(
    observers: const [CrashlyticsProviderObserver()],
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MainApp(),
    ),
  );

  unawaited(_refreshRemoteTariff(container, tariffRepository));
}

Future<void> _refreshRemoteTariff(
  ProviderContainer container,
  TariffRepository repository,
) async {
  try {
    final remote = await repository.fetchRemote();
    if (remote == null) return;

    TariffRates.configure(remote);
    container
      ..invalidate(usageProvider)
      ..invalidate(dashboardProvider)
      ..invalidate(devicesProvider);
  } on Object catch (error) {
    if (kDebugMode) {
      developer.log(
        'Remote tariff unavailable; using bundled schedule.',
        name: 'TariffRepository',
        error: error.runtimeType,
      );
    }
  }
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();
  late final AnimationController _themeTransition;

  ui.Image? _snapshot;
  bool _displayedDark = false;
  bool? _systemBarsDark;
  bool _toDark = false;

  bool get _isTransitioning => _snapshot != null;

  @override
  void initState() {
    super.initState();
    _displayedDark = ref.read(themeModeProvider);
    _themeTransition =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) _clearSnapshot();
        });
  }

  void _clearSnapshot() {
    final old = _snapshot;
    if (old == null) return;
    if (mounted) setState(() => _snapshot = null);
    // Dispose after the frame that stops using it.
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() {
    _themeTransition.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  void _applySystemBars(bool isDark) {
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: palette.bg,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  void _startThemeTransition({required bool toDark}) {
    if (_isTransitioning) {
      _themeTransition.stop();
      _clearSnapshot();
    }

    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      setState(() => _displayedDark = toDark);
      _rebuildEverything();
      return;
    }

    final pixelRatio = math
        .min(
          View.of(context).devicePixelRatio,
          2,
        )
        .toDouble();
    final image = boundary.toImageSync(pixelRatio: pixelRatio);

    _themeTransition.value = 0;
    setState(() {
      _snapshot = image;
      _displayedDark = toDark;
      _toDark = toDark;
    });

    // Rebuild every element (fixes stale const widgets), THEN start the sweep,
    // so the heavy rebuild doesn't eat the first frames of the animation.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _snapshot != image) return;
      _rebuildEverything();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _snapshot != image) return;
      unawaited(_themeTransition.forward(from: 0));
    });
  }

  void _rebuildEverything() {
    (context as Element).visitChildren(_rebuildAll);
  }

  void _rebuildAll(Element element) {
    element
      ..markNeedsBuild()
      ..visitChildren(_rebuildAll);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    AppColors.setDark(value: _displayedDark);
    if (_systemBarsDark != _displayedDark) {
      _systemBarsDark = _displayedDark;
      _applySystemBars(_displayedDark);
    }

    ref
      ..listen<bool>(themeModeProvider, (previous, next) {
        if (previous == null || previous == next) return;
        if (next == _displayedDark) return;
        _startThemeTransition(toDark: next);
      })
      ..listen<AsyncValue<String?>>(currentUidProvider, (previous, next) {
        final previousUid = previous?.value;
        final nextUid = next.value;

        if (previousUid != null && previousUid != nextUid) {
          unawaited(
            ref.read(notificationServiceProvider).detachToken(previousUid),
          );
        }
        if (nextUid != null) {
          unawaited(ref.read(notificationServiceProvider).init());
        }
      });

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      fontSizeResolver: (fontSize, instance) {
        final scale = instance.scaleWidth.clamp(1.0, 1.50);
        return fontSize * scale;
      },
      builder: (context, child) => Stack(
        alignment: Alignment.topLeft,
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: MaterialApp.router(
              key: ValueKey(_displayedDark),
              title: 'Energy Tracker',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.current,
              darkTheme: AppTheme.current,
              themeMode: _displayedDark ? ThemeMode.dark : ThemeMode.light,
              routerConfig: appRouter,
            ),
          ),
          if (_snapshot case final image?)
            Positioned.fill(
              child: AbsorbPointer(
                child: _SweepOverlay(
                  animation: _themeTransition,
                  image: image,
                  toDark: _toDark,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SweepOverlay extends StatelessWidget {
  const _SweepOverlay({
    required this.animation,
    required this.image,
    required this.toDark,
  });

  final Animation<double> animation;
  final ui.Image image;
  final bool toDark;

  static const _sunColor = Color(0xFFFFC46B);
  static const _moonColor = Color(0xFFDDE6FF);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final feather = w * 0.3;
          final orbSize = 72.r;

          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final t = Curves.easeInOutCubic.transform(animation.value);
              final ltr = toDark;

              // Edge position in sweep space
              final edge = -feather + (w + feather) * t;
              final a = (edge / w).clamp(0.0, 1.0);
              final b = ((edge + feather) / w).clamp(0.0, 1.0);

              final p = toDark ? t : 1 - t;
              final sunOpacity = (1 - p * 1.6).clamp(0.0, 1.0);
              final moonOpacity = ((p - 0.3) / 0.7).clamp(0.0, 1.0);
              final glow = Color.lerp(_sunColor, _moonColor, p)!;

              final presence = math.sin(math.pi * t);

              // Screen-space positions: mirror when sweeping right to left.
              final bandLeft = ltr ? edge : w - edge - feather;
              final orbCenterX = bandLeft + feather / 2;
              final orbY = h * 0.28 - presence * h * 0.08;

              return Stack(
                alignment: Alignment.topLeft,
                fit: StackFit.expand,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => LinearGradient(
                      // Mirror the gradient direction and stops for R→L.
                      begin: ltr ? Alignment.centerLeft : Alignment.centerRight,
                      end: ltr ? Alignment.centerRight : Alignment.centerLeft,
                      colors: const [Color(0x00000000), Color(0xFF000000)],
                      stops: [a, b],
                    ).createShader(rect),
                    child: RawImage(image: image, fit: BoxFit.fill),
                  ),
                  Positioned(
                    left: bandLeft,
                    width: feather,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            glow.withValues(alpha: 0),
                            glow.withValues(alpha: 0.28 * presence),
                            glow.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: orbCenterX - orbSize / 2,
                    top: orbY - orbSize / 2,
                    width: orbSize,
                    height: orbSize,
                    child: Opacity(
                      opacity: (presence * 3).clamp(0.0, 1.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  glow.withValues(alpha: 0.45),
                                  glow.withValues(alpha: 0),
                                ],
                              ),
                            ),
                            child: SizedBox.square(dimension: orbSize * 1.8),
                          ),
                          Opacity(
                            opacity: sunOpacity,
                            child: Transform.rotate(
                              angle: p * math.pi,
                              child: Transform.scale(
                                scale: 1 - p * 0.4,
                                child: Icon(
                                  Icons.wb_sunny_rounded,
                                  size: orbSize,
                                  color: _sunColor,
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: moonOpacity,
                            child: Transform.rotate(
                              angle: -(1 - p) * math.pi / 2,
                              child: Transform.scale(
                                scale: 0.6 + p * 0.4,
                                child: Icon(
                                  Icons.nightlight_round,
                                  size: orbSize * 0.8,
                                  color: _moonColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
