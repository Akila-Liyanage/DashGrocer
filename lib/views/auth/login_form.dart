import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'widgets/dynamic_text_field.dart';
import 'widgets/social_auth_button.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onSwitchToRegister;

  const LoginForm({
    super.key,
    required this.onSwitchToRegister,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'customer@dashgrocer.com');
  final _passwordController = TextEditingController(text: 'pass123');
  final _authService = AuthService();

  bool _showEmailFields = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _autofillRole(UserRole role) {
    final demo = AuthService.demoUsers.firstWhere((u) => u.role == role);
    setState(() {
      _emailController.text = demo.email;
      _passwordController.text = 'pass123';
      _showEmailFields = true;
    });
    _authService.clearError();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
  }

  Future<void> _loginAsGuest() async {
    await _authService.login(
      email: 'customer@dashgrocer.com',
      password: 'pass123',
    );
  }

  void _mockSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$provider login simulated. Signing in as Customer...',
          style: GoogleFonts.plusJakartaSans(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    _loginAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authService,
      builder: (context, _) {
        final isLoading = _authService.isLoading;
        final errorMsg = _authService.errorMessage;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error banner if any
              if (errorMsg != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMsg,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 1. Continue with Facebook
              SocialAuthButton.facebook(
                onPressed: () => _mockSocialLogin('Facebook'),
              ),

              const SizedBox(height: 12),

              // 2. Continue with Google
              SocialAuthButton.google(
                onPressed: () => _mockSocialLogin('Google'),
              ),

              const SizedBox(height: 18),

              // 3. Or divider
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'or',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 4. Continue as Guest button
              SocialAuthButton.guest(
                isLoading: isLoading && !_showEmailFields,
                onPressed: _loginAsGuest,
              ),

              const SizedBox(height: 16),

              // Toggle to view Email & Password credentials
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showEmailFields = !_showEmailFields;
                    });
                  },
                  icon: Icon(
                    _showEmailFields
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.mail_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _showEmailFields
                        ? 'Hide Email Sign In'
                        : 'Sign In with Email & Password',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              // Email & Password Fields
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _showEmailFields
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),

                          // Email Input
                          DynamicTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'name@example.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // Password Input
                          DynamicTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (val.length < 6) {
                                return 'Minimum 6 characters required';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Password reset instructions sent to ${_emailController.text}',
                                      style: GoogleFonts.plusJakartaSans(),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot password?',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Sign In Button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C265),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: isLoading ? null : _submit,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Sign In',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // Demo Switcher Pills with distinct accents
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Demo:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DemoPill(
                        label: 'Customer',
                        dotColor: const Color(0xFF00C265),
                        onTap: () => _autofillRole(UserRole.customer),
                      ),
                      const SizedBox(width: 6),
                      _DemoPill(
                        label: 'Shop',
                        dotColor: const Color(0xFFF59E0B),
                        onTap: () => _autofillRole(UserRole.shopOwner),
                      ),
                      const SizedBox(width: 6),
                      _DemoPill(
                        label: 'Admin',
                        dotColor: const Color(0xFF6366F1),
                        onTap: () => _autofillRole(UserRole.admin),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Footer: Don't have an account? Sign up
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onSwitchToRegister,
                      child: Text(
                        'Sign up',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF00C265),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DemoPill extends StatelessWidget {
  final String label;
  final Color dotColor;
  final VoidCallback onTap;

  const _DemoPill({
    required this.label,
    required this.dotColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
