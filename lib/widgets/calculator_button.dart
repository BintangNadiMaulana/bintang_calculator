import 'package:flutter/material.dart';
import 'package:calculator_bintang/models/calc_button.dart';

class CalculatorButtonWidget extends StatelessWidget {
  final CalcButton config;
  final Color defaultColor;
  final Color defaultTextColor;
  final void Function(String) onPressed;

  const CalculatorButtonWidget({
    Key? key,
    required this.config,
    required this.defaultColor,
    required this.defaultTextColor,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: config.flex,
      child: Padding(
        padding: const EdgeInsets.all(3.5),
        child: Material(
          color: config.color ?? defaultColor,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shadowColor: Colors.black54,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            onTap: () => onPressed(config.text),
            child: Center(
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
    );
  }
}
