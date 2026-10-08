import 'package:flutter/services.dart';

/// Formatter and validator for Sri Lankan phone numbers:
/// Ensures format "+94" followed by exactly 9 digits (e.g. 77 123 4567).
class SriLankaPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Handle pasting numbers with +94 or 94 prefix
    if (text.startsWith('94') && text.length >= 11) {
      text = text.substring(2);
    }

    // Automatically strip leading 0 if entered
    if (text.startsWith('0')) {
      text = text.replaceFirst(RegExp(r'^0+'), '');
    }

    // Limit to exactly 9 digits
    if (text.length > 9) {
      text = text.substring(0, 9);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class SriLankaPhoneUtils {
  /// Extracts the 9 digits of a Sri Lankan phone number, stripping country code or leading 0.
  static String extractLk9Digits(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('94') && digits.length >= 11) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0') && digits.length >= 10) {
      digits = digits.substring(1);
    }
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }
    return digits;
  }

  /// Formats 9 digits into standard Sri Lankan "+94 77 123 4567"
  static String formatWithCountryCode(String input) {
    final digits = extractLk9Digits(input);
    if (digits.length == 9) {
      return '+94 ${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
    }
    if (digits.isNotEmpty) {
      return '+94 $digits';
    }
    return '';
  }

  /// Validates that input is exactly 9 digits after +94 and is a valid LK number
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter phone number';
    }
    final trimmed = value.trim();
    if (trimmed.startsWith('0')) {
      return 'Do not include leading 0 after +94';
    }
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9) {
      return 'Enter exactly 9 digits after +94 (e.g. 77 123 4567)';
    }
    if (digits.length > 9) {
      return 'Maximum 9 digits allowed after +94';
    }
    if (!RegExp(r'^[1-9][0-9]{8}$').hasMatch(digits)) {
      return 'Enter valid 9-digit LK number (e.g. 77 123 4567)';
    }
    return null;
  }
}
