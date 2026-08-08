import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calculator_bintang/main.dart';
import 'package:calculator_bintang/utils/calculator_logic.dart';
import 'package:calculator_bintang/utils/formatting.dart';

final _eqFinder = find.byKey(const Key('equation'));
final _resFinder = find.byKey(const Key('result'));

/// Membaca teks baris ekspresi yang sedang tampil.
String _eq(WidgetTester t) => (t.widget<Text>(_eqFinder)).data!;

/// Membaca teks baris hasil yang sedang tampil.
String _res(WidgetTester t) => (t.widget<Text>(_resFinder)).data!;

/// Menekan satu tombol lalu menunggu animasi teks selesai.
Future<void> _tap(WidgetTester t, String label) async {
  await t.tap(find.text(label));
  await t.pump(const Duration(milliseconds: 250));
}

/// Menekan sederet tombol secara berurutan.
Future<void> _tapAll(WidgetTester t, List<String> labels) async {
  for (final l in labels) {
    await _tap(t, l);
  }
}

void main() {
  // Widget test berjalan tanpa plugin platform asli, jadi penyimpanan
  // lokal diganti dengan versi tiruan yang selalu dimulai kosong.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

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

    testWidgets('digit replaces leading zero after operator', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '0', '3']);
      expect(_eq(t), '5 + 3');
    });

    testWidgets('zero stays single after operator', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '0', '0']);
      expect(_eq(t), '5 + 0');
    });

    testWidgets('digit blocked after close paren', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['()', '5', '()', '3']);
      expect(_eq(t), '(5)');
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
      expect(_eq(t), '5 - ');
    });

    testWidgets('= ignored when ending with operator', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '=']);
      expect(_eq(t), '5 + ');
    });

    testWidgets('operator after = chains from result', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=', '+']);
      expect(_eq(t), '8 + ');
    });

    testWidgets('chained calculation across equals', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=', '+', '2', '=']);
      expect(_res(t), '10');
    });

    testWidgets('multiple = does not re-evaluate', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=', '=']);
      expect(_res(t), '8');
      expect(_eq(t), '5 + 3');
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
      expect(_eq(t), '5.3 + 1.2');
    });

    testWidgets('after operator adds 0.', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '.']);
      expect(_eq(t), '5 + 0.');
    });

    testWidgets('after = starts 0.', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=', '.']);
      expect(_eq(t), '0.');
    });

    testWidgets('blocked after close paren', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['()', '5', '()', '.']);
      expect(_eq(t), '(5)');
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
      expect(_eq(t), '50% × 2');
    });

    testWidgets('cannot add twice', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '%', '%']);
      expect(_eq(t), '5%');
    });

    testWidgets('not allowed after operator', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '%']);
      expect(_eq(t), '5 + ');
    });
  });

  group('Parentheses', () {
    testWidgets('() on initial state opens paren', (t) async {
      await t.pumpWidget(const MyApp());
      await _tap(t, '()');
      expect(_eq(t), '(');
    });

    testWidgets('basic parenthesized expression', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['()', '5', '+', '3', '()', '×', '2', '=']);
      expect(_res(t), '16');
    });

    testWidgets('auto-closes unclosed parens on =', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['()', '5', '+', '3', '×', '2', '=']);
      expect(_res(t), '11');
    });

    testWidgets('implicit multiply before open paren', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '()', '3', '+', '2', '()', '=']);
      expect(_eq(t), '5 × (3 + 2)');
      expect(_res(t), '25');
    });

    testWidgets('nested parentheses', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['()', '()', '2', '+', '3', '()', '()', '×', '4', '=']);
      expect(_res(t), '20');
    });
  });

  group('Sign toggle ±', () {
    testWidgets('negates simple number', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '±']);
      expect(_eq(t), '-5');
    });

    testWidgets('double toggle returns to positive', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '±', '±']);
      expect(_eq(t), '5');
    });

    testWidgets('does nothing on 0', (t) async {
      await t.pumpWidget(const MyApp());
      await _tap(t, '±');
      expect(_eq(t), '0');
    });

    testWidgets('negates result after =', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=', '±']);
      expect(_eq(t), '-8');
    });

    testWidgets('does nothing in compound expression', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '±']);
      expect(_eq(t), '5 + 3');
    });
  });

  group('Display formatting', () {
    testWidgets('operators have spaces', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '×', '2']);
      expect(_eq(t), '5 + 3 × 2');
    });

    testWidgets('unary minus has no space', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '±']);
      expect(_eq(t), '-5');
    });

    testWidgets('thousands separator on result', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['9', '9', '9', '×', '9', '9', '9', '=']);
      expect(_res(t), '998,001');
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

    testWidgets('preview auto-closes parens', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['()', '5', '+', '3']);
      expect(_res(t), '8');
    });
  });

  group('History', () {
    testWidgets('history icon exists', (t) async {
      await t.pumpWidget(const MyApp());
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('empty history shows snackbar', (t) async {
      await t.pumpWidget(const MyApp());
      await t.tap(find.byIcon(Icons.history));
      await t.pump();
      expect(find.text('Belum ada riwayat'), findsOneWidget);
    });

    testWidgets('calculation adds to history', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=']);
      await t.tap(find.byIcon(Icons.history));
      await t.pumpAndSettle();
      expect(find.text('Riwayat'), findsOneWidget);
    });

    testWidgets('history entry can be reused', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=']);
      await t.tap(find.byIcon(Icons.history));
      await t.pumpAndSettle();

      await t.tap(find.text('= 8'));
      await t.pumpAndSettle();
      expect(_eq(t), '8');
    });

    testWidgets('clearing history empties the sheet', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=']);
      await t.tap(find.byIcon(Icons.history));
      await t.pumpAndSettle();

      await t.tap(find.text('Hapus Riwayat'));
      await t.pumpAndSettle();

      await t.tap(find.byIcon(Icons.history));
      await t.pump();
      expect(find.text('Belum ada riwayat'), findsOneWidget);
    });

    testWidgets('history survives app restart', (t) async {
      await t.pumpWidget(const MyApp());
      await _tapAll(t, ['5', '+', '3', '=']);
      await t.pumpAndSettle();

      // Ganti dulu dengan widget lain agar State lama benar-benar dilepas,
      // sehingga `initState` berjalan lagi seperti saat aplikasi dibuka ulang.
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();

      await t.pumpWidget(const MyApp());
      await t.pumpAndSettle();

      await t.tap(find.byIcon(Icons.history));
      await t.pumpAndSettle();
      expect(find.text('= 8'), findsOneWidget);
    });
  });

  group('Accessibility', () {
    testWidgets('symbol buttons expose readable labels', (t) async {
      await t.pumpWidget(const MyApp());
      final handle = t.ensureSemantics();

      // Simbol seperti × dan ÷ tidak terbaca jelas oleh screen reader,
      // jadi tiap tombol menyediakan label dalam Bahasa Indonesia.
      for (final label in [
        'Kali',
        'Bagi',
        'Tambah',
        'Kurang',
        'Sama dengan',
        'Persen',
        'Hapus',
        'Hapus semua',
        'Kurung',
        'Plus minus',
        'Titik desimal',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget,
            reason: 'label "$label" tidak ditemukan');
      }

      handle.dispose();
    });
  });

  group('CalculatorLogic', () {
    test('recognises infix operators', () {
      expect(CalculatorLogic.isInfixOperator('+'), isTrue);
      expect(CalculatorLogic.isInfixOperator('×'), isTrue);
      expect(CalculatorLogic.isInfixOperator('5'), isFalse);
      expect(CalculatorLogic.isInfixOperator('('), isFalse);
    });

    test('formats integers without decimal part', () {
      expect(CalculatorLogic.formatResult('8.0'), '8');
      expect(CalculatorLogic.formatResult('-3.0'), '-3');
    });

    test('trims trailing zeros from decimals', () {
      expect(CalculatorLogic.formatResult('2.500'), '2.5');
    });

    test('uses scientific notation for extreme values', () {
      expect(CalculatorLogic.formatResult('1e13'), contains('e'));
      expect(CalculatorLogic.formatResult('1e-10'), contains('e'));
    });

    test('returns null for unparseable input', () {
      expect(CalculatorLogic.tryEvaluate('5+'), isNull);
    });

    test('reports division by zero as undefined', () {
      expect(CalculatorLogic.tryEvaluate('5÷0'), 'Tidak terdefinisi');
    });

    test('converts percent to division by hundred', () {
      expect(CalculatorLogic.tryEvaluate('50%'), '0.5');
    });
  });

  group('Formatting', () {
    test('spaces binary operators', () {
      expect(Formatting.formatEquationDisplay('5+3×2'), '5 + 3 × 2');
    });

    test('keeps unary minus tight', () {
      expect(Formatting.formatEquationDisplay('-5'), '-5');
      expect(Formatting.formatEquationDisplay('5+-3'), '5 + -3');
      expect(Formatting.formatEquationDisplay('(-5)'), '(-5)');
    });

    test('adds thousands separators', () {
      expect(Formatting.addThousandsSeparator('998001'), '998,001');
      expect(Formatting.addThousandsSeparator('1234567'), '1,234,567');
    });

    test('separates only the integer part', () {
      expect(Formatting.addThousandsSeparator('1234.5678'), '1,234.5678');
    });

    test('handles negative numbers', () {
      expect(Formatting.addThousandsSeparator('-9876'), '-9,876');
    });

    test('leaves errors and scientific notation untouched', () {
      expect(Formatting.addThousandsSeparator('Error'), 'Error');
      expect(
        Formatting.addThousandsSeparator('Tidak terdefinisi'),
        'Tidak terdefinisi',
      );
      expect(Formatting.addThousandsSeparator('1.00000e+13'), '1.00000e+13');
    });
  });
}
