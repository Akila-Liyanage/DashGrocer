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

  static Duration simulatedDelay = const Duration(milliseconds: 700);

  void _initAuthState() {
    final auth = _firebaseAuth;
    if (auth == null) return;
    auth.authStateChanges().listen((User? user) async {
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

  /// Login with email and password using Firebase Auth
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final normalizedEmail = email.trim().toLowerCase();
    final demoMatch = demoUsers.where((u) => u.email.toLowerCase() == normalizedEmail);

    try {
      final auth = _firebaseAuth;
      if (auth == null) {
        if (demoMatch.isNotEmpty && (password == 'pass123' || password == 'Password123!' || password.length >= 6)) {
          _currentUser = demoMatch.first;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        }
        _currentUser = UserModel(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: normalizedEmail,
          fullName: normalizedEmail.split('@').first,
          phoneNumber: '',
          role: normalizedEmail.contains('owner') || normalizedEmail.contains('seller')
              ? UserRole.shopOwner
              : UserRole.customer,
        );
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      final credential = await auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await _loadUserProfile(user.uid, fallbackEmail: user.email);
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      // If user not found, try auto-provisioning seed credentials in Firebase Auth
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        final cred = await DatabaseSeeder.provisionSeedUserAuth(normalizedEmail, password);
        if (cred?.user != null) {
          await _loadUserProfile(cred!.user!.uid, fallbackEmail: cred.user!.email);
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        }
      }

      // Allow demo user login fallback for quick testing
      if (demoMatch.isNotEmpty && (password == 'pass123' || password == 'Password123!' || password.length >= 6)) {
        _currentUser = demoMatch.first;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = _mapFirebaseAuthError(e);
      notifyListeners();
      return false;
    } catch (e) {
      if (demoMatch.isNotEmpty && (password == 'pass123' || password == 'Password123!' || password.length >= 6)) {
        _currentUser = demoMatch.first;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Login failed: ${e.toString()}';
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
