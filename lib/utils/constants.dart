import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF007BFF);
  static const Color primaryDark = Color(0xFF0056B3);
  static const Color accentGreen = Color(0xFF28A745);
  static const Color accentDarkGreen = Color(0xFF218838);
  static const Color textDark = Color(0xFF343A40);
  static const Color textMedium = Color(0xFF495057);
  static const Color textMuted = Color(0xFF6C757D);
  static const Color background = Color(0xFFE9ECEF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFDEE2E6);
  static const Color danger = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );
  static const TextStyle body = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w400,
    color: AppColors.textMedium,
  );
  static const TextStyle label = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
}