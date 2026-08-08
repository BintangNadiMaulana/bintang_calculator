import 'package:calculator_bintang/utils/calculator_logic.dart';

/// Fungsi-fungsi untuk mempercantik tampilan angka dan ekspresi di layar.
///
/// Formatting hanya memengaruhi tampilan — nilai yang disimpan di state
/// tetap dalam bentuk mentah tanpa spasi maupun pemisah ribuan.
class Formatting {
  /// Menyisipkan spasi di sekitar operator biner agar ekspresi lebih terbaca.
  ///
  /// Contoh: `"5+3×2"` menjadi `"5 + 3 × 2"`.
  ///
  /// Tanda minus diperlakukan khusus: minus unary (tanda negatif) tidak
  /// diberi spasi, sehingga `"-5"` tetap `"-5"` dan bukan `"- 5"`.
  static String formatEquationDisplay(String eq) {
    final buf = StringBuffer();

    for (int i = 0; i < eq.length; i++) {
      final ch = eq[i];

      if (ch == '+' || ch == '×' || ch == '÷') {
        buf.write(' $ch ');
      } else if (ch == '-') {
        // Minus dianggap unary bila berada di awal ekspresi, tepat setelah
        // kurung buka, atau tepat setelah operator lain.
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

  /// Menambahkan pemisah ribuan pada [value].
  ///
  /// Contoh: `"998001"` menjadi `"998,001"`.
  ///
  /// Dikembalikan apa adanya bila [value] berupa pesan error, angka nol,
  /// atau sudah dalam notasi ilmiah — pada kasus tersebut pemisah ribuan
  /// justru membuat tampilan salah.
  static String addThousandsSeparator(String value) {
    if (value == 'Error' || value == 'Tidak terdefinisi' || value == '0') {
      return value;
    }
    if (value.contains('e') || value.contains('E')) return value;

    final negative = value.startsWith('-');
    final body = negative ? value.substring(1) : value;

    // Pisahkan bagian bulat dari bagian desimal; hanya bagian bulat
    // yang diberi pemisah ribuan.
    final dotIndex = body.indexOf('.');
    final intPart = dotIndex == -1 ? body : body.substring(0, dotIndex);
    final decPart = dotIndex == -1 ? null : body.substring(dotIndex + 1);

    final buf = StringBuffer();
    final len = intPart.length;
    for (int i = 0; i < len; i++) {
      // Sisipkan koma setiap kelipatan tiga digit dihitung dari kanan.
      if (i > 0 && (len - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }

    final withSeparator = decPart == null ? buf.toString() : '$buf.$decPart';
    return negative ? '-$withSeparator' : withSeparator;
  }
}
