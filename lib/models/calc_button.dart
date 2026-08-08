import 'package:flutter/material.dart';

/// Konfigurasi satu tombol kalkulator.
///
/// Class ini bersifat immutable (semua field `final`) sehingga bisa dibuat
/// dengan `const`, yang membuat Flutter bisa melakukan optimisasi rebuild.
class CalcButton {
  /// Teks yang ditampilkan pada tombol sekaligus nilai yang dikirim
  /// ke handler saat tombol ditekan.
  final String text;

  /// Warna latar tombol. Jika `null`, dipakai warna default dari parent.
  final Color? color;

  /// Warna teks tombol. Jika `null`, dipakai warna default dari parent.
  final Color? textColor;

  /// Bobot lebar tombol dalam sebuah baris (dipakai oleh `Expanded`).
  final int flex;

  /// Label yang dibacakan screen reader. Berguna untuk simbol seperti
  /// `×` atau `÷` yang tidak terbaca jelas jika dibaca apa adanya.
  final String? semanticLabel;

  const CalcButton(
    this.text, {
    this.color,
    this.textColor,
    this.flex = 1,
    this.semanticLabel,
  });
}
