import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF90CAF9);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFF003258);

  // Secondary palette
  static const Color secondaryLight = Color(0xFF26A69A);
  static const Color secondaryDark = Color(0xFF80CBC4);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFF003731);

  // Tertiary palette
  static const Color tertiaryLight = Color(0xFF7E57C2);
  static const Color tertiaryDark = Color(0xFFD1C4E9);

  // Semantic colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);

  // Surfaces
  static const Color surfaceLight = Color(0xFFFEFEFE);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceVariantLight = Color(0xFFF5F5F5);
  static const Color surfaceVariantDark = Color(0xFF1E1E1E);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF0A0A0A);

  // Status
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'active':
        return success;
      case 'pending':
      case 'processing':
        return warning;
      case 'cancelled':
      case 'failed':
      case 'returned':
        return error;
      default:
        return info;
    }
  }
}