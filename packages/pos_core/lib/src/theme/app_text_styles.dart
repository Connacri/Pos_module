import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle displaySmall(Color color) => TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.1,
      );

  static TextStyle headlineMedium(Color color) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle titleLarge(Color color) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle titleMedium(Color color) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle bodyLarge(Color color) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle labelMedium(Color color) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle money(Color color) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle appBarTitle(Color color) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      );
}
