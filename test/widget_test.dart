import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calculator_bintang/main.dart';

final _eqFinder = find.byKey(const Key('equation'));
final _resFinder = find.byKey(const Key('result'));

String _eq(WidgetTester t) => (t.widget<Text>(_eqFinder)).data!;
String _res(WidgetTester t) => (t.widget<Text>(_resFinder)).data!;

Future<void> _tap(WidgetTester t, String label) async {
  await t.tap(find.text(label));
  await t.pump(const Duration(milliseconds: 250));
}

Future<void> _tapAll(WidgetTester t, List<String> labels) async {
  for (final l in labels) {
    await _tap(t, l);
  }
}

void main() {
  group('Initial state', () {
    testWidgets('shows 0 for equation and result', (t) async {
      await t.pumpWidget(const MyApp());
      expect(_eq(t), '0');
      expect(_res(t), '0');
    });
  });

  group('Number input', () {
    testWidgets('single digit replaces initial 0', (t) async {
      await t.pumpWidget(const MyApp());
      await _tap(t, '5');
      expect(_eq(t), '5');
    });

    testWidgets('multi-digit input', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['1', '2', '3']);
      expect(_eq(t), '123');
    });

    testWidgets('00 on initial state stays 0', (t) async {
      await t.pumpWidget(const MyApp());
      await _tap(t, '00');
      expect(_eq(t), '0');
    });

    testWidgets('00 after operator becomes single 0', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '00']);
      expect(_eq(t), '5+0');
    });

    testWidgets('digit replaces leading zero after operator', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '0', '3']);
      expect(_eq(t), '5+3');
    });

    testWidgets('zero stays single after operator', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '0', '0']);
      expect(_eq(t), '5+0');
    });
  });

  group('Basic operations', () {
    testWidgets('addition', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=']);
      expect(_res(t), '8');
    });

    testWidgets('subtraction', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['9', '-', '4', '=']);
      expect(_res(t), '5');
    });

    testWidgets('multiplication', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['6', '×', '7', '=']);
      expect(_res(t), '42');
    });

    testWidgets('division', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['8', '÷', '2', '=']);
      expect(_res(t), '4');
    });

    testWidgets('division by zero', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '÷', '0', '=']);
      expect(_res(t), 'Tidak terdefinisi');
    });

    testWidgets('decimal result removes trailing zeros', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['1', '0', '÷', '4', '=']);
      expect(_res(t), '2.5');
    });
  });

  group('AC and backspace', () {
    testWidgets('AC clears everything', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', 'AC']);
      expect(_eq(t), '0');
      expect(_res(t), '0');
    });

    testWidgets('backspace removes last char', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['1', '2', '⌫']);
      expect(_eq(t), '1');
    });

    testWidgets('backspace on single digit resets to 0', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '⌫']);
      expect(_eq(t), '0');
    });

    testWidgets('backspace after calculation resets all', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=', '⌫']);
      expect(_eq(t), '0');
      expect(_res(t), '0');
    });
  });

  group('Operator handling', () {
    testWidgets('consecutive operators replaced', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '-']);
      expect(_eq(t), '5-');
    });

    testWidgets('= ignored when ending with operator', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '=']);
      expect(_eq(t), '5+');
    });

    testWidgets('operator after = chains from result', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=', '+']);
      expect(_eq(t), '8+');
    });

    testWidgets('chained calculation across equals', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=', '+', '2', '=']);
      expect(_res(t), '10');
    });
  });

  group('Post-calculation input', () {
    testWidgets('number after = starts fresh', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=', '9']);
      expect(_eq(t), '9');
    });

    testWidgets('operator after error resets', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '÷', '0', '=', '+']);
      expect(_eq(t), '0');
    });
  });

  group('Decimal point', () {
    testWidgets('only once per number', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '.', '3', '.']);
      expect(_eq(t), '5.3');
    });

    testWidgets('allowed in second number', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '.', '3', '+', '1', '.', '2']);
      expect(_eq(t), '5.3+1.2');
    });

    testWidgets('after operator adds 0.', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '.']);
      expect(_eq(t), '5+0.');
    });

    testWidgets('after = starts 0.', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=', '.']);
      expect(_eq(t), '0.');
    });
  });

  group('Percent', () {
    testWidgets('adds percent sign', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '0', '%']);
      expect(_eq(t), '50%');
    });

    testWidgets('not replaced by next operator', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '0', '%', '×', '2']);
      expect(_eq(t), '50%×2');
    });

    testWidgets('cannot add twice', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '%', '%']);
      expect(_eq(t), '5%');
    });

    testWidgets('not allowed after operator', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '%']);
      expect(_eq(t), '5+');
    });
  });

  group('Live preview', () {
    testWidgets('shows preview while typing expression', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3']);
      expect(_res(t), '8');
    });

    testWidgets('no preview for single number', (t) async {
      await t.pumpWidget(const MyApp());
      await _tap(t, '5');
      expect(_res(t), '0');
    });

    testWidgets('no preview when ending with operator', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+']);
      expect(_res(t), '0');
    });
  });
}
