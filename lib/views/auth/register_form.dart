import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/phone_validator.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'widgets/animated_role_selector.dart';
import 'widgets/dynamic_text_field.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const RegisterForm({
    super.key,
    required this.onSwitchToLogin,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.customer;
  final _authService = AuthService();
  double _passwordStrength = 0.0;
  String _strengthLabel = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _strengthLabel = '';
      });
      return;
    }

    double score = 0.2;
    if (password.length >= 6) score += 0.3;
    if (password.length >= 8) score += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.15;

    setState(() {
      _passwordStrength = score.clamp(0.0, 1.0);
      if (_passwordStrength < 0.4) {
        _strengthLabel = 'Weak';
      } else if (_passwordStrength < 0.75) {
        _strengthLabel = 'Good';
      } else {
        _strengthLabel = 'Strong';
      }
    });
  }

  Color _getStrengthColor() {
    if (_passwordStrength < 0.4) return AppColors.error;
    if (_passwordStrength < 0.75) return AppColors.warning;
    return const Color(0xFF00C265);
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final formattedPhone = SriLankaPhoneUtils.formatWithCountryCode(_phoneController.text);
      await _authService.register(
        fullName: _nameController.text,
        email: _emailController.text,
        phoneNumber: formattedPhone,
        password: _passwordController.text,
        role: _selectedRole,
        shopName: _selectedRole == UserRole.shopOwner ? _shopNameController.text : null,
        shopAddress: _selectedRole == UserRole.shopOwner ? _shopAddressController.text : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isShopOwner = _selectedRole == UserRole.shopOwner;

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
              // Modern Fresh Produce Banner Image
              Container(
                height: 118,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/fresh_groceries.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, error) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF064E3B), Color(0xFF047857)],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.75),
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C265),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Fresh Daily Guarantee',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Join DashGrocer Market',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Pre-order fresh local items for zero-wait pickup',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Role Selector Pill
              AnimatedRoleSelector(
                selectedRole: _selectedRole,
                onRoleChanged: (newRole) {
                  setState(() {
                    _selectedRole = newRole;
                  });
                  _authService.clearError();
                },
              ),

              const SizedBox(height: 16),

              // Animated Error Banner
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: errorMsg != null
                    ? Container(
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
                      )
                    : const SizedBox.shrink(),
              ),

              // Full Name
              DynamicTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Kasun Perera',
                prefixIcon: Icons.person_outline_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Contact / Phone Number with Phone Icon
              DynamicTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '77 123 4567',
                prefixIcon: Icons.phone_outlined,
                prefixWidget: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🇱🇰 +94',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 16, color: const Color(0xFFE2E8F0)),
                    ],
                  ),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  SriLankaPhoneInputFormatter(),
                ],
                validator: SriLankaPhoneUtils.validate,
              ),

              const SizedBox(height: 14),

              // Email Address
              DynamicTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'name@example.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!val.contains('@') || !val.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              // Dynamic Store Details if Shop Owner
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: isShopOwner
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          DynamicTextField(
                            controller: _shopNameController,
                            label: 'Store Name',
                            hint: 'GreenMart Colombo',
                            prefixIcon: Icons.storefront_outlined,
                            validator: (val) {
                              if (isShopOwner && (val == null || val.trim().isEmpty)) {
                                return 'Please enter your grocery shop name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          DynamicTextField(
                            controller: _shopAddressController,
                            label: 'Pickup Address',
                            hint: 'No. 42, High Level Road',
                            prefixIcon: Icons.location_on_outlined,
                            validator: (val) {
                              if (isShopOwner && (val == null || val.trim().isEmpty)) {
                                return 'Please specify the store pickup address';
                              }
                              return null;
                            },
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 14),

              // Password
              DynamicTextField(
                controller: _passwordController,
                label: 'Password',
                hint: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                onChanged: () => _calculatePasswordStrength(_passwordController.text),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (val.length < 6) {
                    return 'Minimum 6 characters required';
                  }
                  return null;
                },
              ),

              // Password Strength Indicator
              if (_strengthLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _passwordStrength,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor()),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _strengthLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getStrengthColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Confirm Password
              DynamicTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: '••••••••',
                prefixIcon: Icons.lock_reset_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (val != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 22),

              // Solid Emerald Pill Submit Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C265),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    shadowColor: const Color(0xFF00C265).withValues(alpha: 0.35),
                  ),
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isShopOwner ? 'Create Store Account' : 'Create Account',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              // Footer: Already have an account? Sign In
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onSwitchToLogin,
                      child: Text(
                        'Sign In',
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
