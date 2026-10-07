import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/grocery_service.dart';
import 'about_me_screen.dart';
import 'favorites_tab.dart';
import 'my_cards_screen.dart';
import 'notification_settings_screen.dart';
import 'order_history_screen.dart';

class ProfileTab extends StatelessWidget {
  final UserModel? user;

  const ProfileTab({
    super.key,
    this.user,
  });

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout from DashGrocer?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your customer account?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              authService.logout();
            },
            child: Text(
              'Logout',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final groceryService = GroceryService();
    final currentUser = user ?? authService.currentUser;

    final name = currentUser?.fullName.isNotEmpty == true ? currentUser!.fullName : 'Kasun Perera';
    final email = currentUser?.email.isNotEmpty == true ? currentUser!.email : 'kasun.perera@gmail.com';
    final initial = name[0].toUpperCase();

    return ListenableBuilder(
      listenable: groceryService,
      builder: (context, _) {
        final unread = groceryService.unreadCustomerNotificationsCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F5F9),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildAvatar(initial),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: 'About me',
                    onTap: () => _push(context, AboutMeScreen(user: currentUser)),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    label: 'My Orders',
                    onTap: () => _push(context, const OrderHistoryScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.favorite_border_rounded,
                    label: 'My Favorites',
                    onTap: () => _push(context, const FavoritesTab()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.credit_card_rounded,
                    label: 'My Cards',
                    onTap: () => _push(context, const MyCardsScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    badgeCount: unread,
                    onTap: () => _push(context, const NotificationSettingsScreen()),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout_rounded,
                    label: 'Sign out',
                    showChevron: false,
                    onTap: () => _showLogoutDialog(context, authService),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildAvatar(String initial) {
    return Stack(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F6EB), Color(0xFFD1FAE5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Center(
            child: Text(
              initial,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.brandGreenDark,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Icon(Icons.camera_alt_rounded, size: 11, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int badgeCount = 0,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.brandGreen),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFE5858),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            if (showChevron)
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
