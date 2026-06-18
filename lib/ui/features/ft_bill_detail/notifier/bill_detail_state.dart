import 'package:energy_tracker/models/bill_record.dart';
import 'package:energy_tracker/models/reading_record.dart';

class BillDetailPageState {
  const BillDetailPageState({
    this.isLoading = true,
    this.isUpdatingPaid = false,
    this.isPaid = false,
    this.bill,
    this.readings = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final bool isUpdatingPaid;
  final bool isPaid;
  final BillRecord? bill;
  final List<ReadingRecord> readings;
  final String? errorMessage;

  BillDetailPageState copyWith({
    bool? isLoading,
    bool? isUpdatingPaid,
    bool? isPaid,
    BillRecord? bill,
    List<ReadingRecord>? readings,
    String? errorMessage,
  }) {
    return BillDetailPageState(
      isLoading: isLoading ?? this.isLoading,
      isUpdatingPaid: isUpdatingPaid ?? this.isUpdatingPaid,
      isPaid: isPaid ?? this.isPaid,
      bill: bill ?? this.bill,
      readings: readings ?? this.readings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
