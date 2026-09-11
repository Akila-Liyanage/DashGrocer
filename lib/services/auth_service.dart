import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Pre-configured Demo Accounts for HCI testing
  static final List<UserModel> demoUsers = [
    const UserModel(
      id: 'cust_01',
      email: 'customer@dashgrocer.com',
      fullName: 'Kasun Perera',
      phoneNumber: '+94 77 123 4567',
      role: UserRole.customer,
    ),
    const UserModel(
      id: 'owner_01',
      email: 'owner@dashgrocer.com',
      fullName: 'Sunil Weerasinghe',
      phoneNumber: '+94 71 987 6543',
      role: UserRole.shopOwner,
      shopName: 'GreenLeaf Fresh Mart',
      shopAddress: 'No. 42, High Level Road, Maharagama',
    ),
    const UserModel(
      id: 'admin_01',
      email: 'admin@dashgrocer.com',
      fullName: 'System Administrator',
      phoneNumber: '+94 11 234 5678',
      role: UserRole.admin,
    ),
  ];

  // In-memory registered user database
  final List<UserModel> _registeredUsers = [...demoUsers];

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  static Duration simulatedDelay = const Duration(milliseconds: 700);

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Smooth HCI interaction delay to demonstrate loading motion
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    final normalizedEmail = email.trim().toLowerCase();

    // Check credentials against registered database
    final matchedUser = _registeredUsers.firstWhere(
      (user) => user.email.toLowerCase() == normalizedEmail,
      orElse: () => const UserModel(
        id: '',
        email: '',
        fullName: '',
        phoneNumber: '',
        role: UserRole.customer,
      ),
    );

    if (matchedUser.id.isEmpty) {
      _isLoading = false;
      _errorMessage = 'No account found with this email. Please register.';
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      _isLoading = false;
      _errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    _currentUser = matchedUser;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Register a new user with Role-Based attributes
  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
    String? shopName,
    String? shopAddress,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }

    final normalizedEmail = email.trim().toLowerCase();

    // Check if email is already taken
    final exists = _registeredUsers.any(
      (u) => u.email.toLowerCase() == normalizedEmail,
    );

    if (exists) {
      _isLoading = false;
      _errorMessage = 'An account already exists with this email address.';
      notifyListeners();
      return false;
    }

    // Role-specific validation
    if (role == UserRole.shopOwner) {
      if (shopName == null || shopName.trim().isEmpty) {
        _isLoading = false;
        _errorMessage = 'Shop name is required for Shop Owners.';
        notifyListeners();
        return false;
      }
      if (shopAddress == null || shopAddress.trim().isEmpty) {
        _isLoading = false;
        _errorMessage = 'Pickup location/address is required for Shop Owners.';
        notifyListeners();
        return false;
      }
    }

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: normalizedEmail,
      fullName: fullName.trim(),
      phoneNumber: phoneNumber.trim(),
      role: role,
      shopName: role == UserRole.shopOwner ? shopName?.trim() : null,
      shopAddress: role == UserRole.shopOwner ? shopAddress?.trim() : null,
    );

    _registeredUsers.add(newUser);
    _currentUser = newUser;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Quick Demo Role Switcher for instant examiner testing
  void switchDemoRole(UserRole role) {
    _currentUser = demoUsers.firstWhere((u) => u.role == role);
    _errorMessage = null;
    notifyListeners();
  }

  /// Logout
  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
