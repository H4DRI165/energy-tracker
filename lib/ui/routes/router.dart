import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: GoRouterRefreshStream(AuthService().authStateChanges),
  redirect: (context, state) {
    final isLoggedIn = AuthService().currentUser != null;
    final isOnAuth = state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register ||
        state.matchedLocation == AppRoutes.landing ||
        state.matchedLocation == AppRoutes.splash;

    // If logged in and on auth screens → go to dashboard
    if (isLoggedIn && isOnAuth) return AppRoutes.dashboard;

    // If not logged in and trying to access dashboard → go to login
    if (!isLoggedIn && !isOnAuth) return AppRoutes.login;

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
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const RegisterPage(),
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
      path: AppRoutes.onboarding,
      name: 'onboarding',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: OnboardingPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      name: 'dashboard',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: DashboardPage(),
      ),
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
