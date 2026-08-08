/// Satu entri riwayat perhitungan.
///
/// Menyimpan ekspresi yang dihitung beserta hasilnya, keduanya dalam bentuk
/// `String` mentah (belum diformat untuk tampilan).
class CalcRecord {
  /// Ekspresi mentah, contoh: `"5+3×2"`.
  final String equation;

  /// Hasil perhitungan, contoh: `"11"`.
  final String result;

  const CalcRecord(this.equation, this.result);

  /// Mengubah record menjadi `Map` agar bisa disimpan sebagai JSON.
  Map<String, dynamic> toJson() => {'eq': equation, 'res': result};

  /// Membuat record dari `Map` hasil decode JSON.
  ///
  /// Menggunakan `?? ''` sebagai pengaman jika data tersimpan rusak
  /// atau berasal dari versi aplikasi yang lebih lama.
  factory CalcRecord.fromJson(Map<String, dynamic> json) => CalcRecord(
        json['eq'] as String? ?? '',
        json['res'] as String? ?? '',
      );
}
