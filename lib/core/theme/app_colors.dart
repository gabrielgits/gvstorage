import 'package:flutter/material.dart';

/// WPShop color scheme extracted from the website
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF3498DB);
  static const Color primaryDark = Color(0xFF2980B9);
  static const Color primaryLight = Color(0xFF5DADE2);

  // Secondary colors
  static const Color secondary = Color(0xFF2ECC71);
  static const Color secondaryDark = Color(0xFF27AE60);

  // Accent colors
  static const Color accent = Color(0xFFF8484A);
  static const Color accentLight = Color(0xFFFF6B6B);

  // Neutral colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceVariant = Color(0xFFEBEBEB);
  static const Color border = Color(0xFFEBEBEB);

  // Text colors
  static const Color textPrimary = Color(0xFF434343);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Footer colors
  static const Color footerBackground = Color(0xFF3D3D3D);
  static const Color footerText = Color(0xFFCCCCCC);

  // Status colors
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Sale/Discount colors
  static const Color saleBackground = Color(0xFFF8484A);
  static const Color saleForeground = Color(0xFFFFFFFF);
  static const Color originalPrice = Color(0xFF999999);

  // Card colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A000000);

  // Button colors
  static const Color buttonPrimary = Color(0xFF3498DB);
  static const Color buttonSecondary = Color(0xFF95A5A6);
  static const Color buttonDisabled = Color(0xFFBDC3C7);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
