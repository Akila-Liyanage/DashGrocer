import 'package:flutter/material.dart';

class AppColors {
  // Fresh Botanical Brand Palette (Figma Grocery Design)
  static const Color brandGreen = Color(0xFF6CC51D); // Figma vibrant grocery green
  static const Color brandGreenDark = Color(0xFF539C14);
  static const Color brandGreenSoft = Color(0xFFF1FCE8);
  static const Color brandGreenMuted = Color(0xFFE5F8D5);
  static const Color brandRed = Color(0xFFEF4444);
  static const Color brandRedSoft = Color(0xFFFEE2E2);
  static const Color brandPeach = Color(0xFFFFECE5);
  static const Color brandOrange = Color(0xFFFF8B38);
  static const Color brandCardBg = Colors.white;
  static const Color brandPillBg = Color(0xFFF4F5F7);

  // Fresh Botanical Brand Palette
  static const Color primary = Color(0xFF6CC51D); // Emerald to Figma green
  static const Color primaryLight = Color(0xFF82D834);
  static const Color primaryDark = Color(0xFF539C14);
  static const Color primarySoft = Color(0xFFF1FCE8);
  static const Color primaryMuted = Color(0xFFE5F8D5);

  // Modern Neutral Canvas
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF1F5F9); // Slate 100
  static const Color surfaceElevated = Colors.white;

  // Typography
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Subtle Borders
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate 100
  static const Color borderFocused = Color(0xFF059669);

  // Functional Accents
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentAmberSoft = Color(0xFFFEF3C7);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentBlueSoft = Color(0xFFEFF6FF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);

  // Roles
  static const Color roleCustomer = Color(0xFF059669);
  static const Color roleCustomerSoft = Color(0xFFD1FAE5);
  static const Color roleShopOwner = Color(0xFFD97706);
  static const Color roleShopOwnerSoft = Color(0xFFFEF3C7);
  static const Color roleAdmin = Color(0xFF6366F1);
  static const Color roleAdminSoft = Color(0xFFEEF2FF);

  // Card Shadow
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get cardShadowSubtle => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}
