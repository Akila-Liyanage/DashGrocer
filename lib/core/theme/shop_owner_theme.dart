import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour tokens taken from the Shop Owner Figma file.
///
/// Named ShopColors (not AppColors) so they never clash with the team's
/// `AppColors` in `app_colors.dart`.
class ShopColors {
  ShopColors._();

  static const background = Color(0xFFF4FBF6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFEEF5F0);
  static const surfaceMid = Color(0xFFE9F0EB);
  static const surfaceHigh = Color(0xFFE3EAE5);
  static const surfaceHighest = Color(0xFFDDE4DF);
  static const inputFill = Color(0xFFEAF7EA);

  static const textPrimary = Color(0xFF161D1A);
  static const textSecondary = Color(0xFF40493D);

  static const primary = Color(0xFF0D631B);
  static const primaryButton = Color(0xFF2E7D32);
  static const secondary = Color(0xFF2A6B2C);
  static const greenContainer = Color(0xFFACF4A4);
  static const onGreenContainer = Color(0xFF0C5216);

  /// Amber, used only for the "LOW STOCK" badge.
  static const warningContainer = Color(0xFFFFE8B3);
  static const onWarningContainer = Color(0xFF5C4300);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
}

/// Text styles taken from the Figma file (Inter).
///
/// They are built with GoogleFonts so the real 600 and 700 weights are loaded
/// instead of a faked bold.
class ShopText {
  ShopText._();

  static TextStyle _inter(
    double size,
    double lineHeight,
    FontWeight weight,
    Color color, {
    double spacing = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
    );
  }

  /// "OVERVIEW" style section captions.
  static final TextStyle caps =
      _inter(12, 16, FontWeight.w600, ShopColors.textSecondary, spacing: 0.6);

  /// Small labels: chips, badges, nav items.
  static final TextStyle label =
      _inter(11, 14, FontWeight.w600, ShopColors.textSecondary, spacing: 0.22);

  static final TextStyle body =
      _inter(12, 16, FontWeight.w400, ShopColors.textSecondary);

  static final TextStyle bodyStrong =
      _inter(12, 16, FontWeight.w600, ShopColors.textPrimary);

  /// Text inside buttons.
  static final TextStyle button =
      _inter(13, 16, FontWeight.w600, Colors.white, spacing: 0.1);

  /// Text typed into fields, and longer readable text.
  static final TextStyle input =
      _inter(14, 20, FontWeight.w400, ShopColors.textPrimary);

  static final TextStyle subtitle =
      _inter(14, 20, FontWeight.w600, ShopColors.textPrimary);

  static final TextStyle title =
      _inter(17, 22, FontWeight.w600, ShopColors.textPrimary);

  static final TextStyle heading =
      _inter(20, 26, FontWeight.w700, ShopColors.textPrimary);

  static final TextStyle metric =
      _inter(24, 30, FontWeight.w700, ShopColors.textPrimary, spacing: -0.36);
}

class ShopDecor {
  ShopDecor._();

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// White rounded card with the soft shadow used across the app.
  static BoxDecoration card({double radius = 12}) {
    return BoxDecoration(
      color: ShopColors.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: cardShadow,
    );
  }

  /// Pale rounded block used inside cards.
  static BoxDecoration tile({Color color = ShopColors.surfaceLow}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    );
  }

  /// Solid green button (or another colour for special cases).
  static ButtonStyle primaryButton({
    Color color = ShopColors.primary,
    double radius = 8,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      disabledBackgroundColor: ShopColors.surfaceHigh,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      textStyle: ShopText.button,
    );
  }

  /// Pale button for secondary actions such as "Details".
  static ButtonStyle tonalButton({
    Color foreground = ShopColors.textPrimary,
    double radius = 8,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: ShopColors.surfaceMid,
      foregroundColor: foreground,
      disabledBackgroundColor: ShopColors.surfaceHigh,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      textStyle: ShopText.button,
    );
  }

  /// Filled text field with no outline until it is focused.
  static InputDecoration input({
    String? hint,
    String? prefixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    Color fill = ShopColors.surface,
  }) {
    final plainBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: ShopText.input.copyWith(color: ShopColors.textSecondary),
      prefixText: prefixText,
      prefixStyle: ShopText.subtitle.copyWith(color: ShopColors.primary),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: fill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: plainBorder,
      enabledBorder: plainBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ShopColors.primary, width: 1.5),
      ),
    );
  }
}

/// The look of the shop owner side (colours and font from its Figma file).
///
/// The rest of the app uses the team theme in `app_theme.dart`. The shop
/// owner screens are wrapped in this theme instead, so both designs stay
/// exactly as they were prototyped.
class ShopTheme {
  ShopTheme._();

  /// Built once and reused.
  static final ThemeData data = _build();

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: ShopColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: ShopColors.primary,
      onPrimary: Colors.white,
      secondary: ShopColors.secondary,
      error: ShopColors.error,
      surface: ShopColors.surface,
      onSurface: ShopColors.textPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ShopColors.background,
    );

    return base.copyWith(
      // Only the font family name is taken from google_fonts here, so this
      // works with every google_fonts version.
      textTheme: base.textTheme.apply(
        fontFamily: GoogleFonts.inter().fontFamily,
        bodyColor: ShopColors.textPrimary,
        displayColor: ShopColors.textPrimary,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Route for a shop owner screen opened on top of the tabs.
///
/// A new route does not inherit the theme of the screen that opened it, so
/// this wraps the new screen in [ShopTheme] again. Always push shop owner
/// screens with this instead of a plain MaterialPageRoute.
MaterialPageRoute<T> shopRoute<T>(WidgetBuilder builder) {
  return MaterialPageRoute<T>(
    builder: (context) => Theme(
      data: ShopTheme.data,
      child: Builder(builder: builder),
    ),
  );
}
