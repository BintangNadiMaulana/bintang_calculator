import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';

class SimpleCalculator extends StatefulWidget {
  const SimpleCalculator({Key? key}) : super(key: key);

  @override
  State<SimpleCalculator> createState() => _SimpleCalculatorState();
}

class _SimpleCalculatorState extends State<SimpleCalculator> {
  String equation = "0";
  String result = "0";
  bool _calculated = false;

  static const Color _bgColor = Color(0xFF1C1C1E);
  static const Color _numberColor = Color(0xFF2C2C2E);
  static const Color _functionColor = Color(0xFF3A3A3C);
  static const Color _operatorColor = Color(0xFF0A84FF);
  static const Color _accentColor = Color(0xFFFF453A);
  static const Color _textColor = Colors.white;
  static const Color _secondaryText = Color(0xFFA1A1A6);
  static const Color _dividerColor = Color(0x1AFFFFFF);

  static const Set<String> _infixOperators = {'+', '-', '×', '÷'};

  bool _isInfixOperator(String s) => _infixOperators.contains(s);

  bool _endsWithOperator() {
    if (equation.isEmpty) return false;
    return _isInfixOperator(equation[equation.length - 1]);
  }

  String _formatResult(String raw) {
    double? val = double.tryParse(raw);
    if (val == null) return raw;
    if (val == val.toInt().toDouble() && !raw.contains('e')) {
      return val.toInt().toString();
    }
    String formatted = val.toStringAsFixed(10);
    formatted = formatted.replaceAll(RegExp(r'0+$'), '');
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  void buttonPressed(String buttonText) {
    HapticFeedback.lightImpact();
    setState(() {
      switch (buttonText) {
        case "AC":
          equation = "0";
          result = "0";
          _calculated = false;
          break;

        case "⌫":
          if (_calculated) {
            equation = "0";
            result = "0";
            _calculated = false;
          } else if (equation.length > 1) {
            equation = equation.substring(0, equation.length - 1);
          } else {
            equation = "0";
          }
          break;

        case "=":
          if (!_endsWithOperator()) {
            _calculate();
          }
          break;

        case "%":
          if (equation != "0" && !_endsWithOperator() && !equation.endsWith('%')) {
            equation = equation + "%";
          }
          break;

        default:
          _handleInput(buttonText);
      }
    });
  }

  void _handleInput(String buttonText) {
    if (_isInfixOperator(buttonText)) {
      if (_calculated) {
        equation = result;
        _calculated = false;
      }
      if (equation == "0" && buttonText != '-') return;
      if (_endsWithOperator()) {
        equation = equation.substring(0, equation.length - 1) + buttonText;
      } else {
        equation = equation + buttonText;
      }
    } else if (buttonText == ".") {
      if (_calculated) {
        equation = "0.";
        result = "0";
        _calculated = false;
        return;
      }
      String lastNumber = _getLastNumber();
      if (!lastNumber.contains('.')) {
        if (_endsWithOperator()) {
          equation = equation + "0.";
        } else if (equation == "0") {
          equation = "0.";
        } else {
          equation = equation + ".";
        }
      }
    } else {
      if (_calculated) {
        equation = (buttonText == "00") ? "0" : buttonText;
        result = "0";
        _calculated = false;
      } else if (equation == "0") {
        equation = (buttonText == "00") ? "0" : buttonText;
      } else {
        String lastNumber = _getLastNumber();
        if (lastNumber == "0" && buttonText == "00") return;
        equation = equation + buttonText;
      }
    }
  }

  String _getLastNumber() {
    String last = "";
    for (int i = equation.length - 1; i >= 0; i--) {
      if (_isInfixOperator(equation[i])) break;
      last = equation[i] + last;
    }
    return last;
  }

  void _calculate() {
    String expr = equation;
    expr = expr.replaceAll('×', '*');
    expr = expr.replaceAll('÷', '/');
    expr = expr.replaceAll('%', '/100');

    try {
      Parser p = Parser();
      Expression exp = p.parse(expr);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      if (eval.isInfinite) {
        result = "Tidak terdefinisi";
      } else if (eval.isNaN) {
        result = "Error";
      } else {
        result = _formatResult('$eval');
      }
    } catch (e) {
      result = "Error";
    }
    _calculated = true;
  }

  Widget _buildButton(String text, {Color? color, Color? textColor, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: color ?? _numberColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            onTap: () => buttonPressed(text),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? _textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<Map<String, dynamic>> buttons) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.map((b) {
          return _buildButton(
            b['text'] as String,
            color: b['color'] as Color?,
            textColor: b['textColor'] as Color?,
            flex: (b['flex'] as int?) ?? 1,
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        equation,
                        style: TextStyle(
                          fontSize: _calculated ? 28 : 44,
                          fontWeight: FontWeight.w300,
                          color: _calculated ? _secondaryText : _textColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        result,
                        style: TextStyle(
                          fontSize: _calculated ? 52 : 32,
                          fontWeight: _calculated ? FontWeight.w400 : FontWeight.w300,
                          color: _calculated ? _textColor : _secondaryText,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: _dividerColor, height: 1),
            ),

            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Column(
                  children: [
                    _buildButtonRow([
                      {'text': 'AC', 'color': _accentColor},
                      {'text': '⌫', 'color': _functionColor},
                      {'text': '%', 'color': _functionColor},
                      {'text': '÷', 'color': _operatorColor},
                    ]),
                    _buildButtonRow([
                      {'text': '7'},
                      {'text': '8'},
                      {'text': '9'},
                      {'text': '×', 'color': _operatorColor},
                    ]),
                    _buildButtonRow([
                      {'text': '4'},
                      {'text': '5'},
                      {'text': '6'},
                      {'text': '-', 'color': _operatorColor},
                    ]),
                    _buildButtonRow([
                      {'text': '1'},
                      {'text': '2'},
                      {'text': '3'},
                      {'text': '+', 'color': _operatorColor},
                    ]),
                    _buildButtonRow([
                      {'text': '00'},
                      {'text': '0'},
                      {'text': '.'},
                      {'text': '=', 'color': _accentColor},
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

