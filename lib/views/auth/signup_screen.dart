import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onGoToLogin;

  const SignupScreen({
    super.key,
    required this.onGoToLogin,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  UserRole _selectedRole = UserRole.customer;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await _authService.register(
        fullName: _nameController.text.trim().isEmpty ? 'Shopper' : _nameController.text.trim(),
        email: _emailController.text,
        phoneNumber: _phoneController.text,
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _authService,
        builder: (context, _) {
          final isLoading = _authService.isLoading;
          final errorMsg = _authService.errorMessage;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Hero Image (Full Width Banner) + Back Button
              SizedBox(
                width: double.infinity,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/welcome_hero.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 120,
                      alignment: Alignment.center,
                      errorBuilder: (context, err, _) => Image.network(
                        'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1080&q=80',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                    // Back button on top left
                    SafeArea(
                      bottom: false,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14, top: 8),
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withValues(alpha: 0.9),
                            radius: 17,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Color(0xFF1E293B)),
                              onPressed: widget.onGoToLogin,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Sheet Card matching Figma SIGNUP screen
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    child: SafeArea(
                      top: false,
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                'Create account',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E293B),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Subtitle
                              Text(
                                'Quickly create account',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF868889),
                                ),
                              ),

                          const SizedBox(height: 4),

                          // Subtitle
                          Text(
                            'Quickly create account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF868889),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Segmented Role Pill Toggle: [Customer] [Shop Owner]
                          _buildRoleSegmentToggle(),

                          const SizedBox(height: 14),

                          // Error Banner if any
                          if (errorMsg != null) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.errorSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMsg,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Full Name Field
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Full name',
                            icon: Icons.person_outline_rounded,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter full name';
                              return null;
                            },
                          ),

                          const SizedBox(height: 10),

                          // Email Address Field
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Email address',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter email';
                              if (!v.contains('@')) return 'Enter valid email';
                              return null;
                            },
                          ),

                          const SizedBox(height: 10),

                          // Phone Number Field
                          _buildTextField(
                            controller: _phoneController,
                            hint: 'Phone number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter phone number';
                              return null;
                            },
                          ),

                          // Additional Shop Owner Fields
                          if (isShopOwner) ...[
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: _shopNameController,
                              hint: 'Shop name',
                              icon: Icons.storefront_outlined,
                              validator: (v) {
                                if (isShopOwner && (v == null || v.trim().isEmpty)) {
                                  return 'Enter shop name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: _shopAddressController,
                              hint: 'Shop address',
                              icon: Icons.location_on_outlined,
                              validator: (v) {
                                if (isShopOwner && (v == null || v.trim().isEmpty)) {
                                  return 'Enter shop address';
                                }
                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Password Field
                          _buildTextField(
                            controller: _passwordController,
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 18,
                                color: const Color(0xFF94A3B8),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter password';
                              if (v.length < 6) return 'At least 6 characters';
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // Sign up Button (Green, matching Figma)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isLoading ? null : _submit,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Sign up',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Bottom link: Already have an account ? Login
                          Center(
                            child: GestureDetector(
                              onTap: widget.onGoToLogin,
                              behavior: HitTestBehavior.opaque,
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already have an account ? ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: const Color(0xFF868889),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Login',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: const Color(0xFF1E293B),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
        },
      ),
    );
  }

  Widget _buildRoleSegmentToggle() {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRolePill(
              title: 'Customer',
              isSelected: _selectedRole == UserRole.customer,
              onTap: () => setState(() => _selectedRole = UserRole.customer),
            ),
          ),
          Expanded(
            child: _buildRolePill(
              title: 'Shop Owner',
              isSelected: _selectedRole == UserRole.shopOwner,
              onTap: () => setState(() => _selectedRole = UserRole.shopOwner),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
