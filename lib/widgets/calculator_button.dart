import 'package:flutter/material.dart';

import 'package:calculator_bintang/models/calc_button.dart';

/// Satu tombol kalkulator yang bisa dipakai ulang.
///
/// Widget ini sengaja dibuat "bodoh" — ia tidak tahu apa arti tombolnya,
/// hanya meneruskan [CalcButton.text] ke [onPressed] saat ditekan.
/// Seluruh logika kalkulator tetap berada di layar utama.
class CalculatorButtonWidget extends StatelessWidget {
  /// Konfigurasi tampilan dan nilai tombol.
  final CalcButton config;

  /// Warna latar yang dipakai bila [CalcButton.color] bernilai `null`.
  final Color defaultColor;

  /// Warna teks yang dipakai bila [CalcButton.textColor] bernilai `null`.
  final Color defaultTextColor;

  /// Dipanggil dengan [CalcButton.text] saat tombol ditekan.
  final void Function(String) onPressed;

  const CalculatorButtonWidget({
    super.key,
    required this.config,
    required this.defaultColor,
    required this.defaultTextColor,
    required this.onPressed,
  });

  static final _radius = BorderRadius.circular(18);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: config.flex,
      child: Padding(
        padding: const EdgeInsets.all(3.5),
        child: Semantics(
          // Screen reader membaca label ini, bukan simbol mentahnya —
          // sehingga "×" terbaca "Kali", bukan karakter Unicode.
          label: config.semanticLabel ?? config.text,
          button: true,
          child: Material(
            color: config.color ?? defaultColor,
            borderRadius: _radius,
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            shadowColor: Colors.black54,
            child: InkWell(
              borderRadius: _radius,
              splashColor: Colors.white24,
              highlightColor: Colors.white10,
              onTap: () => onPressed(config.text),
              child: Center(
                // Teks dikecualikan dari semantics agar screen reader tidak
                // membacakan label dan simbolnya dua kali.
                child: ExcludeSemantics(
                  child: Text(
                    config.text,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: config.textColor ?? defaultTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
