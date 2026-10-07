import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onGoToRegister;
  final VoidCallback onGoToForgotPassword;

  const LoginScreen({
    super.key,
    required this.onGoToRegister,
    required this.onGoToForgotPassword,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'customer@dashgrocer.com');
  final _passwordController = TextEditingController(text: 'Password123!');
  final _passwordFocusNode = FocusNode();
  final _authService = AuthService();

  UserRole _selectedRole = UserRole.customer;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isCapsLockOn = false;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.onKeyEvent = (node, event) {
      final caps = HardwareKeyboard.instance.lockModesEnabled.contains(KeyboardLockMode.capsLock);
      if (caps != _isCapsLockOn) {
        setState(() => _isCapsLockOn = caps);
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      if (role == UserRole.shopOwner) {
        _emailController.text = 'seller@dashgrocer.com';
        _passwordController.text = 'Password123!';
      } else if (role == UserRole.admin) {
        _emailController.text = 'admin@dashgrocer.com';
        _passwordController.text = 'Admin123!';
      } else {
        _emailController.text = 'customer@dashgrocer.com';
        _passwordController.text = 'Password123!';
      }
    });
    _authService.clearError();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (success && _rememberMe && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login credentials saved for this device.'),
            backgroundColor: AppColors.brandGreen,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Top Hero Image (Figma Basket of fresh vegetables)
              Expanded(
                flex: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/login_hero.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (context, err, _) => Image.network(
                          'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1080&q=80',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Sheet Card matching Figma LOGIN screen
              Expanded(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 24,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    child: SafeArea(
                      top: false,
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        // Title
                        Text(
                          'Welcome back !',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Subtitle
                        Text(
                          'Sign in to your account',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF868889),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Segmented Role Pill Toggle: [Shop Owner] [Customer]
                        _buildRoleSegmentToggle(),

                        const SizedBox(height: 16),

                        // Error Banner if any
                        if (errorMsg != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
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

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Email Address',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter email';
                            if (!v.contains('@')) return 'Enter valid email';
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
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

                        if (_isCapsLockOn)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.keyboard_capslock_rounded, size: 14, color: Color(0xFFD97706)),
                                const SizedBox(width: 4),
                                Text(
                                  'Caps Lock is ON',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Row: Remember me checkbox & Forgot password link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.brandGreen,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember me',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFF868889),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: widget.onGoToForgotPassword,
                              behavior: HitTestBehavior.opaque,
                              child: Text(
                                'Forgot password',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF407EC7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Login Button (Green, matching Figma)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandGreen,
                              disabledBackgroundColor: AppColors.brandGreen.withValues(alpha: 0.6),
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
                                    'Login',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bottom link: Don't have an account ? Sign up
                        Center(
                          child: GestureDetector(
                            onTap: widget.onGoToRegister,
                            behavior: HitTestBehavior.opaque,
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account ? ",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF868889),
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign up',
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

                        const SizedBox(height: 14),

                        // Quick Demo Accounts Sheet Trigger
                        Center(
                          child: InkWell(
                            onTap: _showDemoAccountsSheet,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '1-Tap Demo Credentials',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF475569),
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
              onTap: () => _onRoleChanged(UserRole.customer),
            ),
          ),
          Expanded(
            child: _buildRolePill(
              title: 'Shop Owner',
              isSelected: _selectedRole == UserRole.shopOwner,
              onTap: () => _onRoleChanged(UserRole.shopOwner),
            ),
          ),
          Expanded(
            child: _buildRolePill(
              title: 'Admin',
              isSelected: _selectedRole == UserRole.admin,
              onTap: () => _onRoleChanged(UserRole.admin),
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
    FocusNode? focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: (_) {
          if (_authService.errorMessage != null) {
            _authService.clearError();
          }
        },
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

  void _showDemoAccountsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick Demo Accounts',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap any role below to autofill verified test credentials:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),
              _buildDemoAccountCard(
                ctx: ctx,
                title: 'Customer (Kasun Perera)',
                email: 'customer@dashgrocer.com',
                pass: 'Password123!',
                role: UserRole.customer,
                icon: Icons.person_rounded,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 8),
              _buildDemoAccountCard(
                ctx: ctx,
                title: 'Shop Owner (Sunil Weerasinghe)',
                email: 'seller@dashgrocer.com',
                pass: 'Password123!',
                role: UserRole.shopOwner,
                icon: Icons.storefront_rounded,
                color: const Color(0xFF3B82F4),
              ),
              const SizedBox(height: 8),
              _buildDemoAccountCard(
                ctx: ctx,
                title: 'Platform Admin',
                email: 'admin@dashgrocer.com',
                pass: 'Admin123!',
                role: UserRole.admin,
                icon: Icons.admin_panel_settings_rounded,
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccountCard({
    required BuildContext ctx,
    required String title,
    required String email,
    required String pass,
    required UserRole role,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        setState(() {
          _selectedRole = role;
          _emailController.text = email;
          _passwordController.text = pass;
        });
        _authService.clearError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded $title credentials'),
            backgroundColor: AppColors.brandGreen,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    email,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
