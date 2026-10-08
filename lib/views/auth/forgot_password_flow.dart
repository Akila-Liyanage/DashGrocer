import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

enum RecoveryStep {
  enterEmail, // Screen 8 (PASSWORD)
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
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleBack() {
    widget.onBackToLogin();
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
        _message = 'Password reset link sent to your email!';
      });
      // Redirect to login after showing success message
      await Future.delayed(const Duration(milliseconds: 1500));
      widget.onBackToLogin();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _message = e.message ?? 'Failed to send recovery email.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _message = 'Failed to send recovery email.';
      });
    }
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
              _buildEnterEmailStep(),

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
                    'Send link',
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
