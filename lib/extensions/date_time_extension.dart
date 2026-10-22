import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  String get shortDayLabel => DateFormat('MMM d').format(this);

  /// Date plus time when the reading has a time component. Backdated readings
  /// are stored at midnight, so they keep the shorter date-only label.
  String get shortDayTimeLabel {
    if (hour == 0 && minute == 0) return shortDayLabel;
    return DateFormat('MMM d, h:mm a').format(this);
  }

  String get fullDateLabel => DateFormat('MMM d, yyyy').format(this);

  String get monthYearLabel => DateFormat('MMMM yyyy').format(this);

  String get shortMonthYearLabel => DateFormat('MMM yyyy').format(this);
}
