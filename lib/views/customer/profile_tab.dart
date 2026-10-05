import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/seller_order_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/grocery_service.dart';
import 'order_history_screen.dart';
import 'track_order_screen.dart';

class ProfileTab extends StatefulWidget {
  final UserModel? user;

  const ProfileTab({
    super.key,
    this.user,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _pickupLocationController;

  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _obscureNewPass = true;
  bool _isSaving = false;
  bool _isPersonalDetailsExpanded = true;
  bool _isChangePassExpanded = false;
  bool _orderNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    final effectiveUser = widget.user ?? AuthService().currentUser;
    _nameController = TextEditingController(
      text: effectiveUser?.fullName.isNotEmpty == true ? effectiveUser!.fullName : 'Kasun Perera',
    );
    _emailController = TextEditingController(
      text: effectiveUser?.email.isNotEmpty == true ? effectiveUser!.email : 'kasun.perera@gmail.com',
    );
    _phoneController = TextEditingController(
      text: effectiveUser?.phoneNumber.isNotEmpty == true ? effectiveUser!.phoneNumber : '+94 77 123 4567',
    );
    _pickupLocationController = TextEditingController(
      text: 'GreenLeaf Fresh Mart - Colombo 03',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pickupLocationController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile details updated successfully!',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.brandGreenDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

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
    final currentUser = widget.user ?? authService.currentUser;

    // Retrieve user orders from GroceryService
    final allStoreOrders = groceryService.sellerOrders;
    List<StoreOrder> userOrders = allStoreOrders.where((o) {
      if (currentUser != null && currentUser.fullName.isNotEmpty) {
        return o.customerName.toLowerCase() == currentUser.fullName.toLowerCase() ||
               o.customerPhone == currentUser.phoneNumber;
      }
      return true;
    }).toList();

    // Fallback if none matched
    if (userOrders.isEmpty) {
      userOrders = allStoreOrders;
    }

    final activeOrders = userOrders.where((o) => o.status != 'Completed' && o.status != 'Cancelled').toList();
    final initial = (currentUser?.fullName.isNotEmpty == true)
        ? currentUser!.fullName[0].toUpperCase()
        : 'K';

    return ListenableBuilder(
      listenable: groceryService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFBFBFB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(
              'About me',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long_rounded, size: 21, color: Color(0xFF475569)),
                tooltip: 'Order History',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 21, color: Color(0xFFEF4444)),
                tooltip: 'Logout',
                onPressed: () => _showLogoutDialog(context, authService),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Customer Profile Identity Card
                _buildProfileIdentityCard(currentUser, initial),

                const SizedBox(height: 16),

                // 2. Customer Quick Stats Row (Total Orders, Active, Favorites, Points)
                _buildStatsRow(userOrders.length, activeOrders.length, groceryService.favoriteItems.length),

                const SizedBox(height: 22),

                // 3. Customer's Orders Section with Full Details
                _buildOrdersSection(context, userOrders),

                const SizedBox(height: 22),

                // 4. Customer Personal Details Card (Editable)
                _buildPersonalDetailsCard(),

                const SizedBox(height: 16),

                // 5. Account Preferences & Quick Links
                _buildPreferencesCard(),

                const SizedBox(height: 16),

                // 6. Change Password (Collapsible)
                _buildChangePasswordCard(),

                const SizedBox(height: 24),

                // 7. Save Settings Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveSettings,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Save settings',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // 8. Logout Button (Red)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _showLogoutDialog(context, authService),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // 1. Customer Profile Identity Card
  Widget _buildProfileIdentityCard(UserModel? user, String initial) {
    final name = _nameController.text.isNotEmpty ? _nameController.text : (user?.fullName ?? 'Kasun Perera');
    final email = _emailController.text.isNotEmpty ? _emailController.text : (user?.email ?? 'kasun.perera@gmail.com');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F6EB), Color(0xFFD1FAE5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandGreen.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandGreenDark,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.brandGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Name and Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F6EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 12, color: AppColors.brandGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Customer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandGreenDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Customer Quick Stats Row
  Widget _buildStatsRow(int totalOrders, int activeOrders, int favoritesCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Orders', '$totalOrders', Icons.receipt_long_rounded, AppColors.brandGreen),
          _buildVerticalDivider(),
          _buildStatItem('Active Pickups', '$activeOrders', Icons.schedule_rounded, const Color(0xFF0284C7)),
          _buildVerticalDivider(),
          _buildStatItem('Wishlist', '$favoritesCount', Icons.favorite_rounded, const Color(0xFFEF4444)),
          _buildVerticalDivider(),
          _buildStatItem('DashPoints', '450 pts', Icons.stars_rounded, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFE2E8F0),
    );
  }

  // 3. Customer's Orders Section with Full Details
  Widget _buildOrdersSection(BuildContext context, List<StoreOrder> userOrders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.brandGreen),
                const SizedBox(width: 8),
                Text(
                  'My Orders & Pickups',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
              },
              child: Text(
                'View All (${userOrders.length}) →',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandGreenDark,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        if (userOrders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 36, color: Color(0xFF94A3B8)),
                const SizedBox(height: 8),
                Text(
                  'No orders placed yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else
          ...userOrders.take(2).map((order) => _buildCustomerOrderCard(context, order)),
      ],
    );
  }

  // Individual Order Card with Full Details & Track Order button
  Widget _buildCustomerOrderCard(BuildContext context, StoreOrder order) {
    Color statusBgColor;
    Color statusTextColor;
    String displayStatus = order.status;

    if (order.status == 'Ready for Pickup') {
      statusBgColor = const Color(0xFFE8F6EB);
      statusTextColor = AppColors.brandGreenDark;
    } else if (order.status == 'Completed') {
      statusBgColor = const Color(0xFFF1F5F9);
      statusTextColor = const Color(0xFF64748B);
    } else {
      statusBgColor = const Color(0xFFE0F2FE);
      statusTextColor = const Color(0xFF0284C7);
      displayStatus = 'Preparing';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF475569)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.id,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayStatus.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Items Summary
          Row(
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.itemsSummary,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Pickup slot & Store
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${order.pickupSlot} • ${order.shopName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Amount and Action Button Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    order.formattedTotal,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackOrderScreen(orderId: order.id),
                    ),
                  );
                },
                icon: const Icon(Icons.location_on_outlined, size: 16),
                label: Text(
                  'Track Order',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Customer Personal Details Card (Editable)
  Widget _buildPersonalDetailsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Expand/Collapse toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _isPersonalDetailsExpanded = !_isPersonalDetailsExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.brandGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Personal Details',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Icon(
                  _isPersonalDetailsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),

          if (_isPersonalDetailsExpanded) ...[
            const SizedBox(height: 14),

            // Name Field
            _buildProfileField(
              controller: _nameController,
              icon: Icons.person_outline_rounded,
              hint: 'Full Name',
            ),
            const SizedBox(height: 10),

            // Email Field
            _buildProfileField(
              controller: _emailController,
              icon: Icons.mail_outline_rounded,
              hint: 'Email Address',
            ),
            const SizedBox(height: 10),

            // Phone Field
            _buildProfileField(
              controller: _phoneController,
              icon: Icons.phone_outlined,
              hint: 'Phone Number',
            ),
            const SizedBox(height: 10),

            // Default Pickup Store Field
            _buildProfileField(
              controller: _pickupLocationController,
              icon: Icons.store_outlined,
              hint: 'Preferred Store Location',
            ),
          ],
        ],
      ),
    );
  }

  // 5. Account Preferences & Quick Links
  Widget _buildPreferencesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          // Order Notifications Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_outlined, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  Text(
                    'Order Pickup Alerts',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Switch(
                value: _orderNotificationsEnabled,
                activeThumbColor: AppColors.brandGreen,
                onChanged: (val) {
                  setState(() => _orderNotificationsEnabled = val);
                },
              ),
            ],
          ),

          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // Payment Methods
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment Methods: Cash on Pickup, Visa & Mastercard enabled', style: GoogleFonts.plusJakartaSans()),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.payment_rounded, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment & Checkout Methods',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Change Password (Collapsible)
  Widget _buildChangePasswordCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isChangePassExpanded = !_isChangePassExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(
                      'Change Password',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Icon(
                  _isChangePassExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),

          if (_isChangePassExpanded) ...[
            const SizedBox(height: 14),

            _buildProfileField(
              controller: _currentPassController,
              icon: Icons.lock_outline_rounded,
              hint: 'Current password',
              obscureText: true,
            ),
            const SizedBox(height: 10),

            _buildProfileField(
              controller: _newPassController,
              icon: Icons.lock_outline_rounded,
              hint: 'New password',
              obscureText: _obscureNewPass,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: const Color(0xFF94A3B8),
                ),
                onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
              ),
            ),
            const SizedBox(height: 10),

            _buildProfileField(
              controller: _confirmPassController,
              icon: Icons.lock_outline_rounded,
              hint: 'Confirm new password',
              obscureText: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
