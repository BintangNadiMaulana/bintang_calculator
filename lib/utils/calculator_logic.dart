import 'package:math_expressions/math_expressions.dart';

class CalculatorLogic {
  static const infixOperators = {'+', '-', '×', '÷'};

  static bool isInfixOperator(String s) => infixOperators.contains(s);

  static String formatResult(String raw) {
    final val = double.tryParse(raw);
    if (val == null) return raw;

    if (val.abs() >= 1e12 || (val != 0 && val.abs() < 1e-8)) {
      return val.toStringAsPrecision(6);
    }

    if (val == val.toInt().toDouble() && val.abs() < 1e15) {
      return val.toInt().toString();
    }

    var formatted = val.toStringAsFixed(10);
    formatted = formatted.replaceAll(RegExp(r'0+$'), '');
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  static String? tryEvaluate(String eq) {
    var expr = eq;
    expr = expr.replaceAll('×', '*');
    expr = expr.replaceAll('÷', '/');
    expr = expr.replaceAll('%', '/100');

    try {
      final p = Parser();
      final exp = p.parse(expr);
      final cm = ContextModel();
      final eval = exp.evaluate(EvaluationType.REAL, cm);

      if (eval.isInfinite) return "Tidak terdefinisi";
      if (eval.isNaN) return "Error";
      return formatResult('$eval');
    } catch (e) {
      return null;
    }
  }
}
