import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_bintang/main.dart';

final _equationFinder = find.byKey(const Key('equation'));
final _resultFinder = find.byKey(const Key('result'));

String _equationText(WidgetTester tester) {
  return (tester.widget<Text>(_equationFinder)).data!;
}

String _resultText(WidgetTester tester) {
  return (tester.widget<Text>(_resultFinder)).data!;
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
}

Future<void> _tapAll(WidgetTester tester, List<String> labels) async {
  for (final label in labels) {
    await _tap(tester, label);
  }
}

void main() {
  testWidgets('Initial state shows 0 for equation and result', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(_equationText(tester), '0');
    expect(_resultText(tester), '0');
  });

  testWidgets('Number buttons update equation', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tap(tester, '5');
    expect(_equationText(tester), '5');
  });

  testWidgets('Multi-digit input', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['1', '2', '3']);
    expect(_equationText(tester), '123');
  });

  testWidgets('AC button clears everything', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '+', '3', 'AC']);
    expect(_equationText(tester), '0');
    expect(_resultText(tester), '0');
  });

  testWidgets('Basic addition', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '+', '3', '=']);
    expect(_resultText(tester), '8');
  });

  testWidgets('Basic subtraction', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['9', '-', '4', '=']);
    expect(_resultText(tester), '5');
  });

  testWidgets('Basic multiplication', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['6', '×', '7', '=']);
    expect(_resultText(tester), '42');
  });

  testWidgets('Basic division', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['8', '÷', '2', '=']);
    expect(_resultText(tester), '4');
  });

  testWidgets('Division by zero shows error', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '÷', '0', '=']);
    expect(_resultText(tester), 'Tidak terdefinisi');
  });

  testWidgets('Backspace removes last character', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['1', '2', '⌫']);
    expect(_equationText(tester), '1');
  });

  testWidgets('Backspace on single digit resets to 0', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '⌫']);
    expect(_equationText(tester), '0');
  });

  testWidgets('Backspace after calculation resets all', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '+', '3', '=', '⌫']);
    expect(_equationText(tester), '0');
    expect(_resultText(tester), '0');
  });

  testWidgets('Consecutive operators replaced', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '+', '-']);
    expect(_equationText(tester), '5-');
  });

  testWidgets('New number after calculation resets equation', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '+', '3', '=', '9']);
    expect(_equationText(tester), '9');
  });

  testWidgets('Operator after calculation chains from result', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '+', '3', '=', '+']);
    expect(_equationText(tester), '8+');
  });

  testWidgets('Decimal point only once per number', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '.', '3', '.']);
    expect(_equationText(tester), '5.3');
  });

  testWidgets('Decimal allowed in second number', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '.', '3', '+', '1', '.', '2']);
    expect(_equationText(tester), '5.3+1.2');
  });

  testWidgets('00 button does not create leading zeros', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tap(tester, '00');
    expect(_equationText(tester), '0');
  });

  testWidgets('= ignored when equation ends with operator', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '+', '=']);
    expect(_equationText(tester), '5+');
  });

  testWidgets('Percent not replaced by next operator', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '0', '%', '×', '2']);
    expect(_equationText(tester), '50%×2');
  });

  testWidgets('Cannot add percent twice', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '%', '%']);
    expect(_equationText(tester), '5%');
  });

  testWidgets('Decimal result removes trailing zeros', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['1', '0', '÷', '4', '=']);
    expect(_resultText(tester), '2.5');
  });

  testWidgets('Chained calculation works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _tapAll(tester, ['5', '+', '3', '=', '+', '2', '=']);
    expect(_resultText(tester), '10');
  });
}
