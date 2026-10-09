import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dashgrocer/models/user_model.dart';
import 'package:dashgrocer/models/shop_profile.dart';
import 'database_seeder.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initAuthState();
    _initDefaultShops();
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
      shopStatus: 'approved',
    ),
    const UserModel(
      id: 'owner_02',
      email: 'owner@dashgrocer.com',
      fullName: 'Sunil Weerasinghe',
      phoneNumber: '+94 71 987 6543',
      role: UserRole.shopOwner,
      shopName: 'GreenLeaf Fresh Mart',
      shopAddress: 'No. 42, High Level Road, Maharagama',
      shopStatus: 'approved',
    ),
    const UserModel(
      id: 'owner_kandy',
      email: 'kandyfresh@dashgrocer.com',
      fullName: 'Mahesh Jayawardena',
      phoneNumber: '+94 81 234 5678',
      role: UserRole.shopOwner,
      shopName: 'Fresh Express Kandy',
      shopAddress: 'No. 12, Dalada Veediya, Kandy',
      shopStatus: 'pending',
    ),
    const UserModel(
      id: 'owner_sunrise',
      email: 'sunrise@dashgrocer.com',
      fullName: 'Anura Wickramasinghe',
      phoneNumber: '+94 11 456 7890',
      role: UserRole.shopOwner,
      shopName: 'Sunrise Organics',
      shopAddress: 'No. 88, Galle Road, Colombo 03',
      shopStatus: 'approved',
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
  final Map<String, ShopProfile> _registeredShops = {};

  void _initDefaultShops() {
    _registeredShops['owner_01'] = const ShopProfile(
      id: 'owner_01',
      name: 'GreenLeaf Fresh Mart',
      address: 'No. 42, High Level Road, Maharagama',
      phone: '+94 71 987 6543',
      status: 'approved',
      ownerName: 'Sunil Weerasinghe',
      ownerEmail: 'seller@dashgrocer.com',
    );
    _registeredShops['owner_02'] = const ShopProfile(
      id: 'owner_02',
      name: 'GreenLeaf Fresh Mart',
      address: 'No. 42, High Level Road, Maharagama',
      phone: '+94 71 987 6543',
      status: 'approved',
      ownerName: 'Sunil Weerasinghe',
      ownerEmail: 'owner@dashgrocer.com',
    );
    _registeredShops['shop_dailysuperette'] = const ShopProfile(
      id: 'shop_dailysuperette',
      name: 'Daily Superette',
      address: 'No. 18, Station Road, Maharagama',
      phone: '+94 77 234 5678',
      status: 'approved',
      ownerName: 'Kamal Perera',
      ownerEmail: 'kamal@dashgrocer.com',
    );
    _registeredShops['owner_kandy'] = const ShopProfile(
      id: 'owner_kandy',
      name: 'Fresh Express Kandy',
      address: 'No. 12, Dalada Veediya, Kandy',
      phone: '+94 81 234 5678',
      status: 'pending',
      ownerName: 'Mahesh Jayawardena',
      ownerEmail: 'kandyfresh@dashgrocer.com',
    );
    _registeredShops['owner_sunrise'] = const ShopProfile(
      id: 'owner_sunrise',
      name: 'Sunrise Organics',
      address: 'No. 88, Galle Road, Colombo 03',
      phone: '+94 11 456 7890',
      status: 'approved',
      ownerName: 'Anura Wickramasinghe',
      ownerEmail: 'sunrise@dashgrocer.com',
    );
  }

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
          if (_registeredPasswords[normalizedEmail] == password ||
              (_registeredPasswords[normalizedEmail] == null && _isValidDemoPassword(password))) {
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
        if (_registeredPasswords[normalizedEmail] == password ||
            (_registeredPasswords[normalizedEmail] == null && _isValidDemoPassword(password))) {
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
      if (demoMatch.isNotEmpty &&
          (_registeredPasswords[normalizedEmail] == password ||
              (_registeredPasswords[normalizedEmail] == null && _isValidDemoPassword(password)))) {
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

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        _errorMessage = 'Google sign-in was cancelled.';
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final auth = _firebaseAuth;
      if (auth == null) {
        _isLoading = false;
        _errorMessage = 'Firebase Auth not available.';
        notifyListeners();
        return false;
      }

      final UserCredential userCredential = await auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _loadUserProfile(user.uid, fallbackEmail: user.email);
        _lastLoginTime = DateTime.now();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Failed to sign in with Google.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Google sign-in failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
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
          shopStatus: role == UserRole.shopOwner ? 'pending' : null,
          createdAt: DateTime.now(),
        );

        if (role == UserRole.shopOwner) {
          final newShop = ShopProfile(
            id: newUser.id,
            name: shopName?.trim() ?? 'My Grocery Shop',
            address: shopAddress?.trim() ?? '',
            phone: phoneNumber.trim(),
            status: 'pending',
            ownerName: fullName.trim(),
            ownerEmail: normalizedEmail,
            createdAt: DateTime.now(),
          );
          _registeredShops[newUser.id] = newShop;
        }

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
        shopStatus: role == UserRole.shopOwner ? 'pending' : null,
        createdAt: DateTime.now(),
      );

      ShopProfile? newShop;
      if (role == UserRole.shopOwner) {
        newShop = ShopProfile(
          id: user.uid,
          name: shopName?.trim() ?? 'My Grocery Shop',
          address: shopAddress?.trim() ?? '',
          phone: phoneNumber.trim(),
          status: 'pending',
          ownerName: fullName.trim(),
          ownerEmail: normalizedEmail,
          createdAt: DateTime.now(),
        );
        _registeredShops[user.uid] = newShop;
      }

      // Save user profile and shop in Firestore
      if (firestore != null) {
        await firestore.collection('users').doc(user.uid).set(newUser.toMap());
        if (newShop != null) {
          await firestore.collection('shops').doc(user.uid).set(newShop.toMap());
        }
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

  /// Update the signed-in user's password in Firebase Authentication.
  /// Passwords are credentials and must not be stored in Firestore.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _errorMessage = null;
    final normalizedEmail = _currentUser?.email.trim().toLowerCase();

    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      _errorMessage = 'Please sign in again before changing your password.';
      notifyListeners();
      return false;
    }
    if (newPassword.length < 6) {
      _errorMessage = 'The new password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    try {
      final firebaseUser = _firebaseAuth?.currentUser;
      if (firebaseUser != null) {
        final email = firebaseUser.email;
        if (email == null || email.isEmpty) {
          _errorMessage = 'This account cannot change its password here.';
          notifyListeners();
          return false;
        }

        final credential = EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        );
        await firebaseUser.reauthenticateWithCredential(credential);
        await firebaseUser.updatePassword(newPassword);
      } else {
        final storedPassword = _registeredPasswords[normalizedEmail];
        final isDemoAccount = demoUsers.any((user) => user.email.toLowerCase() == normalizedEmail);
        final currentPasswordMatches = storedPassword != null
            ? storedPassword == currentPassword
            : isDemoAccount && _isValidDemoPassword(currentPassword);

        if (!currentPasswordMatches) {
          _errorMessage = 'Current password is incorrect.';
          notifyListeners();
          return false;
        }
        _registeredPasswords[normalizedEmail] = newPassword;
      }

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Could not update password: ${e.toString()}';
      notifyListeners();
      return false;
    }
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

  // =============================================================
  // ADMIN & DATABASE MANAGEMENT
  // =============================================================

  /// Watch all registered accounts from Firestore & local registry
  Stream<List<UserModel>> watchAllUsers() {
    final firestore = _firestore;
    if (firestore != null) {
      return firestore.collection('users').snapshots().map((snapshot) {
        final Map<String, UserModel> merged = {};
        for (final u in demoUsers) {
          merged[u.id] = u;
        }
        for (final u in _registeredUsers.values) {
          merged[u.id] = u;
        }
        for (final doc in snapshot.docs) {
          final u = UserModel.fromMap(doc.data(), doc.id);
          merged[u.id] = u;
        }
        final list = merged.values.toList();
        list.sort((a, b) {
          if (a.createdAt != null && b.createdAt != null) {
            return b.createdAt!.compareTo(a.createdAt!);
          }
          return a.fullName.compareTo(b.fullName);
        });
        return list;
      });
    }

    // Local / Offline Stream
    late StreamController<List<UserModel>> controller;
    void emit() {
      if (!controller.isClosed) {
        final Map<String, UserModel> merged = {};
        for (final u in demoUsers) {
          merged[u.id] = u;
        }
        for (final u in _registeredUsers.values) {
          merged[u.id] = u;
        }
        final list = merged.values.toList();
        list.sort((a, b) {
          if (a.createdAt != null && b.createdAt != null) {
            return b.createdAt!.compareTo(a.createdAt!);
          }
          return a.fullName.compareTo(b.fullName);
        });
        controller.add(list);
      }
    }

    controller = StreamController<List<UserModel>>(
      onListen: () {
        emit();
        addListener(emit);
      },
      onCancel: () {
        removeListener(emit);
      },
    );
    return controller.stream;
  }

  /// Watch all registered grocery shops from Firestore & local registry
  Stream<List<ShopProfile>> watchAllShops() {
    final firestore = _firestore;
    if (firestore != null) {
      return firestore.collection('shops').snapshots().map((snapshot) {
        final Map<String, ShopProfile> merged = Map.from(_registeredShops);
        for (final doc in snapshot.docs) {
          final s = ShopProfile.fromMap(doc.id, doc.data());
          merged[s.id] = s;
        }
        final list = merged.values.toList();
        list.sort((a, b) {
          // Put pending approvals first
          if (a.isPending && !b.isPending) return -1;
          if (!a.isPending && b.isPending) return 1;
          return a.name.compareTo(b.name);
        });
        return list;
      });
    }

    // Local / Offline Stream
    late StreamController<List<ShopProfile>> controller;
    void emit() {
      if (!controller.isClosed) {
        final list = _registeredShops.values.toList();
        list.sort((a, b) {
          if (a.isPending && !b.isPending) return -1;
          if (!a.isPending && b.isPending) return 1;
          return a.name.compareTo(b.name);
        });
        controller.add(list);
      }
    }

    controller = StreamController<List<ShopProfile>>(
      onListen: () {
        emit();
        addListener(emit);
      },
      onCancel: () {
        removeListener(emit);
      },
    );
    return controller.stream;
  }

  /// Admin approves a registered shop so it can be listed and sell to customers
  Future<void> approveShop(String shopId, {String? userId}) async {
    final effectiveUserId = userId ?? shopId;

    // 1. Update in-memory shop
    if (_registeredShops.containsKey(shopId)) {
      _registeredShops[shopId] = _registeredShops[shopId]!.copyWith(
        status: 'approved',
        rejectionReason: '',
      );
    } else {
      _registeredShops[shopId] = ShopProfile(
        id: shopId,
        name: 'Grocery Shop',
        status: 'approved',
      );
    }

    // 2. Update in-memory user
    for (final entry in _registeredUsers.entries) {
      if (entry.value.id == effectiveUserId || entry.value.shopName == _registeredShops[shopId]?.name) {
        _registeredUsers[entry.key] = entry.value.copyWith(
          shopStatus: 'approved',
          rejectionReason: '',
        );
      }
    }
    for (int i = 0; i < demoUsers.length; i++) {
      if (demoUsers[i].id == effectiveUserId) {
        demoUsers[i] = demoUsers[i].copyWith(
          shopStatus: 'approved',
          rejectionReason: '',
        );
      }
    }

    if (_currentUser != null && _currentUser!.id == effectiveUserId) {
      _currentUser = _currentUser!.copyWith(
        shopStatus: 'approved',
        rejectionReason: '',
      );
    }

    // 3. Update Cloud Firestore
    try {
      final firestore = _firestore;
      if (firestore != null) {
        final batch = firestore.batch();
        batch.set(
          firestore.collection('shops').doc(shopId),
          {
            'status': 'approved',
            'rejectionReason': '',
            'approvedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        batch.set(
          firestore.collection('users').doc(effectiveUserId),
          {
            'shopStatus': 'approved',
            'rejectionReason': '',
          },
          SetOptions(merge: true),
        );
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error updating approval in Firestore: $e');
    }

    notifyListeners();
  }

  /// Admin rejects a shop registration with a specified reason
  Future<void> rejectShop(String shopId, {String? userId, required String reason}) async {
    final effectiveUserId = userId ?? shopId;

    // 1. Update in-memory shop
    if (_registeredShops.containsKey(shopId)) {
      _registeredShops[shopId] = _registeredShops[shopId]!.copyWith(
        status: 'rejected',
        rejectionReason: reason,
      );
    }

    // 2. Update in-memory user
    for (final entry in _registeredUsers.entries) {
      if (entry.value.id == effectiveUserId || entry.value.shopName == _registeredShops[shopId]?.name) {
        _registeredUsers[entry.key] = entry.value.copyWith(
          shopStatus: 'rejected',
          rejectionReason: reason,
        );
      }
    }
    for (int i = 0; i < demoUsers.length; i++) {
      if (demoUsers[i].id == effectiveUserId) {
        demoUsers[i] = demoUsers[i].copyWith(
          shopStatus: 'rejected',
          rejectionReason: reason,
        );
      }
    }

    if (_currentUser != null && _currentUser!.id == effectiveUserId) {
      _currentUser = _currentUser!.copyWith(
        shopStatus: 'rejected',
        rejectionReason: reason,
      );
    }

    // 3. Update Cloud Firestore
    try {
      final firestore = _firestore;
      if (firestore != null) {
        final batch = firestore.batch();
        batch.set(
          firestore.collection('shops').doc(shopId),
          {
            'status': 'rejected',
            'rejectionReason': reason,
            'rejectedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        batch.set(
          firestore.collection('users').doc(effectiveUserId),
          {
            'shopStatus': 'rejected',
            'rejectionReason': reason,
          },
          SetOptions(merge: true),
        );
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error updating rejection in Firestore: $e');
    }

    notifyListeners();
  }

  /// Admin suspends an approved shop
  Future<void> suspendShop(String shopId, {String? userId}) async {
    final effectiveUserId = userId ?? shopId;

    if (_registeredShops.containsKey(shopId)) {
      _registeredShops[shopId] = _registeredShops[shopId]!.copyWith(
        status: 'pending',
      );
    }

    for (final entry in _registeredUsers.entries) {
      if (entry.value.id == effectiveUserId) {
        _registeredUsers[entry.key] = entry.value.copyWith(
          shopStatus: 'pending',
        );
      }
    }
    for (int i = 0; i < demoUsers.length; i++) {
      if (demoUsers[i].id == effectiveUserId) {
        demoUsers[i] = demoUsers[i].copyWith(
          shopStatus: 'pending',
        );
      }
    }

    if (_currentUser != null && _currentUser!.id == effectiveUserId) {
      _currentUser = _currentUser!.copyWith(
        shopStatus: 'pending',
      );
    }

    try {
      final firestore = _firestore;
      if (firestore != null) {
        final batch = firestore.batch();
        batch.set(
          firestore.collection('shops').doc(shopId),
          {'status': 'pending'},
          SetOptions(merge: true),
        );
        batch.set(
          firestore.collection('users').doc(effectiveUserId),
          {'shopStatus': 'pending'},
          SetOptions(merge: true),
        );
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error suspending shop in Firestore: $e');
    }

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
