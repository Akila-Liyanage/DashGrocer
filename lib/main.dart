import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'package:dashgrocer/models/user_model.dart';
import 'services/auth_service.dart';
import 'services/database_seeder.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/auth/auth_screen.dart';
import 'views/customer/customer_dashboard.dart';
import 'views/shop_owner/shop_owner_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Never let a slow/blocked Firebase init keep the app on a blank screen
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    // Seed initial Firestore catalog and demo users if needed (runs in background)
    DatabaseSeeder.seedInitialDataIfNeeded().catchError((Object e) {
      debugPrint('Database seeding notice: $e');
    });
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const DashGrocerApp());
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
