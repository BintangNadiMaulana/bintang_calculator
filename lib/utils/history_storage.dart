import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:calculator_bintang/models/calc_record.dart';

/// Menyimpan dan memuat riwayat perhitungan ke penyimpanan lokal perangkat.
///
/// Seluruh operasi dibungkus `try-catch`: riwayat adalah fitur pelengkap,
/// jadi kegagalan penyimpanan tidak boleh membuat kalkulator berhenti bekerja.
/// Pada lingkungan tanpa plugin (misalnya widget test), method di sini
/// akan mengembalikan daftar kosong alih-alih melempar exception.
class HistoryStorage {
  /// Kunci penyimpanan di `SharedPreferences`.
  static const _key = 'calc_history';

  /// Jumlah maksimum entri yang disimpan, agar penyimpanan tidak membengkak.
  static const maxEntries = 50;

  const HistoryStorage();

  /// Memuat riwayat yang tersimpan.
  ///
  /// Mengembalikan daftar kosong bila belum ada data, penyimpanan tidak
  /// tersedia, atau data yang tersimpan rusak.
  Future<List<CalcRecord>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key);
      if (raw == null) return const [];

      final records = <CalcRecord>[];
      for (final item in raw) {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          records.add(CalcRecord.fromJson(decoded));
        }
      }
      return records;
    } catch (_) {
      return const [];
    }
  }

  /// Menyimpan [records] ke penyimpanan lokal.
  ///
  /// Mengembalikan `true` bila berhasil. Kegagalan sengaja tidak dilempar
  /// agar pemanggil tidak perlu menanganinya.
  Future<bool> save(List<CalcRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = records.map((r) => jsonEncode(r.toJson())).toList();
      return await prefs.setStringList(_key, raw);
    } catch (_) {
      return false;
    }
  }

  /// Menghapus seluruh riwayat dari penyimpanan lokal.
  Future<bool> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_key);
    } catch (_) {
      return false;
    }
  }
}
