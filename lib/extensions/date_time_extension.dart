import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  String get shortDayLabel => DateFormat('MMM d').format(this);

  String get fullDateLabel => DateFormat('MMM d, yyyy').format(this);

  String get monthYearLabel => DateFormat('MMMM yyyy').format(this);

  String get shortMonthYearLabel => DateFormat('MMM yyyy').format(this);
}
