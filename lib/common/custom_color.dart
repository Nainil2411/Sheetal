import 'package:flutter/material.dart';

class CustomColors {
  static const Color primary1 = Color(0xFF6200EE);
  static const Color appbar = Color(0xFF1A2639);
  static const Color basic = Color(0xFFFDF8FE);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color accent = Color(0xFFFFC107);
  static const Color error = Color(0xFFB00020);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
  static const Color primary = Color(0xFFA3A9F3);
  static const Color secondary1 = Color(0xFFBC8EFD);
  static const Color header = Color(0xFFB3E5FC);
  static const Color green1 = Color(0xFF02AF05);
  static const Color blue1 = Color(0xFF0072FF);
  static const Color floral =Color(0xFFB4E33D);
  static const Color grey300 = Color(0xE0E0E0FF);
  static const Color error1 = Color(0xFFFF5252);

  static Color fromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
