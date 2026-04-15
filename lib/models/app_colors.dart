import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary Gradient
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color accent = Color(0xFF00CEC9);

  // Backgrounds
  static const Color background = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF12121C);
  static const Color card = Color(0xFF1A1A28);
  static const Color cardHover = Color(0xFF222234);
  static const Color glass = Color(0x1AFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xFF8B8BA3);
  static const Color textHint = Color(0xFF5C5C72);

  // Status
  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color info = Color(0xFF74B9FF);

  // Input Fields
  static const Color inputBackground = Color(0xFF15151F);
  static const Color inputBorder = Color(0xFF2A2A3C);

  // Buttons
  static const Color buttonPrimary = Color(0xFF6C5CE7);
  static const Color buttonSecondary = Color(0xFF2A2A3C);

  // Divider and Border
  static const Color divider = Color(0xFF1F1F30);
  static const Color border = Color(0xFF2A2A3C);

  // Misc
  static const Color white = Color(0xFFF5F5FA);
  static const Color black = Color(0xFF000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A28), Color(0xFF151522)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
