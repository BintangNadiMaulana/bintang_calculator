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

  testWidgets('New input after calculation resets equation', (WidgetTester tester) async {
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
}
