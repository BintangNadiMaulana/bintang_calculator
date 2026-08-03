import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calculator_bintang/models/calc_button.dart';
import 'package:calculator_bintang/models/calc_record.dart';
import 'package:calculator_bintang/utils/calculator_logic.dart';
import 'package:calculator_bintang/utils/formatting.dart';
import 'package:calculator_bintang/widgets/calculator_button.dart';
import 'package:calculator_bintang/widgets/history_sheet.dart';

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

  static final _digitOrCloseOrPercent = RegExp(r'[0-9)%]');
  static final _compoundChars = RegExp(r'[+\-×÷()%]');
  static const _historyKey = 'calc_history';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_historyKey);
    if (data != null) {
      setState(() {
        _history.clear();
        for (final item in data) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          _history.add(CalcRecord(map['eq'] as String, map['res'] as String));
        }
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _history
        .map((r) => jsonEncode({'eq': r.equation, 'res': r.result}))
        .toList();
    await prefs.setStringList(_historyKey, data);
  }

  bool get _endsWithOperator {
    if (equation.isEmpty) return false;
    return CalculatorLogic.isInfixOperator(equation[equation.length - 1]);
  }

  bool get _isErrorResult =>
      result == "Error" || result == "Tidak terdefinisi";

  // ── Preview ──

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

    _preview = CalculatorLogic.tryEvaluate(evalExpr) ?? "";
    if (_preview == equation) _preview = "";
  }

  // ── Helpers ──

  String _getLastNumber() {
    var last = "";
    for (int i = equation.length - 1; i >= 0; i--) {
      final ch = equation[i];
      if (CalculatorLogic.isInfixOperator(ch) || ch == '(' || ch == ')') break;
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

    final evalResult = CalculatorLogic.tryEvaluate(equation);
    result = evalResult ?? "Error";
    _calculated = true;
    _preview = "";

    if (!_isErrorResult) {
      _history.insert(0, CalcRecord(equation, result));
      if (_history.length > 50) _history.removeLast();
      _saveHistory();
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

    if (openCount > closeCount && _digitOrCloseOrPercent.hasMatch(lastChar)) {
      equation += ")";
    } else if (_digitOrCloseOrPercent.hasMatch(lastChar)) {
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
    final isSimple = !withoutMinus.contains(_compoundChars);

    if (isSimple) {
      equation =
          equation.startsWith('-') ? equation.substring(1) : '-$equation';
    }
  }

  void _handleInput(String buttonText) {
    if (CalculatorLogic.isInfixOperator(buttonText)) {
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
      builder: (_) => HistorySheet(
        history: _history,
        formatEquation: Formatting.formatEquationDisplay,
        formatNumber: Formatting.addThousandsSeparator,
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
          _saveHistory();
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

  Widget _buildButtonRow(List<CalcButton> buttons, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons
            .map((b) => CalculatorButtonWidget(
                  config: b,
                  defaultColor: _numberColor,
                  defaultTextColor: _textColor,
                  onPressed: buttonPressed,
                ))
            .toList(),
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
                          const Text('swipe → hapus',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0x508E8E93))),
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
                                  Formatting.formatEquationDisplay(equation),
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
                                    Formatting.addThousandsSeparator(
                                        _displayResult),
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
                      const CalcButton('()', color: _functionColor, semanticLabel: 'Kurung'),
                      const CalcButton('⌫', color: _functionColor, semanticLabel: 'Hapus'),
                      const CalcButton('%', color: _functionColor, semanticLabel: 'Persen'),
                      const CalcButton('AC', color: _accentColor, semanticLabel: 'Hapus semua'),
                    ]),
                    _buildButtonRow([
                      const CalcButton('7'),
                      const CalcButton('8'),
                      const CalcButton('9'),
                      const CalcButton('÷', color: _operatorColor, semanticLabel: 'Bagi'),
                    ]),
                    _buildButtonRow([
                      const CalcButton('4'),
                      const CalcButton('5'),
                      const CalcButton('6'),
                      const CalcButton('×', color: _operatorColor, semanticLabel: 'Kali'),
                    ]),
                    _buildButtonRow([
                      const CalcButton('1'),
                      const CalcButton('2'),
                      const CalcButton('3'),
                      const CalcButton('-', color: _operatorColor, semanticLabel: 'Kurang'),
                    ]),
                    _buildButtonRow([
                      const CalcButton('±', semanticLabel: 'Plus minus'),
                      const CalcButton('0'),
                      const CalcButton('.', semanticLabel: 'Titik desimal'),
                      const CalcButton('+', color: _operatorColor, semanticLabel: 'Tambah'),
                    ]),
                    SizedBox(
                      height: 52,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CalculatorButtonWidget(
                            config: const CalcButton('=', color: _equalsColor, semanticLabel: 'Sama dengan'),
                            defaultColor: _numberColor,
                            defaultTextColor: _textColor,
                            onPressed: buttonPressed,
                          ),
                        ],
                      ),
                    ),
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
