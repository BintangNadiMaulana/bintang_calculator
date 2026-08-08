import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:calculator_bintang/models/calc_button.dart';
import 'package:calculator_bintang/models/calc_record.dart';
import 'package:calculator_bintang/utils/calculator_logic.dart';
import 'package:calculator_bintang/utils/formatting.dart';
import 'package:calculator_bintang/utils/history_storage.dart';
import 'package:calculator_bintang/widgets/calculator_button.dart';
import 'package:calculator_bintang/widgets/history_sheet.dart';

/// Layar utama kalkulator.
///
/// Seluruh state dan logika input berada di sini, sementara tampilan tombol
/// dan panel riwayat didelegasikan ke widget terpisah.
class SimpleCalculator extends StatefulWidget {
  const SimpleCalculator({super.key});

  @override
  State<SimpleCalculator> createState() => _SimpleCalculatorState();
}

class _SimpleCalculatorState extends State<SimpleCalculator> {
  // ── State ──

  /// Ekspresi mentah yang sedang diketik, tanpa spasi. Contoh: `"5+3×2"`.
  String equation = '0';

  /// Hasil terakhir setelah tombol `=` ditekan.
  String result = '0';

  /// Hasil sementara yang dihitung otomatis saat pengguna mengetik.
  String _preview = '';

  /// Menandai bahwa `=` baru saja ditekan. Flag ini menentukan bagaimana
  /// input berikutnya diperlakukan — melanjutkan hasil atau memulai baru.
  bool _calculated = false;

  final List<CalcRecord> _history = [];
  final HistoryStorage _storage = const HistoryStorage();

  // ── Konstanta warna ──

  static const _bgColor = Color(0xFF101014);
  static const _numberColor = Color(0xFF2A2A2E);
  static const _functionColor = Color(0xFF3A3A3C);
  static const _operatorColor = Color(0xFF0A84FF);
  static const _accentColor = Color(0xFFFF453A);
  static const _textColor = Colors.white;
  static const _secondaryText = Color(0xFF8E8E93);
  static const _previewText = Color(0xFFAEAEB2);
  static const _equalsColor = Color(0xFF30D158);
  static const _hintColor = Color(0x508E8E93);
  static const _sheetColor = Color(0xFF1C1C1E);

  // ── Konstanta lain ──

  /// Tinggi tetap baris tombol `=`. Tanpa ini, di layar tinggi seperti tablet
  /// tombol `=` akan ikut memanjang dan terlihat tidak proporsional.
  static const _equalsRowHeight = 56.0;

  /// Dikompilasi sekali sebagai `static final` agar tidak dialokasikan ulang
  /// setiap kali tombol ditekan.
  static final _digitOrCloseOrPercent = RegExp(r'[0-9)%]');
  static final _compoundChars = RegExp(r'[+\-×÷()%]');

  // ── Siklus hidup ──

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final records = await _storage.load();

    // Widget bisa saja sudah dilepas sebelum pemuatan selesai —
    // memanggil `setState` setelah itu akan melempar exception.
    if (!mounted || records.isEmpty) return;

