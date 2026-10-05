import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class AboutMeScreen extends StatefulWidget {
  final UserModel? user;

  const AboutMeScreen({super.key, this.user});

  @override
  State<AboutMeScreen> createState() => _AboutMeScreenState();
}

class _AboutMeScreenState extends State<AboutMeScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _pickupLocationController;

  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _obscureNewPass = true;
  bool _isSaving = false;
  bool _isChangePassExpanded = false;

  @override
  void initState() {
    super.initState();
    final user = widget.user ?? AuthService().currentUser;
    _nameController = TextEditingController(
      text: user?.fullName.isNotEmpty == true ? user!.fullName : 'Kasun Perera',
    );
    _emailController = TextEditingController(
      text: user?.email.isNotEmpty == true ? user!.email : 'kasun.perera@gmail.com',
    );
    _phoneController = TextEditingController(
      text: user?.phoneNumber.isNotEmpty == true ? user!.phoneNumber : '+94 77 123 4567',
    );
    _pickupLocationController = TextEditingController(
      text: 'GreenLeaf Fresh Mart - Colombo 03',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pickupLocationController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile details updated successfully!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.brandGreenDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F5F9),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About me',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  _buildCard(
                    child: Column(
                      children: [
                        _buildField(_nameController, Icons.person_outline_rounded, 'Full Name'),
                        const SizedBox(height: 10),
                        _buildField(_emailController, Icons.mail_outline_rounded, 'Email Address'),
                        const SizedBox(height: 10),
                        _buildField(_phoneController, Icons.phone_outlined, 'Phone Number'),
                        const SizedBox(height: 10),
                        _buildField(_pickupLocationController, Icons.store_outlined, 'Preferred Store Location'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _isChangePassExpanded = !_isChangePassExpanded),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Change Password',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                _isChangePassExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ),
                        if (_isChangePassExpanded) ...[
                          const SizedBox(height: 14),
                          _buildField(_currentPassController, Icons.lock_outline_rounded, 'Current password',
                              obscureText: true),
                          const SizedBox(height: 10),
                          _buildField(
                            _newPassController,
                            Icons.lock_outline_rounded,
                            'New password',
                            obscureText: _obscureNewPass,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 18,
                                color: const Color(0xFF94A3B8),
                              ),
                              onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildField(_confirmPassController, Icons.lock_outline_rounded, 'Confirm new password',
                              obscureText: true),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSaving ? null : _saveSettings,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save settings',
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _buildField(
    TextEditingController controller,
    IconData icon,
    String hint, {
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
