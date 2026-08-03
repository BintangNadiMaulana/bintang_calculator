import 'package:flutter/material.dart';

class CalcButton {
  final String text;
  final Color? color;
  final Color? textColor;
  final int flex;
  final String? semanticLabel;
  const CalcButton(this.text,
      {this.color, this.textColor, this.flex = 1, this.semanticLabel});
}
