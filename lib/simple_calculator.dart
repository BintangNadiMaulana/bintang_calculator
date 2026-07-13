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

class CalcRecord {
  final String equation;
  final String result;
  const CalcRecord(this.equation, this.result);
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
  final List<CalcRecord> _history = [];

  static const _bgColor = Color(0xFF101014);
  static const _numberColor = Color(0xFF2A2A2E);
  static const _functionColor = Color(0xFF3A3A3C);
  static const _operatorColor = Color(0xFF0A84FF);
  static const _accentColor = Color(0xFFFF453A);
  static const _textColor = Colors.white;
  static const _secondaryText = Color(0xFF8E8E93);
  static const _previewText = Color(0xFFAEAEB2);
  static const _equalsColor = Color(0xFF30D158);

  static const _infixOperators = {'+', '-', '×', '÷'};

  bool _isInfixOperator(String s) => _infixOperators.contains(s);

  bool get _endsWithOperator {
    if (equation.isEmpty) return false;
    return _isInfixOperator(equation[equation.length - 1]);
  }

  bool get _isErrorResult =>
      result == "Error" || result == "Tidak terdefinisi";

  // ── Formatting ──

  String _formatResult(String raw) {
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

  String formatEquationDisplay(String eq) {
    final buf = StringBuffer();
    for (int i = 0; i < eq.length; i++) {
      final ch = eq[i];
      if (ch == '+' || ch == '×' || ch == '÷') {
        buf.write(' $ch ');
      } else if (ch == '-') {
        final isUnary = i == 0 ||
            eq[i - 1] == '(' ||
            _isInfixOperator(eq[i - 1]);
        buf.write(isUnary ? ch : ' $ch ');
      } else {
        buf.write(ch);
      }
    }
    return buf.toString();
  }

  String addThousandsSeparator(String num) {
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

  // ── Evaluation ──

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
    if (_calculated || _endsWithOperator ||
        equation == "0" || equation.endsWith('(')) {
      _preview = "";
      return;
    }

    final openCount = '('.allMatches(equation).length;
    final closeCount = ')'.allMatches(equation).length;

    var evalExpr = equation;
    for (int i = 0; i < openCount - closeCount; i++) {
      evalExpr += ')';
    }

    _preview = _tryEvaluate(evalExpr) ?? "";
    if (_preview == equation) _preview = "";
  }

  // ── Helpers ──

  String _getLastNumber() {
    var last = "";
    for (int i = equation.length - 1; i >= 0; i--) {
      final ch = equation[i];
      if (_isInfixOperator(ch) || ch == '(' || ch == ')') break;
      last = ch + last;
    }
    return last;
  }

  // ── Input handling ──

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
          _handleBackspace();
          _updatePreview();
          break;
        case "=":
          _handleEquals();
          break;
        case "%":
          _handlePercent();
          _updatePreview();
          break;
        case "()":
          _handleParenthesis();
          _updatePreview();
          break;
        case "±":
          _handleSignToggle();
          _updatePreview();
          break;
        default:
          _handleInput(buttonText);
          _updatePreview();
      }
    });
  }

  void _handleBackspace() {
    if (_calculated) {
      equation = "0";
      result = "0";
      _calculated = false;
    } else if (equation.length > 1) {
      equation = equation.substring(0, equation.length - 1);
    } else {
      equation = "0";
    }
  }

  void _handleEquals() {
    if (_endsWithOperator || equation == "0" || equation.endsWith('(')) return;
    if (_calculated) return;

    final openCount = '('.allMatches(equation).length;
    final closeCount = ')'.allMatches(equation).length;
    for (int i = 0; i < openCount - closeCount; i++) {
      equation += ')';
    }

    final evalResult = _tryEvaluate(equation);
    result = evalResult ?? "Error";
    _calculated = true;
    _preview = "";

    if (!_isErrorResult) {
      _history.insert(0, CalcRecord(equation, result));
      if (_history.length > 50) _history.removeLast();
    }
  }

  void _handlePercent() {
    if (equation == "0" || _endsWithOperator ||
        equation.endsWith('%') || equation.endsWith('(')) return;
    equation += "%";
  }

  void _handleParenthesis() {
    if (_calculated) {
      equation = "(";
      result = "0";
      _calculated = false;
      return;
    }

    if (equation == "0") {
      equation = "(";
      return;
    }

    final lastChar = equation[equation.length - 1];
    final openCount = '('.allMatches(equation).length;
    final closeCount = ')'.allMatches(equation).length;

    if (openCount > closeCount && RegExp(r'[0-9)%]').hasMatch(lastChar)) {
      equation += ")";
    } else if (RegExp(r'[0-9)%]').hasMatch(lastChar)) {
      equation += "×(";
    } else {
      equation += "(";
    }
  }

  void _handleSignToggle() {
    if (equation == "0") return;

    if (_calculated) {
      if (_isErrorResult || result == "0") return;
      equation = result.startsWith('-') ? result.substring(1) : '-$result';
      result = "0";
      _calculated = false;
      return;
    }

    final withoutMinus =
        equation.startsWith('-') ? equation.substring(1) : equation;
    final isSimple = !withoutMinus.contains(RegExp(r'[+\-×÷()%]'));

    if (isSimple) {
      equation =
          equation.startsWith('-') ? equation.substring(1) : '-$equation';
    }
  }

  void _handleInput(String buttonText) {
    if (_isInfixOperator(buttonText)) {
      _handleOperator(buttonText);
    } else if (buttonText == ".") {
      _handleDot();
    } else {
      _handleDigit(buttonText);
    }
  }

  void _handleOperator(String op) {
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

    if (equation.endsWith('(') && op != '-') return;
    if (equation == "0" && op != '-') return;

    if (_endsWithOperator) {
      equation = equation.substring(0, equation.length - 1) + op;
    } else {
      equation += op;
    }
  }

  void _handleDot() {
    if (_calculated) {
      equation = "0.";
      result = "0";
      _calculated = false;
      return;
    }

    if (equation.endsWith(')') || equation.endsWith('%')) return;

    final lastNumber = _getLastNumber();
    if (!lastNumber.contains('.')) {
      if (_endsWithOperator || equation.endsWith('(')) {
        equation += "0.";
      } else if (equation == "0") {
        equation = "0.";
      } else {
        equation += ".";
      }
    }
  }

  void _handleDigit(String digit) {
    if (_calculated) {
      equation = (digit == "00") ? "0" : digit;
      result = "0";
      _calculated = false;
      return;
    }

    if (equation.endsWith(')') || equation.endsWith('%')) return;

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

  // ── Actions ──

  void _onSwipeDelete() {
    HapticFeedback.lightImpact();
    setState(() {
      _handleBackspace();
      _updatePreview();
    });
  }

  void _copyResult() {
    final text = _calculated
        ? result
        : (_preview.isNotEmpty ? _preview : null);
    if (text == null || text == "0") return;

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Disalin: $text'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _functionColor,
      ),
    );
  }

  void _showHistory() {
    if (_history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada riwayat'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HistorySheet(
        history: _history,
        formatEquation: formatEquationDisplay,
        formatNumber: addThousandsSeparator,
        onTap: (record) {
          setState(() {
            equation = record.result;
            result = "0";
            _preview = "";
            _calculated = false;
          });
          Navigator.pop(context);
        },
        onClear: () {
          setState(() => _history.clear());
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── UI ──

  String get _displayResult {
    if (_calculated) return result;
    if (_preview.isNotEmpty) return _preview;
    return result;
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

  Widget _buildButtonRow(List<CalcButton> buttons, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.map(_buildButton).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPreview = !_calculated && _preview.isNotEmpty;
    final sw = MediaQuery.of(context).size.width;
    final eqSize = sw * (_calculated ? 0.06 : 0.095);
    final resSize = sw * (_calculated ? 0.12 : (showPreview ? 0.07 : 0.065));

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Display ──
            Expanded(
              flex: 2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) > 100) _onSwipeDelete();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _showHistory,
                            child: const Icon(Icons.history,
                                color: _secondaryText, size: 22),
                          ),
                          const Spacer(),
                          Text('swipe → hapus',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: const Color(0x508E8E93))),
                        ],
                      ),
                      Expanded(
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
                                  fontSize: eqSize.clamp(18.0, 48.0),
                                  fontWeight: FontWeight.w300,
                                  color: _calculated
                                      ? _secondaryText
                                      : _textColor,
                                  letterSpacing: 1.2,
                                ),
                                child: Text(
                                  formatEquationDisplay(equation),
                                  key: const Key('equation'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onLongPress: _copyResult,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: resSize.clamp(20.0, 56.0),
                                    fontWeight: _calculated
                                        ? FontWeight.w400
                                        : FontWeight.w300,
                                    color: _calculated
                                        ? _textColor
                                        : (showPreview
                                            ? _previewText
                                            : _secondaryText),
                                    letterSpacing: 0.8,
                                  ),
                                  child: Text(
                                    addThousandsSeparator(_displayResult),
                                    key: const Key('result'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Color(0x00FFFFFF),
                    Color(0x33FFFFFF),
                    Color(0x00FFFFFF),
                  ]),
                ),
              ),
            ),

            // ── Buttons ──
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
                child: Column(
                  children: [
                    _buildButtonRow([
                      const CalcButton('()', color: _functionColor),
                      const CalcButton('⌫', color: _functionColor),
                      const CalcButton('%', color: _functionColor),
                      const CalcButton('AC', color: _accentColor),
                    ]),
                    _buildButtonRow([
                      const CalcButton('7'),
                      const CalcButton('8'),
                      const CalcButton('9'),
                      const CalcButton('÷', color: _operatorColor),
                    ]),
                    _buildButtonRow([
                      const CalcButton('4'),
                      const CalcButton('5'),
                      const CalcButton('6'),
                      const CalcButton('×', color: _operatorColor),
                    ]),
                    _buildButtonRow([
                      const CalcButton('1'),
                      const CalcButton('2'),
                      const CalcButton('3'),
                      const CalcButton('-', color: _operatorColor),
                    ]),
                    _buildButtonRow([
                      const CalcButton('±'),
                      const CalcButton('0'),
                      const CalcButton('.'),
                      const CalcButton('+', color: _operatorColor),
                    ]),
                    _buildButtonRow([
                      const CalcButton('=', color: _equalsColor),
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

class _HistorySheet extends StatelessWidget {
  final List<CalcRecord> history;
  final String Function(String) formatEquation;
  final String Function(String) formatNumber;
  final void Function(CalcRecord) onTap;
  final VoidCallback onClear;

  const _HistorySheet({
    required this.history,
    required this.formatEquation,
    required this.formatNumber,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF8E8E93),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Riwayat',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 8),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: history.length,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemBuilder: (_, i) {
              final r = history[i];
              return InkWell(
                onTap: () => onTap(r),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatEquation(r.equation),
                          style: const TextStyle(
                              fontSize: 16, color: Color(0xFF8E8E93))),
                      const SizedBox(height: 4),
                      Text('= ${formatNumber(r.result)}',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onClear,
                style:
                    TextButton.styleFrom(foregroundColor: const Color(0xFFFF453A)),
                child: const Text('Hapus Riwayat'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
