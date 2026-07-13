import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_bintang/main.dart';

void main() {
  testWidgets('Calculator displays initial state correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('Number buttons update equation', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('AC button clears everything', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('AC'));
    await tester.pump();
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('Basic addition works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('+'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('Basic subtraction works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('9'));
    await tester.pump();
    await tester.tap(find.text('-'));
    await tester.pump();
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('Basic multiplication works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('6'));
    await tester.pump();
    await tester.tap(find.text('×'));
    await tester.pump();
    await tester.tap(find.text('7'));
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('Basic division works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('8'));
    await tester.pump();
    await tester.tap(find.text('÷'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('Division by zero shows error', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('÷'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();
    expect(find.text('Tidak terdefinisi'), findsOneWidget);
  });

  testWidgets('Backspace removes last character', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('⌫'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Backspace on single digit resets to 0', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('⌫'));
    await tester.pump();
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('Backspace after calculation resets', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('+'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();
    await tester.tap(find.text('⌫'));
    await tester.pump();
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('Cannot enter double operators', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('+'));
    await tester.pump();
    await tester.tap(find.text('-'));
    await tester.pump();
    expect(find.text('5-'), findsOneWidget);
  });

  testWidgets('New number input after calculation resets equation', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('+'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();
    await tester.tap(find.text('9'));
    await tester.pump();
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('Operator after calculation chains from result', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('+'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();
    await tester.tap(find.text('+'));
    await tester.pump();
    expect(find.text('8+'), findsOneWidget);
  });

  testWidgets('Decimal point only added once per number', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('.'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('.'));
    await tester.pump();
    expect(find.text('5.3'), findsOneWidget);
  });

  testWidgets('00 button does not create leading zeros', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('00'));
    await tester.pump();
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('Cannot press = when ending with operator', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('+'));
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();
    expect(find.text('5+'), findsOneWidget);
  });

  testWidgets('Percent does not get replaced by operator', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('%'));
    await tester.pump();
    await tester.tap(find.text('×'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    expect(find.text('50%×2'), findsOneWidget);
  });

  testWidgets('Cannot add percent twice', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('%'));
    await tester.pump();
    await tester.tap(find.text('%'));
    await tester.pump();
    expect(find.text('5%'), findsOneWidget);
  });

  testWidgets('Decimal result removes trailing zeros', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('÷'));
    await tester.pump();
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.text('='));
    await tester.pump();
    expect(find.text('2.5'), findsOneWidget);
  });
}
