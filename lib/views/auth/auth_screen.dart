import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'forgot_password_flow.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'signup_screen.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

enum AuthScreenStep {
  splash,
  onboarding,
  welcome,
  login,
  signup,
  forgotPassword,
}

class AuthScreen extends StatefulWidget {
  final AuthScreenStep? initialStep;

  const AuthScreen({
    super.key,
    this.initialStep,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthScreenStep _currentStep;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    if (widget.initialStep != null) {
      _currentStep = widget.initialStep!;
    } else {
      _currentStep = AuthScreenStep.splash;
    }
  }

  void _goTo(AuthScreenStep step) {
    setState(() {
      _currentStep = step;
    });
    _authService.clearError();
  }

  Future<void> _handleGoogleSignIn() async {
    // Quick Demo / Guest Customer sign-in for seamless experience
    await _authService.login(
      email: 'customer@dashgrocer.com',
      password: 'pass123',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentStep) {
      case AuthScreenStep.splash:
        return SplashScreen(
          key: const ValueKey('splash_screen'),
          onFinish: () => _goTo(AuthScreenStep.onboarding),
        );

      case AuthScreenStep.onboarding:
        // Figma ONBOARDING1, ONBOARDING2, ONBOARDING3 (Screens 1, 2, 3)
        return OnboardingScreen(
          key: const ValueKey('onboarding_screen'),
          onFinish: () => _goTo(AuthScreenStep.welcome),
        );

      case AuthScreenStep.welcome:
        // Figma WELCOME (Screen 6)
        return WelcomeScreen(
          key: const ValueKey('welcome_screen'),
          onGoToLogin: () => _goTo(AuthScreenStep.login),
          onGoToRegister: () => _goTo(AuthScreenStep.signup),
          onGoogleSignIn: _handleGoogleSignIn,
        );

      case AuthScreenStep.login:
        // Figma LOGIN (Screen 4)
        return LoginScreen(
          key: const ValueKey('login_screen'),
          onGoToRegister: () => _goTo(AuthScreenStep.signup),
          onGoToForgotPassword: () => _goTo(AuthScreenStep.forgotPassword),
        );

      case AuthScreenStep.signup:
        // Figma SIGNUP (Screen 5)
        return SignupScreen(
          key: const ValueKey('signup_screen'),
          onGoToLogin: () => _goTo(AuthScreenStep.login),
        );

      case AuthScreenStep.forgotPassword:
        // Figma PASSWORD RECOVERY: PASSWORD, VERIFY, CHANGE (Screens 8, 9, 10)
        return ForgotPasswordFlow(
          key: const ValueKey('forgot_password_flow'),
          onBackToLogin: () => _goTo(AuthScreenStep.login),
        );
    }
  }
}
