import 'package:flutter/material.dart';
import 'package:calculator_bintang/models/calc_record.dart';

class HistorySheet extends StatelessWidget {
  final List<CalcRecord> history;
  final String Function(String) formatEquation;
  final String Function(String) formatNumber;
  final void Function(CalcRecord) onTap;
  final VoidCallback onClear;

  const HistorySheet({
    Key? key,
    required this.history,
    required this.formatEquation,
    required this.formatNumber,
    required this.onTap,
    required this.onClear,
  }) : super(key: key);

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
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF453A)),
                child: const Text('Hapus Riwayat'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
