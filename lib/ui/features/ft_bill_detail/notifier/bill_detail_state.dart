import 'package:energy_tracker/models/bill_record.dart';
import 'package:energy_tracker/models/reading_record.dart';

class BillDetailPageState {
  const BillDetailPageState({
    this.isLoading = true,
    this.isUpdatingPaid = false,
    this.isPaid = false,
    this.bill,
    this.readings = const [],
    this.billDeleted = false,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isUpdatingPaid;
  final bool isPaid;
  final BillRecord? bill;
  final List<ReadingRecord> readings;
  final bool billDeleted;
  final String? errorMessage;
  static const Object _unset = Object();

  BillDetailPageState copyWith({
    bool? isLoading,
    bool? isUpdatingPaid,
    bool? isPaid,
    Object? bill = _unset,
    List<ReadingRecord>? readings,
    bool? billDeleted,
    Object? errorMessage = _unset,
  }) {
    return BillDetailPageState(
      isLoading: isLoading ?? this.isLoading,
      isUpdatingPaid: isUpdatingPaid ?? this.isUpdatingPaid,
      isPaid: isPaid ?? this.isPaid,
      bill: identical(bill, _unset) ? this.bill : bill as BillRecord?,
      readings: readings ?? this.readings,
      billDeleted: billDeleted ?? this.billDeleted,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
