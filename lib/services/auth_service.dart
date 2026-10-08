import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:dashgrocer/models/user_model.dart';
import 'database_seeder.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initAuthState();
  }

  FirebaseAuth? get _firebaseAuth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastLoginTime;
  bool _biometricsEnabled = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastLoginTime => _lastLoginTime;
  bool get isBiometricsEnabled => _biometricsEnabled;

  void setBiometricsEnabled(bool enabled) {
    _biometricsEnabled = enabled;
    notifyListeners();
  }

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
      email: 'seller@dashgrocer.com',
      fullName: 'Sunil Weerasinghe',
      phoneNumber: '+94 71 987 6543',
      role: UserRole.shopOwner,
      shopName: 'GreenLeaf Fresh Mart',
      shopAddress: 'No. 42, High Level Road, Maharagama',
    ),
    const UserModel(
      id: 'owner_02',
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

  /// Runtime registry for accounts registered in app session
  final Map<String, UserModel> _registeredUsers = {};
  final Map<String, String> _registeredPasswords = {};

  static bool _isValidDemoPassword(String password) {
    return password == 'Password123!' ||
        password == 'pass123' ||
        password == 'Admin123!' ||
        password == 'admin123' ||
        password == 'password123';
  }

  static Duration simulatedDelay = const Duration(milliseconds: 700);

  StreamSubscription<User?>? _authSub;

  void initFirebaseListeners() {
    _initAuthState();
  }

  void _initAuthState() {
    final auth = _firebaseAuth;
    if (auth == null) return;
    _authSub?.cancel();
    _authSub = auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        if (_currentUser == null || _currentUser!.id != user.uid) {
          await _loadUserProfile(user.uid, fallbackEmail: user.email);
        }
      } else {
        final isDemo = demoUsers.any((d) => d.id == _currentUser?.id);
        if (!isDemo && _currentUser != null) {
          _currentUser = null;
          notifyListeners();
        }
      }
    });
  }

  Future<void> _loadUserProfile(String uid, {String? fallbackEmail}) async {
    try {
      final firestore = _firestore;
      if (firestore == null) {
        final emailLower = (fallbackEmail ?? '').toLowerCase();
        final isSeller = emailLower.contains('seller') || emailLower.contains('owner');
        final isAdmin = emailLower.contains('admin');
        final role = isSeller
            ? UserRole.shopOwner
            : (isAdmin ? UserRole.admin : UserRole.customer);

        _currentUser = UserModel(
          id: uid,
          email: fallbackEmail ?? '',
          fullName: isSeller ? 'Sunil Weerasinghe' : (fallbackEmail?.split('@').first ?? 'Customer Shopper'),
          phoneNumber: isSeller ? '+94 71 987 6543' : '+94 77 123 4567',
          role: role,
          shopName: isSeller ? 'GreenLeaf Fresh Mart' : null,
          shopAddress: isSeller ? 'No. 42, High Level Road, Maharagama' : null,
        );
        notifyListeners();
        return;
      }

      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!, uid);
      } else {
        final emailLower = (fallbackEmail ?? '').toLowerCase();
        final isSeller = emailLower.contains('seller') || emailLower.contains('owner');
        final isAdmin = emailLower.contains('admin');
        final role = isSeller
            ? UserRole.shopOwner
            : (isAdmin ? UserRole.admin : UserRole.customer);

        final newUser = UserModel(
          id: uid,
          email: fallbackEmail ?? '',
          fullName: isSeller ? 'Sunil Weerasinghe' : (fallbackEmail?.split('@').first ?? 'Customer Shopper'),
          phoneNumber: isSeller ? '+94 71 987 6543' : '+94 77 123 4567',
          role: role,
          shopName: isSeller ? 'GreenLeaf Fresh Mart' : null,
          shopAddress: isSeller ? 'No. 42, High Level Road, Maharagama' : null,
        );

        // Store profile in Firestore so role is persisted
        await firestore.collection('users').doc(uid).set(newUser.toMap());
        _currentUser = newUser;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Login with email and password with strict authentication
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      _isLoading = false;
      _errorMessage = 'Please enter your email address.';
      notifyListeners();
      return false;
    }
    if (password.isEmpty) {
      _isLoading = false;
      _errorMessage = 'Please enter your password.';
      notifyListeners();
      return false;
    }

    final demoMatch = demoUsers.where((u) => u.email.toLowerCase() == normalizedEmail);

    try {
      final auth = _firebaseAuth;
      if (auth == null) {
        // Offline / mock mode: authenticate credentials strictly
        if (demoMatch.isNotEmpty) {
          if (_isValidDemoPassword(password)) {
            _currentUser = demoMatch.first;
            _lastLoginTime = DateTime.now();
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
            return true;
          } else {
            _isLoading = false;
            _errorMessage = 'Incorrect password. Please try again.';
            notifyListeners();
            return false;
          }
        }

        if (_registeredUsers.containsKey(normalizedEmail)) {
          if (_registeredPasswords[normalizedEmail] == password) {
            _currentUser = _registeredUsers[normalizedEmail];
            _lastLoginTime = DateTime.now();
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
            return true;
          } else {
            _isLoading = false;
            _errorMessage = 'Incorrect password. Please try again.';
            notifyListeners();
            return false;
          }
        }

        // Neither a demo user nor an existing registered user
        _isLoading = false;
        _errorMessage = 'No account found with this email. Please check your credentials or register.';
        notifyListeners();
        return false;
      }

      final credential = await auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await _loadUserProfile(user.uid, fallbackEmail: user.email);
        _lastLoginTime = DateTime.now();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      if (demoMatch.isNotEmpty) {
        // Strictly check password for demo account
        if (_isValidDemoPassword(password)) {
          try {
            final cred = await DatabaseSeeder.provisionSeedUserAuth(normalizedEmail, password);
            if (cred?.user != null) {
              await _loadUserProfile(cred!.user!.uid, fallbackEmail: cred.user!.email);
              _lastLoginTime = DateTime.now();
              _isLoading = false;
              _errorMessage = null;
              notifyListeners();
              return true;
            }
          } catch (_) {}
          _currentUser = demoMatch.first;
          _lastLoginTime = DateTime.now();
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        } else {
          _isLoading = false;
          _errorMessage = 'Incorrect password. Please try again.';
          notifyListeners();
          return false;
        }
      }

      // Check if account was registered locally in this app session
      if (_registeredUsers.containsKey(normalizedEmail)) {
        if (_registeredPasswords[normalizedEmail] == password) {
          _currentUser = _registeredUsers[normalizedEmail];
          _lastLoginTime = DateTime.now();
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        } else {
          _isLoading = false;
          _errorMessage = 'Incorrect password. Please try again.';
          notifyListeners();
          return false;
        }
      }

      _isLoading = false;
      _errorMessage = _mapFirebaseAuthError(e);
      notifyListeners();
      return false;
    } catch (e) {
      // Unexpected error or desktop platform fallback: strictly verify credentials
      if (demoMatch.isNotEmpty && _isValidDemoPassword(password)) {
        _currentUser = demoMatch.first;
        _lastLoginTime = DateTime.now();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      if (_registeredUsers.containsKey(normalizedEmail) && _registeredPasswords[normalizedEmail] == password) {
        _currentUser = _registeredUsers[normalizedEmail];
        _lastLoginTime = DateTime.now();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Invalid email or password. Please try again.';
      notifyListeners();
      return false;
    }

    _isLoading = false;
    return false;
  }

  /// Register a new user with Firebase Auth and store profile in Cloud Firestore
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

    final normalizedEmail = email.trim().toLowerCase();

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

    // Prevent duplicate registrations
    if (demoUsers.any((u) => u.email.toLowerCase() == normalizedEmail) ||
        _registeredUsers.containsKey(normalizedEmail)) {
      _isLoading = false;
      _errorMessage = 'An account already exists with this email address. Please login.';
      notifyListeners();
      return false;
    }

    try {
      final auth = _firebaseAuth;
      final firestore = _firestore;

      if (auth == null) {
        // Fallback for tests or offline environment
        final newUser = UserModel(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: normalizedEmail,
          fullName: fullName.trim(),
          phoneNumber: phoneNumber.trim(),
          role: role,
          shopName: role == UserRole.shopOwner ? shopName?.trim() : null,
          shopAddress: role == UserRole.shopOwner ? shopAddress?.trim() : null,
        );
        _registeredUsers[normalizedEmail] = newUser;
        _registeredPasswords[normalizedEmail] = password;
        _currentUser = newUser;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      final credential = await auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        _isLoading = false;
        _errorMessage = 'Registration failed. Please try again.';
        notifyListeners();
        return false;
      }

      final newUser = UserModel(
        id: user.uid,
        email: normalizedEmail,
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        role: role,
        shopName: role == UserRole.shopOwner ? shopName?.trim() : null,
        shopAddress: role == UserRole.shopOwner ? shopAddress?.trim() : null,
      );

      // Save user profile in Firestore
      if (firestore != null) {
        await firestore.collection('users').doc(user.uid).set(newUser.toMap());
      }

      _registeredUsers[normalizedEmail] = newUser;
      _registeredPasswords[normalizedEmail] = password;
      _currentUser = newUser;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _mapFirebaseAuthError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Registration error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Quick Demo Role Switcher for instant examiner testing
  void switchDemoRole(UserRole role) {
    _currentUser = demoUsers.firstWhere((u) => u.role == role);
    _errorMessage = null;
    notifyListeners();
  }

  /// Logout
  Future<void> logout() async {
    try {
      final auth = _firebaseAuth;
      if (auth != null) {
        await auth.signOut();
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    _currentUser = null;
    _errorMessage = null;
    _lastLoginTime = null;
    notifyListeners();
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email. Please register.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password or email. Please check your credentials.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}
