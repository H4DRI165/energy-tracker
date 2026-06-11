import 'package:energy_tracker/models/reading_record.dart';

class BillDetailPageState {
  const BillDetailPageState({
    this.isLoading = true,
    this.isUpdatingPaid = false,
    this.isPaid = false,
    this.readings = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final bool isUpdatingPaid;
  final bool isPaid;
  final List<ReadingRecord> readings;
  final String? errorMessage;

  BillDetailPageState copyWith({
    bool? isLoading,
    bool? isUpdatingPaid,
    bool? isPaid,
    List<ReadingRecord>? readings,
    String? errorMessage,
  }) {
    return BillDetailPageState(
      isLoading: isLoading ?? this.isLoading,
      isUpdatingPaid: isUpdatingPaid ?? this.isUpdatingPaid,
      isPaid: isPaid ?? this.isPaid,
      readings: readings ?? this.readings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
