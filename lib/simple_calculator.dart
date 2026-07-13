import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';

class CalcButton {
  final String text;
  final Color? color;
  final Color? textColor;
  final int flex;

  const CalcButton(this.text, {this.color, this.textColor, this.flex = 1});
}

class SimpleCalculator extends StatefulWidget {
  const SimpleCalculator({Key? key}) : super(key: key);

  @override
  State<SimpleCalculator> createState() => _SimpleCalculatorState();
}

class _SimpleCalculatorState extends State<SimpleCalculator> {
  String equation = "0";
  String result = "0";
  String _preview = "";
  bool _calculated = false;

  static const _bgColor = Color(0xFF101014);
  static const _numberColor = Color(0xFF2A2A2E);
  static const _functionColor = Color(0xFF3A3A3C);
  static const _operatorColor = Color(0xFF0A84FF);
  static const _accentColor = Color(0xFFFF453A);
  static const _textColor = Colors.white;
  static const _secondaryText = Color(0xFF8E8E93);
  static const _previewText = Color(0xFFAEAEB2);

  static const _infixOperators = {'+', '-', '×', '÷'};

  bool _isInfixOperator(String s) => _infixOperators.contains(s);

  bool get _endsWithOperator {
    if (equation.isEmpty) return false;
    return _isInfixOperator(equation[equation.length - 1]);
  }

  bool get _isErrorResult =>
      result == "Error" || result == "Tidak terdefinisi";

  String _formatResult(String raw) {
    final val = double.tryParse(raw);
    if (val == null) return raw;
    if (val == val.toInt().toDouble() && !raw.contains('e')) {
      return val.toInt().toString();
    }
    var formatted = val.toStringAsFixed(10);
    formatted = formatted.replaceAll(RegExp(r'0+$'), '');
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  String? _tryEvaluate(String eq) {
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
      return _formatResult('$eval');
    } catch (e) {
      return null;
    }
  }

  void _updatePreview() {
    if (_calculated || _endsWithOperator || equation == "0") {
      _preview = "";
      return;
    }
    _preview = _tryEvaluate(equation) ?? "";
    if (_preview == equation) _preview = "";
  }

  String _getLastNumber() {
    var last = "";
    for (int i = equation.length - 1; i >= 0; i--) {
      if (_isInfixOperator(equation[i])) break;
      last = equation[i] + last;
    }
    return last;
  }

  void buttonPressed(String buttonText) {
    HapticFeedback.lightImpact();
    setState(() {
      switch (buttonText) {
        case "AC":
          equation = "0";
          result = "0";
          _preview = "";
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
          _updatePreview();
          break;

        case "=":
          if (!_endsWithOperator && equation != "0") {
            final evalResult = _tryEvaluate(equation);
            result = evalResult ?? "Error";
            _calculated = true;
            _preview = "";
          }
          break;

        case "%":
          if (equation != "0" && !_endsWithOperator && !equation.endsWith('%')) {
            equation += "%";
            _updatePreview();
          }
          break;

        default:
          _handleInput(buttonText);
          _updatePreview();
      }
    });
  }

  void _handleInput(String buttonText) {
    if (_isInfixOperator(buttonText)) {
      if (_calculated) {
        if (_isErrorResult) {
          equation = "0";
          result = "0";
          _calculated = false;
          return;
        }
        equation = result;
        _calculated = false;
      }
      if (equation == "0" && buttonText != '-') return;
      if (_endsWithOperator) {
        equation = equation.substring(0, equation.length - 1) + buttonText;
      } else {
        equation += buttonText;
      }
    } else if (buttonText == ".") {
      if (_calculated) {
        equation = "0.";
        result = "0";
        _calculated = false;
        return;
      }
      final lastNumber = _getLastNumber();
      if (!lastNumber.contains('.')) {
        if (_endsWithOperator) {
          equation += "0.";
        } else if (equation == "0") {
          equation = "0.";
        } else {
          equation += ".";
        }
      }
    } else {
      _handleDigit(buttonText);
    }
  }

  void _handleDigit(String digit) {
    if (_calculated) {
      equation = (digit == "00") ? "0" : digit;
      result = "0";
      _calculated = false;
      return;
    }

    if (equation == "0") {
      equation = (digit == "00") ? "0" : digit;
      return;
    }

    final lastNumber = _getLastNumber();

    if (lastNumber.isEmpty) {
      equation += (digit == "00") ? "0" : digit;
    } else if (lastNumber == "0") {
      if (digit == "0" || digit == "00") return;
      equation = equation.substring(0, equation.length - 1) + digit;
    } else {
      equation += digit;
    }
  }

  Widget _buildButton(CalcButton config) {
    return Expanded(
      flex: config.flex,
      child: Padding(
        padding: const EdgeInsets.all(3.5),
        child: Material(
          color: config.color ?? _numberColor,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shadowColor: Colors.black54,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            onTap: () => buttonPressed(config.text),
            child: Center(
              child: Text(
                config.text,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: config.textColor ?? _textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<CalcButton> buttons) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.map(_buildButton).toList(),
      ),
    );
  }

  String get _displayResult {
    if (_calculated) return result;
    if (_preview.isNotEmpty) return _preview;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final showPreview = !_calculated && _preview.isNotEmpty;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: _calculated ? 26 : 42,
                          fontWeight: FontWeight.w300,
                          color: _calculated ? _secondaryText : _textColor,
                          letterSpacing: 1.5,
                        ),
                        child: Text(
                          equation,
                          key: const Key('equation'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: _calculated ? 52 : (showPreview ? 30 : 28),
                          fontWeight: _calculated ? FontWeight.w400 : FontWeight.w300,
                          color: _calculated
                              ? _textColor
                              : (showPreview ? _previewText : _secondaryText),
                          letterSpacing: 1.0,
                        ),
                        child: Text(
                          _displayResult,
                          key: const Key('result'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x00FFFFFF),
                      Color(0x33FFFFFF),
                      Color(0x00FFFFFF),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
                child: Column(
                  children: [
                    _buildButtonRow([
                      const CalcButton('AC', color: _accentColor),
                      const CalcButton('⌫', color: _functionColor),
                      const CalcButton('%', color: _functionColor),
                      const CalcButton('÷', color: _operatorColor),
                    ]),
                    _buildButtonRow([
                      const CalcButton('7'),
                      const CalcButton('8'),
                      const CalcButton('9'),
                      const CalcButton('×', color: _operatorColor),
                    ]),
                    _buildButtonRow([
                      const CalcButton('4'),
                      const CalcButton('5'),
                      const CalcButton('6'),
                      const CalcButton('-', color: _operatorColor),
                    ]),
                    _buildButtonRow([
                      const CalcButton('1'),
                      const CalcButton('2'),
                      const CalcButton('3'),
                      const CalcButton('+', color: _operatorColor),
                    ]),
                    _buildButtonRow([
                      const CalcButton('00'),
                      const CalcButton('0'),
                      const CalcButton('.'),
                      const CalcButton('=', color: _accentColor),
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
