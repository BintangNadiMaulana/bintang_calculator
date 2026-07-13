import 'package:flutter/material.dart';
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
  static const Color _displayBg = Color(0xFF1C1C1E);
  static const Color _numberColor = Color(0xFF2C2C2E);
  static const Color _operatorColor = Color(0xFF0A84FF);
  static const Color _accentColor = Color(0xFFFF453A);
  static const Color _textColor = Colors.white;
  static const Color _secondaryText = Color(0xFFA1A1A6);

  static const Set<String> _operators = {'+', '-', '×', '÷', '%'};

  bool _isOperator(String s) => _operators.contains(s);

  bool _endsWithOperator() {
    if (equation.isEmpty) return false;
    return _isOperator(equation[equation.length - 1]);
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
          _calculate();
          break;

        case "%":
          if (equation != "0" && !_endsWithOperator()) {
            equation = equation + "%";
          }
          break;

        default:
          _handleInput(buttonText);
      }
    });
  }

  void _handleInput(String buttonText) {
    if (_isOperator(buttonText)) {
      _calculated = false;
      if (equation == "0" && buttonText != '-') return;
      if (_endsWithOperator()) {
        equation = equation.substring(0, equation.length - 1) + buttonText;
      } else {
        equation = equation + buttonText;
      }
    } else if (buttonText == ".") {
      _calculated = false;
      String lastNumber = _getLastNumber();
      if (!lastNumber.contains('.')) {
        if (_endsWithOperator() || equation == "0") {
          if (equation == "0") {
            equation = "0.";
          } else {
            equation = equation + "0.";
          }
        } else {
          equation = equation + ".";
        }
      }
    } else {
      if (_calculated) {
        equation = buttonText;
        result = "0";
        _calculated = false;
      } else if (equation == "0") {
        equation = buttonText;
      } else {
        equation = equation + buttonText;
      }
    }
  }

  String _getLastNumber() {
    String last = "";
    for (int i = equation.length - 1; i >= 0; i--) {
      if (_isOperator(equation[i])) break;
      last = equation[i] + last;
    }
    return last;
  }

  void _calculate() {
    String expression = equation;
    expression = expression.replaceAll('×', '*');
    expression = expression.replaceAll('÷', '/');
    expression = expression.replaceAll('%', '/100');

    try {
      Parser p = Parser();
      Expression exp = p.parse(expression);
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
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => buttonPressed(text),
            child: Container(
              height: 70,
              alignment: Alignment.center,
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
    return Row(
      children: buttons.map((b) {
        return _buildButton(
          b['text'] as String,
          color: b['color'] as Color?,
          textColor: b['textColor'] as Color?,
          flex: (b['flex'] as int?) ?? 1,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Display area
            Expanded(
              child: Container(
                color: _displayBg,
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
                          fontSize: _calculated ? 32 : 48,
                          fontWeight: FontWeight.w300,
                          color: _calculated ? _secondaryText : _textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        result,
                        style: TextStyle(
                          fontSize: _calculated ? 56 : 36,
                          fontWeight: _calculated ? FontWeight.w400 : FontWeight.w300,
                          color: _calculated ? _textColor : _secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            ),

            // Button grid
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              child: Column(
                children: [
                  _buildButtonRow([
                    {'text': 'AC', 'color': _accentColor},
                    {'text': '⌫', 'color': const Color(0xFF3A3A3C)},
                    {'text': '%', 'color': const Color(0xFF3A3A3C)},
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
          ],
        ),
      ),
    );
  }
}
