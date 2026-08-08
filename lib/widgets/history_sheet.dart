import 'package:flutter/material.dart';

import 'package:calculator_bintang/models/calc_record.dart';

/// Panel riwayat perhitungan yang muncul dari bawah layar.
///
/// Formatting diterima lewat parameter [formatEquation] dan [formatNumber]
/// agar widget ini tidak bergantung langsung pada util formatting —
/// membuatnya lebih mudah diuji secara terpisah.
class HistorySheet extends StatelessWidget {
  /// Daftar riwayat, entri terbaru berada di indeks 0.
  final List<CalcRecord> history;

  /// Memformat ekspresi untuk ditampilkan (menyisipkan spasi antar operator).
  final String Function(String) formatEquation;

  /// Memformat angka hasil (menambahkan pemisah ribuan).
  final String Function(String) formatNumber;

  /// Dipanggil saat salah satu entri riwayat ditekan.
  final void Function(CalcRecord) onTap;

  /// Dipanggil saat tombol "Hapus Riwayat" ditekan.
  final VoidCallback onClear;

  const HistorySheet({
    super.key,
    required this.history,
    required this.formatEquation,
    required this.formatNumber,
    required this.onTap,
    required this.onClear,
  });

  static const _mutedColor = Color(0xFF8E8E93);
  static const _dangerColor = Color(0xFFFF453A);

  @override
  Widget build(BuildContext context) {
    return Column(
      // `min` agar panel setinggi isinya saja, tidak memenuhi layar.
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),

        // Batang kecil penanda bahwa panel bisa ditarik.
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: _mutedColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          'Riwayat',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),

        // `Flexible` + `shrinkWrap` membuat daftar ikut menyusut bila
        // entrinya sedikit, tapi tetap bisa di-scroll bila banyak.
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: history.length,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemBuilder: (_, i) {
              final record = history[i];
              return InkWell(
                onTap: () => onTap(record),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatEquation(record.equation),
                        style: const TextStyle(
                          fontSize: 16,
                          color: _mutedColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '= ${formatNumber(record.result)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // `SafeArea` menjaga tombol tidak tertutup gesture bar perangkat.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(foregroundColor: _dangerColor),
                child: const Text('Hapus Riwayat'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