    setState(() {
      _history
        ..clear()
        ..addAll(records);
    });
  }

  // ── Getter bantu ──

  bool get _endsWithOperator {
    if (equation.isEmpty) return false;
    return CalculatorLogic.isInfixOperator(equation[equation.length - 1]);
  }

  bool get _isErrorResult =>
      result == 'Error' || result == 'Tidak terdefinisi';

  /// Jumlah kurung buka yang belum ditutup.
  int get _unclosedParens =>
      '('.allMatches(equation).length - ')'.allMatches(equation).length;

  /// Angka yang sedang diketik, yaitu deretan karakter setelah operator
  /// atau kurung terakhir. Dipakai untuk memvalidasi titik desimal
  /// dan angka nol di depan.
  String _getLastNumber() {
    // Telusuri mundur dari akhir ekspresi sampai bertemu operator
    // atau kurung, lalu ambil potongan setelahnya.
    var start = equation.length;
    for (int i = equation.length - 1; i >= 0; i--) {
      final ch = equation[i];
      if (CalculatorLogic.isInfixOperator(ch) || ch == '(' || ch == ')') break;
      start = i;
    }
    return equation.substring(start);
  }

  // ── Preview ──

  /// Menghitung ulang hasil sementara berdasarkan [equation] saat ini.
  ///
  /// Preview disembunyikan bila ekspresi belum bisa dihitung — misalnya
  /// masih berakhir dengan operator atau kurung buka.
  void _updatePreview() {
    if (_calculated ||
        _endsWithOperator ||
        equation == '0' ||
        equation.endsWith('(')) {
      _preview = '';
      return;
    }

    // Kurung yang belum ditutup ditutup sementara agar ekspresi bisa
    // dievaluasi, tanpa mengubah apa yang tampil di layar.
    final evalExpr = equation + (')' * _unclosedParens);

    _preview = CalculatorLogic.tryEvaluate(evalExpr) ?? '';

    // Tidak ada gunanya menampilkan preview yang sama persis dengan
    // ekspresi yang sedang diketik.
    if (_preview == equation) _preview = '';
  }

  // ── Penanganan input ──

  /// Titik masuk tunggal untuk semua penekanan tombol.
  void buttonPressed(String buttonText) {
    HapticFeedback.lightImpact();

    setState(() {
      switch (buttonText) {
        case 'AC':
          _handleClear();
          break;
        case '⌫':
          _handleBackspace();
          _updatePreview();
          break;
        case '=':
          _handleEquals();
          break;
        case '%':
          _handlePercent();
          _updatePreview();
          break;
        case '()':
          _handleParenthesis();
          _updatePreview();
          break;
        case '±':
          _handleSignToggle();
          _updatePreview();
          break;
        default:
          _handleInput(buttonText);
          _updatePreview();
      }
    });
  }

  void _handleClear() {
    equation = '0';
    result = '0';
    _preview = '';
    _calculated = false;
  }

  void _handleBackspace() {
    if (_calculated) {
      // Setelah `=`, backspace berfungsi seperti AC — hasil sebelumnya
      // tidak bisa diedit sebagian.
      _handleClear();
    } else if (equation.length > 1) {
      equation = equation.substring(0, equation.length - 1);
    } else {
      equation = '0';
    }
  }

  void _handleEquals() {
    // Ekspresi yang belum lengkap tidak dihitung.
    if (_endsWithOperator || equation == '0' || equation.endsWith('(')) return;

    // Menekan `=` berulang kali tidak menghitung ulang hasil.
    if (_calculated) return;

    equation += ')' * _unclosedParens;

    result = CalculatorLogic.tryEvaluate(equation) ?? 'Error';
    _calculated = true;
    _preview = '';

    if (!_isErrorResult) {
      _history.insert(0, CalcRecord(equation, result));
      if (_history.length > HistoryStorage.maxEntries) _history.removeLast();
      // Penyimpanan berjalan di latar belakang; kegagalannya sudah
      // ditangani di dalam HistoryStorage.
      _storage.save(_history);
    }
  }

  void _handlePercent() {
    if (equation == '0' ||
        _endsWithOperator ||
        equation.endsWith('%') ||
        equation.endsWith('(')) {
      return;
    }
    equation += '%';
  }

  /// Tombol `()` cerdas: menentukan sendiri kapan membuka dan menutup kurung.
  void _handleParenthesis() {
    if (_calculated) {
      equation = '(';
      result = '0';
      _calculated = false;
      return;
    }

    if (equation == '0') {
      equation = '(';
      return;
    }

    final lastChar = equation[equation.length - 1];
    final afterValue = _digitOrCloseOrPercent.hasMatch(lastChar);

    if (afterValue && _unclosedParens > 0) {
      // Ada kurung yang menunggu ditutup, dan posisinya valid untuk ditutup.
      equation += ')';
    } else if (afterValue) {
      // Kurung buka tepat setelah angka berarti perkalian implisit:
      // "5(" dibaca sebagai "5×(".
      equation += '×(';
    } else {
      equation += '(';
    }
  }

  /// Mengubah tanda positif/negatif.
  ///
  /// Hanya berlaku untuk bilangan tunggal — membalik tanda pada ekspresi
  /// gabungan seperti `"5+3"` bersifat ambigu, jadi sengaja diabaikan.
  void _handleSignToggle() {
    if (equation == '0') return;

    if (_calculated) {
      if (_isErrorResult || result == '0') return;
      equation = result.startsWith('-') ? result.substring(1) : '-$result';
      result = '0';
      _calculated = false;
      return;
    }

    final withoutMinus =
        equation.startsWith('-') ? equation.substring(1) : equation;

    if (!withoutMinus.contains(_compoundChars)) {
      equation =
          equation.startsWith('-') ? equation.substring(1) : '-$equation';
    }
  }

  void _handleInput(String buttonText) {
    if (CalculatorLogic.isInfixOperator(buttonText)) {
      _handleOperator(buttonText);
    } else if (buttonText == '.') {
      _handleDot();
    } else {
      _handleDigit(buttonText);
    }
  }

  void _handleOperator(String op) {
    if (_calculated) {
      if (_isErrorResult) {
        // Melanjutkan perhitungan dari hasil error tidak masuk akal,
        // jadi state di-reset.
        _handleClear();
        return;
      }
      // Merangkai perhitungan: hasil sebelumnya jadi operand pertama.
      equation = result;
      _calculated = false;
    }

    // Hanya minus yang boleh muncul di posisi ini, sebagai tanda negatif.
    if (equation.endsWith('(') && op != '-') return;
    if (equation == '0' && op != '-') return;

    if (_endsWithOperator) {
      // Operator baru menggantikan yang lama, bukan ditumpuk.
      equation = equation.substring(0, equation.length - 1) + op;
    } else {
      equation += op;
    }
  }

  void _handleDot() {
    if (_calculated) {
      equation = '0.';
      result = '0';
      _calculated = false;
      return;
    }

    // Titik desimal tidak valid setelah kurung tutup atau persen.
    if (equation.endsWith(')') || equation.endsWith('%')) return;

    // Satu angka hanya boleh punya satu titik desimal.
    if (_getLastNumber().contains('.')) return;

    if (_endsWithOperator || equation.endsWith('(')) {
      // Menyisipkan "0" agar tidak terbentuk ekspresi seperti "5+."
      equation += '0.';
    } else if (equation == '0') {
      equation = '0.';
    } else {
      equation += '.';
    }
  }

  void _handleDigit(String digit) {
    if (_calculated) {
      equation = (digit == '00') ? '0' : digit;
      result = '0';
      _calculated = false;
      return;
    }

    if (equation.endsWith(')') || equation.endsWith('%')) return;

    if (equation == '0') {
      equation = (digit == '00') ? '0' : digit;
      return;
    }

    final lastNumber = _getLastNumber();

    if (lastNumber.isEmpty) {
      equation += (digit == '00') ? '0' : digit;
    } else if (lastNumber == '0') {
      // Mencegah angka nol berlebih di depan: "05" menjadi "5".
      if (digit == '0' || digit == '00') return;
      equation = equation.substring(0, equation.length - 1) + digit;
    } else {
      equation += digit;
    }
  }

  // ── Aksi ──

  void _onSwipeDelete() {
    HapticFeedback.lightImpact();
    setState(() {
      _handleBackspace();
      _updatePreview();
    });
  }

  void _copyResult() {
    final text = _calculated ? result : (_preview.isEmpty ? null : _preview);
    if (text == null || text == '0') return;

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

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _sheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => HistorySheet(
        history: _history,
        formatEquation: Formatting.formatEquationDisplay,
        formatNumber: Formatting.addThousandsSeparator,
        onTap: (record) {
          setState(() {
            // Hasil lama dipakai sebagai titik awal perhitungan baru.
            equation = record.result;
            result = '0';
            _preview = '';
            _calculated = false;
          });
          Navigator.pop(sheetContext);
        },
        onClear: () {
          setState(_history.clear);
          _storage.clear();
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  // ── Tampilan ──

  /// Angka yang tampil di baris hasil: hasil akhir bila sudah dihitung,
  /// preview bila sedang mengetik, atau hasil terakhir sebagai cadangan.
  String get _displayResult {
    if (_calculated) return result;
    if (_preview.isNotEmpty) return _preview;
    return result;
  }

  Widget _buildButton(CalcButton config) => CalculatorButtonWidget(
        config: config,
        defaultColor: _numberColor,
        defaultTextColor: _textColor,
        onPressed: buttonPressed,
      );

  /// Satu baris tombol yang membagi ruang vertikal yang tersisa secara merata.
  Widget _buildButtonRow(List<CalcButton> buttons) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.map(_buildButton).toList(),
      ),
    );
  }

  Widget _buildDisplay(BuildContext context) {
    final showPreview = !_calculated && _preview.isNotEmpty;

    // Ukuran font mengikuti lebar layar agar proporsional di berbagai
    // perangkat. Ekspresi mengecil setelah dihitung karena fokus berpindah
    // ke hasil.
    final screenWidth = MediaQuery.of(context).size.width;
    final eqSize = screenWidth * (_calculated ? 0.06 : 0.095);
    final resSize =
        screenWidth * (_calculated ? 0.12 : (showPreview ? 0.07 : 0.065));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        // Geser ke kanan dengan kecepatan cukup berarti hapus satu karakter.
        if ((details.primaryVelocity ?? 0) > 100) _onSwipeDelete();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Semantics(
                  label: 'Riwayat',
                  button: true,
                  child: GestureDetector(
                    onTap: _showHistory,
                    child: const Icon(
                      Icons.history,
                      color: _secondaryText,
                      size: 22,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'swipe → hapus',
                  style: TextStyle(fontSize: 10, color: _hintColor),
                ),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Baris ekspresi. `reverse: true` menjaga ujung kanan
                  // tetap terlihat saat ekspresi lebih lebar dari layar.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: eqSize.clamp(18.0, 48.0),
                        fontWeight: FontWeight.w300,
                        color: _calculated ? _secondaryText : _textColor,
                        letterSpacing: 1.2,
                      ),
                      child: Text(
                        Formatting.formatEquationDisplay(equation),
                        key: const Key('equation'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Baris hasil. Tekan lama untuk menyalin ke clipboard.
                  GestureDetector(
                    onLongPress: _copyResult,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: resSize.clamp(20.0, 56.0),
                          fontWeight:
                              _calculated ? FontWeight.w400 : FontWeight.w300,
                          color: _calculated
                              ? _textColor
                              : (showPreview ? _previewText : _secondaryText),
                          letterSpacing: 0.8,
                        ),
                        child: Text(
                          Formatting.addThousandsSeparator(_displayResult),
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
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
      child: Column(
        children: [
          _buildButtonRow(const [
            CalcButton('()', color: _functionColor, semanticLabel: 'Kurung'),
            CalcButton('⌫', color: _functionColor, semanticLabel: 'Hapus'),
            CalcButton('%', color: _functionColor, semanticLabel: 'Persen'),
            CalcButton('AC', color: _accentColor, semanticLabel: 'Hapus semua'),
          ]),
          _buildButtonRow(const [
            CalcButton('7'),
            CalcButton('8'),
            CalcButton('9'),
            CalcButton('÷', color: _operatorColor, semanticLabel: 'Bagi'),
          ]),
          _buildButtonRow(const [
            CalcButton('4'),
            CalcButton('5'),
            CalcButton('6'),
            CalcButton('×', color: _operatorColor, semanticLabel: 'Kali'),
          ]),
          _buildButtonRow(const [
            CalcButton('1'),
            CalcButton('2'),
            CalcButton('3'),
            CalcButton('-', color: _operatorColor, semanticLabel: 'Kurang'),
          ]),
          _buildButtonRow(const [
            CalcButton('±', semanticLabel: 'Plus minus'),
            CalcButton('0'),
            CalcButton('.', semanticLabel: 'Titik desimal'),
            CalcButton('+', color: _operatorColor, semanticLabel: 'Tambah'),
          ]),

          // Tinggi tetap, bukan `Expanded`, agar tombol `=` tidak
          // memanjang berlebihan di layar yang tinggi.
          SizedBox(
            height: _equalsRowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildButton(
                  const CalcButton(
                    '=',
                    color: _equalsColor,
                    semanticLabel: 'Sama dengan',
                  ),
                ),
              ],
            ),
          ),
        ],
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
            // Area tampilan mendapat 2 bagian, keypad 3 bagian.
            Expanded(flex: 2, child: _buildDisplay(context)),

            // Garis pemisah dengan gradasi yang memudar di kedua ujungnya.
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

            Expanded(flex: 3, child: _buildKeypad()),
          ],
        ),
      ),
    );
  }
}
