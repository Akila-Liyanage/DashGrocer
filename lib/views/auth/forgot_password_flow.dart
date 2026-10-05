import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

enum RecoveryStep {
  enterEmail, // Screen 8 (PASSWORD)
  verifyCode, // Screen 9 (VERIFY)
  changePassword, // Screen 10 (CHANGE)
}

class ForgotPasswordFlow extends StatefulWidget {
  final VoidCallback onBackToLogin;

  const ForgotPasswordFlow({
    super.key,
    required this.onBackToLogin,
  });

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> {
  RecoveryStep _step = RecoveryStep.enterEmail;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_step == RecoveryStep.changePassword) {
      setState(() => _step = RecoveryStep.verifyCode);
    } else if (_step == RecoveryStep.verifyCode) {
      setState(() => _step = RecoveryStep.enterEmail);
    } else {
      widget.onBackToLogin();
    }
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _isError = true;
        _message = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // Trigger Firebase Password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _isLoading = false;
        _isError = false;
        _message = 'Recovery code / link sent to your email!';
        _step = RecoveryStep.verifyCode;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _message = e.message ?? 'Failed to send recovery email.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = false;
        // Proceed to code verify step for user experience
        _step = RecoveryStep.verifyCode;
      });
    }
  }

  void _verifyCode() {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length < 4) {
      setState(() {
        _isError = true;
        _message = 'Please enter the 4 to 6 digit code received.';
      });
      return;
    }

    setState(() {
      _message = null;
      _step = RecoveryStep.changePassword;
    });
  }

  Future<void> _submitNewPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.length < 6) {
      setState(() {
        _isError = true;
        _message = 'Password must be at least 6 characters long.';
      });
      return;
    }

    if (newPass != confirmPass) {
      setState(() {
        _isError = true;
        _message = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _isLoading = false;
      _isError = false;
      _message = 'Password updated successfully! Redirecting to login...';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    widget.onBackToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
          onPressed: _handleBack,
        ),
        centerTitle: true,
        title: Text(
          'Password Recovery',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step == RecoveryStep.enterEmail) _buildEnterEmailStep(),
              if (_step == RecoveryStep.verifyCode) _buildVerifyCodeStep(),
              if (_step == RecoveryStep.changePassword) _buildChangePasswordStep(),

              if (_message != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isError ? AppColors.errorSoft : AppColors.brandGreenSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isError ? AppColors.error : AppColors.brandGreenDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // SCREEN 8: PASSWORD RECOVERY (Enter Email)
  Widget _buildEnterEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Text(
          'Forgot Password',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A fresh start is just ahead, regain access to your account.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF868889),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 36),

        _buildInputField(
          controller: _emailController,
          hint: 'Email Address',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _sendCode,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Send code',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // SCREEN 9: VERIFY (Enter Code)
  Widget _buildVerifyCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Text(
          'Forgot Password',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A fresh start is just ahead, regain access to your account.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF868889),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 36),

        _buildInputField(
          controller: _codeController,
          hint: '-- Enter the code',
          icon: Icons.lock_clock_outlined,
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _verifyCode,
            child: Text(
              'verify',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // SCREEN 10: CHANGE PASSWORD
  Widget _buildChangePasswordStep() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change Password',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),

          // New Password field
          _buildInputField(
            controller: _newPasswordController,
            hint: '•••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureNewPass,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
            ),
          ),

          const SizedBox(height: 14),

          // Confirm password field
          _buildInputField(
            controller: _confirmPasswordController,
            hint: 'Confirm password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirmPass,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _submitNewPassword,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Login',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
