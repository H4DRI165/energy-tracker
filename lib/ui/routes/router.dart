import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/services/app_user_notifier.dart';
import 'package:energy_tracker/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _authService = AuthService();
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  refreshListenable: Listenable.merge([
    GoRouterRefreshStream(_authService.authStateChanges),
    _authService.userNotifier,
  ]),
  redirect: (context, state) {
    final isLoggedIn = _authService.currentUser != null;
    final onboardingStatus = _authService.userNotifier.status;

    final isPublicAuthRoute =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register ||
        state.matchedLocation == AppRoutes.landing ||
        state.matchedLocation == AppRoutes.splash ||
        state.matchedLocation == AppRoutes.forgotPassword;

    // Still loading — stay put
    if (isLoggedIn && onboardingStatus == OnboardingStatus.loading) return null;

    // Firestore error — don't redirect to onboarding, go to a safe screen
    // and let the user retry rather than overwriting their data
    if (isLoggedIn && onboardingStatus == OnboardingStatus.error) {
      return state.matchedLocation == AppRoutes.error ? null : AppRoutes.error;
    }

    // Onboarding incomplete → go to onboarding
    if (isLoggedIn &&
        onboardingStatus == OnboardingStatus.incomplete &&
        state.matchedLocation != AppRoutes.onboarding) {
      return AppRoutes.onboarding;
    }

    // Onboarding complete → go to dashboard
    if (isLoggedIn &&
        onboardingStatus == OnboardingStatus.complete &&
        (isPublicAuthRoute || state.matchedLocation == AppRoutes.onboarding)) {
      return AppRoutes.dashboard;
    }

    // Not logged in, protected route → login
    if (!isLoggedIn && !isPublicAuthRoute) return AppRoutes.login;

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SplashPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.landing,
      name: 'landing',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LandingPage(),
      ),
    ),

    // ----------------------------AUTH ROUTES----------------------------------
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: RegisterPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgot_password',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ForgotPasswordPage(),
      ),
    ),

    // ----------------------------FEATURES ROUTES (non-tab)--------------------
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: OnboardingPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.tariffCalculator,
      name: 'tariff_calculator',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const TariffCalculatorPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      name: 'edit_profile',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: EditProfilePage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.addReading,
      builder: (context, state) {
        final extra = state.extra;
        return AddReadingPage(
          reading: extra is ReadingRecord ? extra : null,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.billDetail,
      builder: (context, state) {
        final extra = state.extra;

        if (extra is! BillRecord) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Invalid navigation. Please select a bill from the usage page.',
              ),
            ),
          );
        }
        return BillDetailPage(bill: extra);
      },
    ),
    GoRoute(
      path: AppRoutes.addAppliance,
      builder: (context, state) => const AddAppliancePage(),
    ),
    GoRoute(
      path: AppRoutes.editAppliance,
      builder: (context, state) {
        final extra = state.extra;

        if (extra is! Appliance) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Invalid navigation. Please select a device from devices page.',
              ),
            ),
          );
        }
        return AddAppliancePage(appliance: extra);
      },
    ),

    // -------------------------------WIP ROUTES--------------------------------
    GoRoute(
      path: AppRoutes.scanBill,
      name: 'scan_bill',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ComingSoonPage(
          title: 'Scan TNB Bill',
          subtitle:
              'Point your camera at your bill and '
              'let AI extract the data automatically.',
          icon: Icons.document_scanner_rounded,
        ),
      ),
    ),

    // --------------------------------ERROR ROUTES-----------------------------
    GoRoute(
      path: AppRoutes.error,
      name: 'error',
      pageBuilder: (context, state) => NoTransitionPage(
        child: Scaffold(
          backgroundColor: AppColors.bgDeep,
          body: ErrorView(
            onRetry: () async {
              // Re-trigger the auth listener by resetting notifier
              _authService.userNotifier.reset();
              await _authService.retryLoadUser();
            },
          ),
        ),
      ),
    ),

    // --------------------------------TAB SHELL (bottom nav)-------------------
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: AppBottomNav(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DashboardPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.usage,
              name: 'usage',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: UsagePage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.devices,
              name: 'devices',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DevicesPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsPage()),
            ),
          ],
        ),
      ],
    ),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
