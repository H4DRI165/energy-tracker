import 'package:energy_tracker/models/bill_record.dart';
import 'package:energy_tracker/models/reading_record.dart';

class BillDetailPageState {
  const BillDetailPageState({
    this.isLoading = true,
    this.bill,
    this.readings = const [],
    this.hasMoreReadings = false,
    this.billDeleted = false,
    this.errorMessage,
  });

  final bool isLoading;
  final BillRecord? bill;
  final List<ReadingRecord> readings;

  final bool hasMoreReadings;
  final bool billDeleted;
  final String? errorMessage;
  static const Object _unset = Object();

  BillDetailPageState copyWith({
    bool? isLoading,
    Object? bill = _unset,
    List<ReadingRecord>? readings,
    bool? hasMoreReadings,
    bool? billDeleted,
    Object? errorMessage = _unset,
  }) {
    return BillDetailPageState(
      isLoading: isLoading ?? this.isLoading,
      bill: identical(bill, _unset) ? this.bill : bill as BillRecord?,
      readings: readings ?? this.readings,
      hasMoreReadings: hasMoreReadings ?? this.hasMoreReadings,
      billDeleted: billDeleted ?? this.billDeleted,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
