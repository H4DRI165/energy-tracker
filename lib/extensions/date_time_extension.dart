import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  /// e.g. "Jun 17"
  String get shortDayLabel => DateFormat('MMM d').format(this);

  /// e.g. "Jun 17, 2026"
  String get fullDateLabel => DateFormat('MMM d, yyyy').format(this);

  /// e.g. "June 2026"
  String get monthYearLabel => DateFormat('MMMM yyyy').format(this);

  /// e.g. "Jun 2026"
  String get shortMonthYearLabel => DateFormat('MMM yyyy').format(this);
}
