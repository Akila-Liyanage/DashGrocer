import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashgrocer/main.dart';
import 'package:dashgrocer/services/auth_service.dart';
import 'package:dashgrocer/views/auth/welcome_screen.dart';
import 'package:dashgrocer/views/auth/login_screen.dart';
import 'package:dashgrocer/views/auth/signup_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AuthService.simulatedDelay = Duration.zero;
    AuthService().logout();
  });

  testWidgets('Welcome screen renders with direct Sign in with Email and Register buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeScreen(
          onGoToLogin: () {},
          onGoToRegister: () {},
          onGoogleSignIn: () {},
        ),
      ),
    );
    await tester.pump();

    // Verify Welcome screen text & direct action buttons
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Sign In with Email'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);

    // Verify Google sign-in is optional at the bottom
    expect(find.text('Or optional sign in'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('Login screen asks directly for Email and Password with optional Google button at bottom', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onGoToRegister: () {},
          onGoToForgotPassword: () {},
        ),
      ),
    );
    await tester.pump();

    // Direct email and password input fields
    expect(find.text('Welcome back !'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Forgot password'), findsOneWidget);

    // Role switcher chips
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Shop Owner'), findsOneWidget);

    // Google login is optional at the bottom
    expect(find.text('Or continue with'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
  });

  testWidgets('Signup screen renders role selector and dynamically shows shop fields for Shop Owner', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SignupScreen(
          onGoToLogin: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);

    // Initially Customer is selected, shop fields are not visible
    expect(find.text('Shop name'), findsNothing);

    // Switch role to Shop Owner
    await tester.tap(find.text('Shop Owner'));
    await tester.pumpAndSettle();

    // Shop fields should now be visible
    expect(find.text('Shop name'), findsOneWidget);
    expect(find.text('Shop address'), findsOneWidget);
  });

  testWidgets('Role-Based Access Control: Customer login shows Customer Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const DashGrocerApp());
    await tester.pump(const Duration(milliseconds: 400));

    final authService = AuthService();
    await authService.login(
      email: 'customer@dashgrocer.com',
      password: 'pass123',
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Verify customer greeting, categories and pickup card
    expect(find.text('Hi, Kasun 👋'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Nearby Pickup Shops'), findsOneWidget);
  });

  testWidgets('Role-Based Access Control: Shop Owner login shows Shop Owner Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const DashGrocerApp());
    await tester.pump(const Duration(milliseconds: 400));

    final authService = AuthService();
    await authService.login(
      email: 'owner@dashgrocer.com',
      password: 'pass123',
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Verify shop owner dashboard is rendered
    expect(find.text('GreenLeaf Fresh Mart'), findsOneWidget);
    expect(find.text('Open for Pickup'), findsOneWidget);
    expect(find.text('Incoming Pickup Orders'), findsOneWidget);
  });
}
