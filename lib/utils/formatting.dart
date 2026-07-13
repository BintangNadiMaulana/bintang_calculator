import 'package:calculator_bintang/utils/calculator_logic.dart';

class Formatting {
  static String formatEquationDisplay(String eq) {
    final buf = StringBuffer();
    for (int i = 0; i < eq.length; i++) {
      final ch = eq[i];
      if (ch == '+' || ch == '×' || ch == '÷') {
        buf.write(' $ch ');
      } else if (ch == '-') {
        final isUnary = i == 0 ||
            eq[i - 1] == '(' ||
            CalculatorLogic.isInfixOperator(eq[i - 1]);
        buf.write(isUnary ? ch : ' $ch ');
      } else {
        buf.write(ch);
      }
    }
    return buf.toString();
  }

  static String addThousandsSeparator(String num) {
    if (num == "Error" || num == "Tidak terdefinisi" || num == "0") return num;
    if (num.contains('e') || num.contains('E')) return num;

    final negative = num.startsWith('-');
    var body = negative ? num.substring(1) : num;

    String intPart;
    String? decPart;
    if (body.contains('.')) {
      final idx = body.indexOf('.');
      intPart = body.substring(0, idx);
      decPart = body.substring(idx + 1);
    } else {
      intPart = body;
    }

    final buf = StringBuffer();
    final len = intPart.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }

    var out = buf.toString();
    if (decPart != null) out = '$out.$decPart';
    return negative ? '-$out' : out;
  }
}
