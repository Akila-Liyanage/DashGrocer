import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'package:dashgrocer/models/user_model.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/grocery_service.dart';
import 'services/database_seeder.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/auth/auth_screen.dart';
import 'views/customer/customer_dashboard.dart';
import 'views/shop_owner/shop_owner_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Launch the Flutter UI immediately so Android renders frames instantly.
  // This completely eliminates frame skips, ANR watchdog timeouts, and Signal 3 crashes.
  runApp(const DashGrocerApp());

  // Initialize Firebase in background without blocking the UI thread
  unawaited(_initFirebaseSafely());
}

Future<void> _initFirebaseSafely() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    // Connect live Firestore listeners across services once Firebase is ready
    AuthService().initFirebaseListeners();
    GroceryService().initFirebaseListeners();
    ChatService().initFirebaseListeners();

    // Background seed initial catalog and users if empty
    DatabaseSeeder.seedInitialDataIfNeeded().catchError((Object e) {
      debugPrint('[DatabaseSeeder] Seeding notice: $e');
    });
  } catch (e) {
    debugPrint('[Firebase] Initialization notice: $e');
  }
}

class DashGrocerApp extends StatelessWidget {
  const DashGrocerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DashGrocer - Local Grocery Pre-order & Pickup',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthRoleWrapper(),
    );
  }
}

/// Role-Based Access Control (RBAC) Router & Guard
class AuthRoleWrapper extends StatelessWidget {
  const AuthRoleWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        final currentUser = authService.currentUser;

        // Smooth Page Transition between Auth and Dashboards
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildRoleDestination(currentUser),
        );
      },
    );
  }

  Widget _buildRoleDestination(UserModel? user) {
    if (user == null) {
      return const AuthScreen(key: ValueKey('unauthenticated_auth_screen'));
    }

    switch (user.role) {
      case UserRole.customer:
        return CustomerDashboard(
          key: ValueKey('customer_dashboard_${user.id}'),
          user: user,
        );
      case UserRole.shopOwner:
        return ShopOwnerHome(
          key: ValueKey('shop_owner_dashboard_${user.id}'),
          user: user,
        );
      case UserRole.admin:
        return AdminDashboard(
          key: ValueKey('admin_dashboard_${user.id}'),
          user: user,
        );
    }
  }
}
