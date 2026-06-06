import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _authService = AuthService();

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: Listenable.merge([
    GoRouterRefreshStream(_authService.authStateChanges),
    _authService.userNotifier,
  ]),
  redirect: (context, state) {
    final isLoggedIn = _authService.currentUser != null;
    final onboardingCompleted = _authService.userNotifier.onboardingCompleted;

    final isPublicAuthRoute = state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register ||
        state.matchedLocation == AppRoutes.landing ||
        state.matchedLocation == AppRoutes.splash ||
        state.matchedLocation == AppRoutes.forgotPassword;

    // Still loading onboarding state from Firestore — stay put
    if (isLoggedIn && onboardingCompleted == null) return null;

    // Logged in, onboarding incomplete → go to onboarding
    if (isLoggedIn &&
        onboardingCompleted == false &&
        state.matchedLocation != AppRoutes.onboarding) {
      return AppRoutes.onboarding;
    }

    // Logged in, onboarding done → go to dashboard
    if (isLoggedIn &&
        onboardingCompleted == true &&
        (isPublicAuthRoute || state.matchedLocation == AppRoutes.onboarding)) {
      return AppRoutes.dashboard;
    }

    // Not logged in, trying to access protected route → go to login
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
      path: AppRoutes.onboarding,
      name: 'onboarding',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: OnboardingPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgot_password',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ForgotPasswordPage(),
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
