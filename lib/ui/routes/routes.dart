export 'router.dart';

abstract class AppRoutes {
  // auth
  static const String splash = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String forgotPassword = '/forgot_password';
  static const String register = '/register';

  // features
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String tariffCalculator = '/tariff-calculator';
  static const String editProfile = '/edit-profile';
  static const String usage = '/usage';
  static const String addReading = '/add_reading';

  // WIP
  static const String tariffSettings = '/tariff-settings';
  static const String budgetSettings = '/budget-settings';
  static const String devices = '/devices';
  static const String scanBill = '/scan_bill';

  // error
  static const String error = '/error';
}
