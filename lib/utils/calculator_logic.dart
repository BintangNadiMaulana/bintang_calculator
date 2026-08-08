import 'package:math_expressions/math_expressions.dart';

/// Kumpulan fungsi murni untuk mengevaluasi dan memformat hasil perhitungan.
///
/// Semua method bersifat `static` karena class ini tidak menyimpan state —
/// ia hanya mengubah input menjadi output.
class CalculatorLogic {
  /// Operator biner yang dikenali kalkulator (operator yang butuh dua operand).
  static const infixOperators = {'+', '-', '×', '÷'};

  /// Menghapus angka nol berlebih di akhir bilangan desimal.
  static final _trailingZeros = RegExp(r'0+$');

  /// Mengecek apakah [s] adalah operator biner.
  static bool isInfixOperator(String s) => infixOperators.contains(s);

  /// Merapikan hasil perhitungan agar enak dibaca.
  ///
  /// Aturan yang diterapkan:
  /// * Bilangan sangat besar (>= 10^12) atau sangat kecil (< 10^-8)
  ///   ditampilkan dalam notasi ilmiah agar tidak memenuhi layar.
  /// * Bilangan bulat ditampilkan tanpa `.0` di belakang.
  /// * Bilangan desimal dipangkas angka nol di akhirnya (`2.50` jadi `2.5`).
  static String formatResult(String raw) {
    final val = double.tryParse(raw);
    if (val == null) return raw;

    if (val.abs() >= 1e12 || (val != 0 && val.abs() < 1e-8)) {
      return val.toStringAsPrecision(6);
    }

    // `1e15` adalah batas aman sebelum `double` kehilangan presisi
    // saat dikonversi ke integer.
    if (val == val.toInt().toDouble() && val.abs() < 1e15) {
      return val.toInt().toString();
    }

    var formatted = val.toStringAsFixed(10).replaceAll(_trailingZeros, '');
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  /// Mengevaluasi ekspresi [eq] dan mengembalikan hasilnya sebagai `String`.
  ///
  /// Mengembalikan `null` jika ekspresi tidak bisa di-parse — misalnya karena
  /// masih setengah jadi saat pengguna mengetik. Pemanggil bertanggung jawab
  /// memutuskan apa yang ditampilkan untuk kasus tersebut.
  ///
  /// Kasus khusus yang ditangani:
  /// * Pembagian dengan nol menghasilkan `"Tidak terdefinisi"`.
  /// * Operasi tak valid seperti `0÷0` menghasilkan `"Error"`.
  static String? tryEvaluate(String eq) {
    // Simbol tampilan diubah ke sintaks yang dimengerti parser.
    final expr = eq
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('%', '/100');

    try {
      final parsed = Parser().parse(expr);
      final evaluated = parsed.evaluate(EvaluationType.REAL, ContextModel());

      // Parser mengembalikan `dynamic`; pastikan hasilnya benar-benar numerik
      // sebelum diperiksa lebih lanjut.
      if (evaluated is! num) return null;
      final value = evaluated.toDouble();

      if (value.isInfinite) return 'Tidak terdefinisi';
      if (value.isNaN) return 'Error';
      return formatResult('$value');
    } catch (_) {
      // Ekspresi belum lengkap atau tidak valid — bukan kondisi fatal.
      return null;
    }
  }
}
