import 'package:energy_tracker/ui/components/display/animated_number.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the initial value and eases to the next one', (
    tester,
  ) async {
    Widget build(double value) {
      return MaterialApp(
        home: Scaffold(
          body: AnimatedNumberText(
            value: value,
            formatter: (value) => value.toStringAsFixed(2),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(10));
    expect(find.text('10.00'), findsOneWidget);

    await tester.pumpWidget(build(20));
    await tester.pumpAndSettle();

    expect(find.text('20.00'), findsOneWidget);
  });
}
