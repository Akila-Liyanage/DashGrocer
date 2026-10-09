import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dashgrocer/core/phone_validator.dart';
import 'package:dashgrocer/views/auth/signup_screen.dart';
import 'package:dashgrocer/views/auth/register_form.dart';
import 'package:dashgrocer/views/customer/profile_tab.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Sri Lanka Phone Number Validation Unit Tests', () {
    testWidgets('Customer profile phone field accepts only 10 digits', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfileTab()));
      await tester.pumpAndSettle();

      final phoneField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.hintText == 'Phone Number',
      );
      await tester.ensureVisible(phoneField);
      await tester.pumpAndSettle();
      await tester.enterText(phoneField, '077ab123456789');
      await tester.pump();

      expect(tester.widget<TextField>(phoneField).controller!.text, '0771234567');
    });

    test('1. Empty phone number returns required error', () {
      expect(SriLankaPhoneUtils.validate(null), 'Enter phone number');
      expect(SriLankaPhoneUtils.validate(''), 'Enter phone number');
      expect(SriLankaPhoneUtils.validate('   '), 'Enter phone number');
    });

    test('2. Phone number with leading 0 after +94 returns error', () {
      expect(
        SriLankaPhoneUtils.validate('0771234567'),
        'Do not include leading 0 after +94',
      );
    });

    test('3. Phone number with fewer than 9 digits returns error', () {
      expect(
        SriLankaPhoneUtils.validate('77123'),
        'Enter exactly 9 digits after +94 (e.g. 77 123 4567)',
      );
    });

    test('4. Valid 9-digit Sri Lankan numbers pass validation', () {
      expect(SriLankaPhoneUtils.validate('771234567'), isNull);
      expect(SriLankaPhoneUtils.validate('719876543'), isNull);
      expect(SriLankaPhoneUtils.validate('701122334'), isNull);
      expect(SriLankaPhoneUtils.validate('112345678'), isNull); // Colombo landline
    });

    test('5. Phone number formatting adds country code correctly', () {
      expect(
        SriLankaPhoneUtils.formatWithCountryCode('771234567'),
        '+94 77 123 4567',
      );
      expect(
        SriLankaPhoneUtils.formatWithCountryCode('0771234567'),
        '+94 77 123 4567',
      );
      expect(
        SriLankaPhoneUtils.formatWithCountryCode('+94 77 123 4567'),
        '+94 77 123 4567',
      );
    });

    test('6. SriLankaPhoneInputFormatter limits to 9 digits and removes leading zero', () {
      final formatter = SriLankaPhoneInputFormatter();

      // Strips leading zero
      final zeroTest = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '077'),
      );
      expect(zeroTest.text, '77');

      // Limits to 9 digits maximum
      final lengthTest = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '771234567890'),
      );
      expect(lengthTest.text, '771234567');
      expect(lengthTest.text.length, 9);

      // Filters out non-digits
      final alphaTest = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '77abc123!4567'),
      );
      expect(alphaTest.text, '771234567');
    });
  });

  group('Customer & Seller Registration Form Phone Input Widget Tests', () {
    testWidgets('7. Customer Registration shows +94 badge and enforces 9 digit entry', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignupScreen(onGoToLogin: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Check +94 badge
      expect(find.text('🇱🇰 +94'), findsOneWidget);

      // Find the phone TextFormField (it has hint '77 123 4567')
      final phoneField = find.widgetWithText(TextFormField, '77 123 4567');
      expect(phoneField, findsOneWidget);

      // Try entering more than 9 digits with leading 0
      await tester.enterText(phoneField, '077123456789');
      await tester.pumpAndSettle();

      // Formatter should have stripped 0 and capped at 9 digits: 771234567
      expect(find.text('771234567'), findsOneWidget);
    });

    testWidgets('8. Seller Registration shows +94 badge and shop fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignupScreen(onGoToLogin: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Shop Owner (Seller) role
      await tester.tap(find.text('Shop Owner'));
      await tester.pumpAndSettle();

      // Verify +94 badge is present for Seller
      expect(find.text('🇱🇰 +94'), findsOneWidget);

      // Verify shop owner fields appear
      expect(find.text('Shop name'), findsOneWidget);
      expect(find.text('Shop address'), findsOneWidget);

      // Verify phone number field accepts 9 digits
      final phoneField = find.widgetWithText(TextFormField, '77 123 4567');
      await tester.enterText(phoneField, '719876543');
      await tester.pumpAndSettle();

      expect(find.text('719876543'), findsOneWidget);
    });

    testWidgets('9. Submitting incomplete phone shows 9 digit validation error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignupScreen(onGoToLogin: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final phoneField = find.widgetWithText(TextFormField, '77 123 4567');
      await tester.enterText(phoneField, '77123'); // only 5 digits
      await tester.pumpAndSettle();

      // Tap Sign up button
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter exactly 9 digits after +94 (e.g. 77 123 4567)'),
        findsOneWidget,
      );
    });

    testWidgets('10. RegisterForm component displays +94 prefix badge and restricts input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RegisterForm(onSwitchToLogin: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🇱🇰 +94'), findsOneWidget);

      final phoneField = find.widgetWithText(TextFormField, '77 123 4567');
      expect(phoneField, findsOneWidget);

      await tester.enterText(phoneField, '077999888777');
      await tester.pumpAndSettle();

      // Leading 0 stripped and capped at 9 digits: 779998887
      expect(find.text('779998887'), findsOneWidget);
    });
  });
}
