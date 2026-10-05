import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:dashgrocer/models/user_model.dart';
import 'grocery_service.dart';

class DatabaseSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String seedPassword = 'Password123!';

  // Standard Seed Accounts
  static final List<Map<String, dynamic>> seedUsers = [
    {
      'email': 'customer@dashgrocer.com',
      'password': seedPassword,
      'fullName': 'Kasun Perera',
      'phoneNumber': '+94 77 123 4567',
      'role': 'customer',
    },
    {
      'email': 'seller@dashgrocer.com',
      'password': seedPassword,
      'fullName': 'Sunil Weerasinghe',
      'phoneNumber': '+94 71 987 6543',
      'role': 'shopOwner',
      'shopName': 'GreenLeaf Fresh Mart',
      'shopAddress': 'No. 42, High Level Road, Maharagama',
    },
    {
      'email': 'owner@dashgrocer.com',
      'password': seedPassword,
      'fullName': 'Sunil Weerasinghe',
      'phoneNumber': '+94 71 987 6543',
      'role': 'shopOwner',
      'shopName': 'GreenLeaf Fresh Mart',
      'shopAddress': 'No. 42, High Level Road, Maharagama',
    },
    {
      'email': 'admin@dashgrocer.com',
      'password': seedPassword,
      'fullName': 'System Administrator',
      'phoneNumber': '+94 11 234 5678',
      'role': 'admin',
    },
  ];

  /// Initialize and seed default Firestore collections if not yet present
  static Future<void> seedInitialDataIfNeeded() async {
    try {
      // 1. Seed Categories & Products to Firestore
      final productsSnapshot = await _firestore.collection('products').limit(1).get();
      if (productsSnapshot.docs.isEmpty) {
        debugPrint('[DatabaseSeeder] Seeding initial grocery products to Firestore...');
        await seedProducts();
      }

      // 2. Provision seed accounts in Firestore
      for (final seed in seedUsers) {
        final email = seed['email'] as String;
        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          final docRef = _firestore.collection('users').doc();
          final userModel = UserModel(
            id: docRef.id,
            email: email,
            fullName: seed['fullName'] as String,
            phoneNumber: seed['phoneNumber'] as String,
            role: seed['role'] == 'shopOwner'
                ? UserRole.shopOwner
                : (seed['role'] == 'admin' ? UserRole.admin : UserRole.customer),
            shopName: seed['shopName'] as String?,
            shopAddress: seed['shopAddress'] as String?,
          );
          await docRef.set(userModel.toMap());
          debugPrint('[DatabaseSeeder] Seed user created in Firestore: $email (${seed['role']})');
        }
      }
    } catch (e) {
      debugPrint('[DatabaseSeeder] Notice during auto-seeding: $e');
    }
  }

  /// Provision a seed user directly in Firebase Authentication and Firestore on-the-fly
  static Future<UserCredential?> provisionSeedUserAuth(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final seed = seedUsers.firstWhere(
      (s) => (s['email'] as String).toLowerCase() == normalized,
      orElse: () => {},
    );

    if (seed.isEmpty) return null;

    try {
      debugPrint('[DatabaseSeeder] Auto-provisioning Firebase Auth user: $normalized');
      final cred = await _auth.createUserWithEmailAndPassword(
        email: normalized,
        password: password.length >= 6 ? password : seedPassword,
      );

      final user = cred.user;
      if (user != null) {
        final role = seed['role'] == 'shopOwner'
            ? UserRole.shopOwner
            : (seed['role'] == 'admin' ? UserRole.admin : UserRole.customer);

        final userModel = UserModel(
          id: user.uid,
          email: normalized,
          fullName: seed['fullName'] as String,
          phoneNumber: seed['phoneNumber'] as String,
          role: role,
          shopName: seed['shopName'] as String?,
          shopAddress: seed['shopAddress'] as String?,
        );

        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
        return cred;
      }
    } catch (e) {
      debugPrint('[DatabaseSeeder] Provision error: $e');
    }
    return null;
  }

  /// Seed the complete product catalog into Cloud Firestore
  static Future<void> seedProducts() async {
    final groceryService = GroceryService();
    final batch = _firestore.batch();

    for (final item in groceryService.allItems) {
      final doc = _firestore.collection('products').doc(item.id);
      batch.set(doc, {
        'id': item.id,
        'name': item.name,
        'unit': item.unit,
        'price': item.price,
        'originalPrice': item.originalPrice,
        'discountPercent': item.discountPercent,
        'category': item.category,
        'rating': item.rating,
        'reviewsCount': item.reviewsCount,
        'description': item.description,
        'imageUrl': item.imageUrl,
        'isNew': item.isNew,
        'isFavorite': item.isFavorite,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    debugPrint('[DatabaseSeeder] Successfully seeded ${groceryService.allItems.length} products to Firestore!');
  }
}
