import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;

  const AdminDashboard({
    super.key,
    required this.user,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final List<Map<String, dynamic>> _shops = [
    {
      'name': 'GreenLeaf Fresh Mart',
      'owner': 'Sunil Weerasinghe',
      'location': 'Maharagama',
      'status': 'Verified',
      'pickups': 142,
    },
    {
      'name': 'Daily Superette',
      'owner': 'Anura Silva',
      'location': 'Nugegoda',
      'status': 'Verified',
      'pickups': 98,
    },
    {
      'name': 'Fresh Express Kandy',
      'owner': 'Mahesh Jayawardena',
      'location': 'Kandy Town',
      'status': 'Pending Approval',
      'pickups': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shield_rounded,
                  color: AppColors.roleAdmin,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'SYSTEM ADMIN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.roleAdmin,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'DashGrocer Platform',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: () => authService.logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Operational Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.roleAdminSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.roleAdmin.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.roleAdmin,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cloud_done_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Services Operational',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.roleAdmin,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Firebase Auth, Firestore sync & notifications active',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Key Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _AdminStatCard(
                  title: 'Total Users',
                  value: '1,280',
                  icon: Icons.people_alt_rounded,
                  color: AppColors.primary,
                ),
                _AdminStatCard(
                  title: 'Partner Shops',
                  value: '38',
                  icon: Icons.storefront_rounded,
                  color: AppColors.roleShopOwner,
                ),
                _AdminStatCard(
                  title: 'Today Pickups',
                  value: '142',
                  icon: Icons.shopping_basket_rounded,
                  color: AppColors.accentAmber,
                ),
                _AdminStatCard(
                  title: 'Avg. Readiness',
                  value: '18 min',
                  icon: Icons.timer_rounded,
                  color: AppColors.accentBlue,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Partner Shops Moderation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registered Grocery Stores',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_shops.length} Total',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._shops.map((shop) => _AdminShopTile(shop: shop)),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppColors.cardShadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminShopTile extends StatelessWidget {
  final Map<String, dynamic> shop;

  const _AdminShopTile({required this.shop});

  @override
  Widget build(BuildContext context) {
    final isVerified = shop['status'] == 'Verified';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppColors.cardShadowSubtle,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isVerified ? AppColors.primarySoft : AppColors.accentAmberSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: isVerified ? AppColors.primaryDark : AppColors.accentOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop['name'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${shop['owner']} • ${shop['location']}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isVerified ? AppColors.successSoft : AppColors.accentAmberSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              shop['status'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isVerified ? AppColors.success : AppColors.accentOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
