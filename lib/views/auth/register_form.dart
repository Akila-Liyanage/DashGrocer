import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'widgets/animated_auth_button.dart';
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
    return AppColors.success;
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await _authService.register(
        fullName: _nameController.text,
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

    return ListenableBuilder(
      listenable: _authService,
      builder: (context, _) {
        final isLoading = _authService.isLoading;
        final errorMsg = _authService.errorMessage;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role Segmented Selector with Dynamic Pill Motion
              const Text(
                'Register as:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedRoleSelector(
                selectedRole: _selectedRole,
                onRoleChanged: (newRole) {
                  setState(() {
                    _selectedRole = newRole;
                  });
                  _authService.clearError();
                },
              ),

              const SizedBox(height: 12),

              // Animated Role Description Chip
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isShopOwner
                      ? AppColors.roleShopOwnerSoft
                      : AppColors.roleCustomerSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isShopOwner ? Icons.store_mall_directory_outlined : Icons.shopping_basket_outlined,
                      size: 16,
                      color: isShopOwner ? AppColors.roleShopOwner : AppColors.roleCustomer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedRole.description,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isShopOwner ? AppColors.roleShopOwner : AppColors.roleCustomer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Animated Error Banner
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: errorMsg != null
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMsg,
                                style: const TextStyle(
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

              // Full Name Input
              DynamicTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'e.g. Kasun Perera',
                prefixIcon: Icons.person_outline_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Email Input
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

              const SizedBox(height: 14),

              // Phone Number Input
              DynamicTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '+94 7X XXX XXXX',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your mobile phone number';
                  }
                  return null;
                },
              ),

              // Dynamic Motion Expandable Section for Shop Owner Fields
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                child: isShopOwner
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          const Divider(color: AppColors.border, height: 1),
                          const SizedBox(height: 14),
                          const Row(
                            children: [
                              Icon(
                                Icons.storefront_rounded,
                                size: 16,
                                color: AppColors.accentOrange,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Store Details (Shop Owner)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DynamicTextField(
                            controller: _shopNameController,
                            label: 'Grocery / Store Name',
                            hint: 'e.g. Fresh Direct Express',
                            prefixIcon: Icons.business_outlined,
                            validator: (val) {
                              if (isShopOwner && (val == null || val.trim().isEmpty)) {
                                return 'Please enter your shop or grocery name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          DynamicTextField(
                            controller: _shopAddressController,
                            label: 'Pickup Store Address',
                            hint: 'e.g. 102 High Street, Kandy',
                            prefixIcon: Icons.location_on_outlined,
                            validator: (val) {
                              if (isShopOwner && (val == null || val.trim().isEmpty)) {
                                return 'Please specify the customer pickup location';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: AppColors.border, height: 1),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 14),

              // Password Input
              DynamicTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Minimum 6 characters',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                onChanged: () => _calculatePasswordStrength(_passwordController.text),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (val.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              // Password Strength Indicator
              if (_strengthLabel.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          tween: Tween<double>(begin: 0, end: _passwordStrength),
                          builder: (context, value, _) {
                            return LinearProgressIndicator(
                              value: value,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getStrengthColor(),
                              ),
                              minHeight: 4,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _strengthLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getStrengthColor(),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // Confirm Password Input
              DynamicTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Re-enter your password',
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

              const SizedBox(height: 24),

              // Submit Button
              AnimatedAuthButton(
                text: isShopOwner
                    ? 'Register as Shop Owner'
                    : 'Create Customer Account',
                icon: Icons.check_circle_outline_rounded,
                color: isShopOwner ? AppColors.accentOrange : AppColors.primary,
                isLoading: isLoading,
                onPressed: _submit,
              ),

              const SizedBox(height: 24),

              // Switch to Login Row
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Already registered? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onSwitchToLogin,
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
