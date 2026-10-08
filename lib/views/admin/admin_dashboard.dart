import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/shop_profile.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../models/grocery_item_model.dart';
import '../../services/grocery_service.dart';
import '../../models/seller_order_model.dart';
import '../common/app_image_view.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;

  const AdminDashboard({
    super.key,
    required this.user,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _salesSearchController = TextEditingController();
  final AuthService _authService = AuthService();

  StreamSubscription<List<UserModel>>? _usersSub;
  StreamSubscription<List<ShopProfile>>? _shopsSub;

  List<UserModel> _users = [];
  List<ShopProfile> _shops = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _shopFilter = 'All'; // 'All', 'Pending', 'Approved', 'Rejected'

  // Sales Filters & Search
  String _salesTimeRange = 'All Time'; // 'Today', '7 Days', '30 Days', 'All Time'
  String _salesStatusFilter = 'All'; // 'All', 'Completed', 'Ready for Pickup', 'Pending', 'Cancelled'
  String _salesShopFilter = 'All'; // 'All' or specific shop name
  String _salesSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    _salesSearchController.addListener(() {
      setState(() {
        _salesSearchQuery = _salesSearchController.text.trim().toLowerCase();
      });
    });

    GroceryService().addListener(_onGroceryServiceChange);

    _subscribeToDatabase();
  }

  void _onGroceryServiceChange() {
    if (mounted) setState(() {});
  }

  void _subscribeToDatabase() {
    setState(() => _isLoading = true);

    _usersSub?.cancel();
    _usersSub = _authService.watchAllUsers().listen((usersList) {
      if (mounted) {
        setState(() {
          _users = usersList;
          _isLoading = false;
        });
      }
    }, onError: (err) {
      debugPrint('Error reading users stream: $err');
      if (mounted) setState(() => _isLoading = false);
    });

    _shopsSub?.cancel();
    _shopsSub = _authService.watchAllShops().listen((shopsList) {
      if (mounted) {
        setState(() {
          _shops = shopsList;
          _isLoading = false;
        });
      }
    }, onError: (err) {
      debugPrint('Error reading shops stream: $err');
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _salesSearchController.dispose();
    GroceryService().removeListener(_onGroceryServiceChange);
    _usersSub?.cancel();
    _shopsSub?.cancel();
    super.dispose();
  }

  // Orders and Sales Analytics Getters
  List<StoreOrder> get _allOrders => GroceryService().sellerOrders;

  List<StoreOrder> get _filteredSalesOrders {
    final now = DateTime.now();
    return _allOrders.where((order) {
      // 1. Time Range Filter
      if (_salesTimeRange == 'Today') {
        final isToday = order.createdAt.year == now.year &&
            order.createdAt.month == now.month &&
            order.createdAt.day == now.day;
        if (!isToday) return false;
      } else if (_salesTimeRange == '7 Days') {
        final start = now.subtract(const Duration(days: 7));
        if (order.createdAt.isBefore(start)) return false;
      } else if (_salesTimeRange == '30 Days') {
        final start = now.subtract(const Duration(days: 30));
        if (order.createdAt.isBefore(start)) return false;
      }

      // 2. Status Filter
      if (_salesStatusFilter != 'All' && order.status != _salesStatusFilter) {
        return false;
      }

      // 3. Shop Filter
      if (_salesShopFilter != 'All' &&
          order.shopName.toLowerCase() != _salesShopFilter.toLowerCase()) {
        return false;
      }

      // 4. Search Filter
      if (_salesSearchQuery.isNotEmpty) {
        final matchesId = order.id.toLowerCase().contains(_salesSearchQuery);
        final matchesCust = order.customerName.toLowerCase().contains(_salesSearchQuery);
        final matchesPhone = order.customerPhone.toLowerCase().contains(_salesSearchQuery);
        final matchesShop = order.shopName.toLowerCase().contains(_salesSearchQuery);
        final matchesItems = order.itemsSummary.toLowerCase().contains(_salesSearchQuery);
        if (!matchesId && !matchesCust && !matchesPhone && !matchesShop && !matchesItems) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  double get _totalPlatformRevenue {
    return _allOrders.fold<double>(0.0, (sum, o) {
      if (o.status == 'Cancelled') return sum;
      return sum + o.totalAmount;
    });
  }

  int get _completedOrdersCount {
    return _allOrders.where((o) => o.status == 'Completed').length;
  }

  int get _activeOrdersCount {
    return _allOrders.where((o) => o.status == 'Pending' || o.status == 'Ready for Pickup').length;
  }

  Map<String, double> get _shopRevenueMap {
    final map = <String, double>{};
    for (final order in _allOrders) {
      if (order.status != 'Cancelled') {
        map[order.shopName] = (map[order.shopName] ?? 0) + order.totalAmount;
      }
    }
    return map;
  }

  // Filtered Lists
  List<UserModel> get _customers {
    return _users.where((u) {
      final matchesRole = u.isCustomer;
      if (!matchesRole) return false;
      if (_searchQuery.isEmpty) return true;
      return u.fullName.toLowerCase().contains(_searchQuery) ||
          u.email.toLowerCase().contains(_searchQuery) ||
          u.phoneNumber.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<UserModel> get _shopOwners {
    return _users.where((u) {
      final matchesRole = u.isShopOwner;
      if (!matchesRole) return false;
      if (_searchQuery.isEmpty) return true;
      return u.fullName.toLowerCase().contains(_searchQuery) ||
          u.email.toLowerCase().contains(_searchQuery) ||
          (u.shopName ?? '').toLowerCase().contains(_searchQuery) ||
          u.phoneNumber.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<ShopProfile> get _filteredShops {
    return _shops.where((s) {
      if (_shopFilter == 'Pending' && !s.isPending) return false;
      if (_shopFilter == 'Approved' && !s.isApproved) return false;
      if (_shopFilter == 'Rejected' && !s.isRejected) return false;

      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery) ||
          s.ownerName.toLowerCase().contains(_searchQuery) ||
          s.address.toLowerCase().contains(_searchQuery) ||
          s.phone.toLowerCase().contains(_searchQuery) ||
          s.ownerEmail.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<ShopProfile> get _pendingShops => _shops.where((s) => s.isPending).toList();

  Future<void> _approveShop(ShopProfile shop) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _authService.approveShop(shop.id, userId: shop.id);
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Approved: "${shop.name}" is now listed and active!',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.brandGreenDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to approve shop: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _promptRejectShop(ShopProfile shop) async {
    final reasonController = TextEditingController();
    final reasons = [
      'Incomplete pickup location / address',
      'Invalid business registration or contact info',
      'Duplicate shop registration',
      'Unable to reach shop owner by phone',
    ];
    String selectedPreset = reasons.first;

    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reject Registration',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to reject "${shop.name}"? Please provide a reason to inform the shop owner.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'REASON',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPreset,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                      ),
                    ),
                    items: reasons
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedPreset = val;
                          reasonController.text = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Additional Notes',
                      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                      hintText: selectedPreset,
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel_rounded, color: Colors.white, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                label: Text(
                  'Confirm Rejection',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (shouldReject == true && mounted) {
      final finalReason = reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : selectedPreset;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await _authService.rejectShop(shop.id, userId: shop.id, reason: finalReason);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Registration for "${shop.name}" has been rejected.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  List<GroceryItem> _getShopItems(ShopProfile shop) {
    return GroceryService().getItemsForShop(
      shopId: shop.id,
      shopName: shop.name,
      ownerName: shop.ownerName,
      ownerEmail: shop.ownerEmail,
    );
  }

  void _showShopDetailsSheet(ShopProfile shop, {int initialTab = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _AdminShopDetailsAndItemsSheet(
          shop: shop,
          initialTab: initialTab,
          onApprove: () async {
            Navigator.pop(ctx);
            await _approveShop(shop);
          },
          onReject: () async {
            Navigator.pop(ctx);
            await _promptRejectShop(shop);
          },
          onSuspend: () async {
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(ctx);
            await _authService.suspendShop(shop.id, userId: shop.id);
            messenger.showSnackBar(
              SnackBar(
                content: Text('Shop "${shop.name}" suspended.'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ─── Header Banner Extending into Notification/Status Bar ───
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2D7A0A), Color(0xFF539C14), Color(0xFF6CC51D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Shield badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_rounded, color: Colors.white, size: 13),
                                const SizedBox(width: 5),
                                Text(
                                  'ADMIN CONSOLE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Live badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4ADE80),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'LIVE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Pending notifications bell
                          if (_pendingShops.isNotEmpty) ...[
                            GestureDetector(
                              onTap: () => _tabController.animateTo(2),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.notifications_rounded, color: Colors.white, size: 18),
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(3.5),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${_pendingShops.length}',
                                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Log Out button
                          GestureDetector(
                            onTap: () => _authService.logout(),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'DashGrocer Platform',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Manage shops, monitor users & moderate registrations',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Separated TabBar ───
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF539C14), Color(0xFF6CC51D)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandGreen.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12.5),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  tabs: [
                    _buildTab('Overview', Icons.dashboard_rounded, _pendingShops.isNotEmpty ? '${_pendingShops.length}' : null),
                    _buildTab('Sales', Icons.analytics_rounded, '${_allOrders.length}'),
                    _buildTab('Shops', Icons.storefront_rounded, '${_shops.length}'),
                    _buildTab('Customers', Icons.people_rounded, '${_customers.length}'),
                    _buildTab('Owners', Icons.business_center_rounded, '${_shopOwners.length}'),
                  ],
                ),
              ),
            ),

            // ─── Tab Content Body ───
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.brandGreen,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Syncing with Firestore...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.brandGreen,
                      onRefresh: () async {
                        _subscribeToDatabase();
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildSalesTab(),
                          _buildShopsTab(),
                          _buildCustomersTab(),
                          _buildShopOwnersTab(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, String? badge) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 5),
            Text(label),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW & PENDING APPROVALS
  // ==========================================
  Widget _buildOverviewTab() {
    final pending = _pendingShops;
    final totalAccounts = _users.length;
    final totalCustomers = _users.where((u) => u.isCustomer).length;
    final totalOwners = _users.where((u) => u.isShopOwner).length;
    final approvedCount = _shops.where((s) => s.isApproved).length;
    final rejectedCount = _shops.where((s) => s.isRejected).length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Financial Highlights Row ───
          Row(
            children: [
              Expanded(
                child: _PremiumStatCard(
                  title: 'Gross Revenue',
                  value: 'Rs. ${_totalPlatformRevenue.toStringAsFixed(0)}',
                  subtitle: '$_completedOrdersCount orders completed',
                  icon: Icons.payments_rounded,
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PremiumStatCard(
                  title: 'Platform Orders',
                  value: '${_allOrders.length}',
                  subtitle: '$_activeOrdersCount active in queue',
                  icon: Icons.receipt_long_rounded,
                  gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ─── Stats Row ───
          Row(
            children: [
              Expanded(
                child: _PremiumStatCard(
                  title: 'Total Users',
                  value: '$totalAccounts',
                  subtitle: '$totalCustomers customers',
                  icon: Icons.people_alt_rounded,
                  gradient: const [Color(0xFF6CC51D), Color(0xFF539C14)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PremiumStatCard(
                  title: 'Pending',
                  value: '${pending.length}',
                  subtitle: pending.isEmpty ? 'All clear ✓' : 'Needs review',
                  icon: Icons.pending_actions_rounded,
                  gradient: const [Color(0xFFFF8B38), Color(0xFFE67A2E)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PremiumStatCard(
                  title: 'Active Shops',
                  value: '$approvedCount',
                  subtitle: 'In marketplace',
                  icon: Icons.storefront_rounded,
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PremiumStatCard(
                  title: 'Rejected',
                  value: '$rejectedCount',
                  subtitle: 'Declined registrations',
                  icon: Icons.block_rounded,
                  gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Platform Summary Card ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  AppColors.brandGreenSoft.withValues(alpha: 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandGreen.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6CC51D), Color(0xFF539C14)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform Summary',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Live Firestore sync active',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildSummaryRow('Gross Merchandise Value (GMV)', 'Rs. ${_totalPlatformRevenue.toStringAsFixed(0)}', Icons.payments_rounded),
                _buildSummaryRow('Total Orders Processed', '${_allOrders.length}', Icons.receipt_long_rounded),
                _buildSummaryRow('Registered Accounts', '$totalAccounts', Icons.account_circle_rounded),
                _buildSummaryRow('Customer Shoppers', '$totalCustomers', Icons.shopping_bag_rounded),
                _buildSummaryRow('Shop Owners', '$totalOwners', Icons.store_rounded),
                _buildSummaryRow('Active Marketplace Shops', '$approvedCount', Icons.verified_rounded, isLast: true),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Urgent Pending Approvals Queue ───
          if (pending.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA).withValues(alpha: 0.7)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8B38).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFF7A00), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pending.length} Pending ${pending.length == 1 ? 'Approval' : 'Approvals'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Shops registered and waiting for your review',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...pending.map((shop) => _buildShopCard(shop)),
            const SizedBox(height: 20),
          ],

          // ─── Quick Navigation ───
          Text(
            'Quick Navigation',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jump to different sections of the admin panel',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          _buildQuickNavTile(
            title: 'Sales & Financial Analytics',
            subtitle: 'Rs. ${_totalPlatformRevenue.toStringAsFixed(0)} GMV • ${_allOrders.length} orders tracked',
            icon: Icons.analytics_rounded,
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            onTap: () => _tabController.animateTo(1),
          ),
          _buildQuickNavTile(
            title: 'Verify & Manage Shops',
            subtitle: '${_shops.length} total shops ($approvedCount approved, ${pending.length} pending)',
            icon: Icons.storefront_rounded,
            gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            onTap: () => _tabController.animateTo(2),
          ),
          _buildQuickNavTile(
            title: 'Browse Customer Accounts',
            subtitle: '$totalCustomers registered customer shoppers',
            icon: Icons.people_rounded,
            gradient: const [Color(0xFF6CC51D), Color(0xFF539C14)],
            onTap: () => _tabController.animateTo(3),
          ),
          _buildQuickNavTile(
            title: 'Browse Shop Owners',
            subtitle: '$totalOwners registered store operators',
            icon: Icons.business_center_rounded,
            gradient: const [Color(0xFFFF8B38), Color(0xFFE67A2E)],
            onTap: () => _tabController.animateTo(4),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.brandGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandGreenSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.brandGreenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: SALES & FINANCIAL ANALYTICS
  // ==========================================
  Widget _buildSalesTab() {
    final orders = _filteredSalesOrders;

    // Calculate metrics for current filtered set
    final totalFilteredRev = orders.fold<double>(0.0, (sum, o) => o.status == 'Cancelled' ? sum : sum + o.totalAmount);
    final completedOrders = orders.where((o) => o.status == 'Completed').toList();
    final completedRevenue = completedOrders.fold<double>(0.0, (sum, o) => sum + o.totalAmount);
    final completedCount = completedOrders.length;
    final aov = completedCount > 0 ? (completedRevenue / completedCount) : 0.0;
    final activeCount = orders.where((o) => o.status == 'Pending' || o.status == 'Ready for Pickup').length;
    final cancelledCount = orders.where((o) => o.status == 'Cancelled').length;

    // Leaderboard sorted entries
    final shopLeaderboard = _shopRevenueMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Time Range Pill Selector ───
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: ['All Time', 'Today', '7 Days', '30 Days'].map((period) {
                final isSelected = _salesTimeRange == period;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _salesTimeRange = period;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF539C14), Color(0xFF6CC51D)],
                              )
                            : null,
                        color: isSelected ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.brandGreen.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          period,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ─── Top 4 Metric Cards (2x2) ───
          Row(
            children: [
              Expanded(
                child: _PremiumStatCard(
                  title: _salesTimeRange == 'All Time' ? 'Gross Revenue' : '$_salesTimeRange Revenue',
                  value: 'Rs. ${totalFilteredRev.toStringAsFixed(0)}',
                  subtitle: '$completedCount completed orders',
                  icon: Icons.payments_rounded,
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PremiumStatCard(
                  title: 'Completed Orders',
                  value: '$completedCount',
                  subtitle: cancelledCount > 0 ? '$cancelledCount cancelled' : '100% fulfilled',
                  icon: Icons.check_circle_rounded,
                  gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PremiumStatCard(
                  title: 'Avg Order Value',
                  value: 'Rs. ${aov.toStringAsFixed(0)}',
                  subtitle: 'Per completed order',
                  icon: Icons.trending_up_rounded,
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PremiumStatCard(
                  title: 'Active Pipeline',
                  value: '$activeCount',
                  subtitle: 'Pending & Ready',
                  icon: Icons.sync_rounded,
                  gradient: const [Color(0xFFFF8B38), Color(0xFFE67A2E)],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ─── Store Revenue Breakdown / Leaderboard Card ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.brandGreenSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.leaderboard_rounded, color: AppColors.brandGreenDark, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Store Revenue Breakdown',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Marketplace sales by merchant',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_salesShopFilter != 'All')
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            _salesShopFilter = 'All';
                          });
                        },
                        icon: const Icon(Icons.clear_rounded, size: 14, color: AppColors.error),
                        label: Text(
                          'Show All',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                if (shopLeaderboard.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'No store revenue recorded yet',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...shopLeaderboard.map((entry) {
                    final shopName = entry.key;
                    final revenue = entry.value;
                    final totalPlatform = _totalPlatformRevenue > 0 ? _totalPlatformRevenue : 1.0;
                    final sharePct = (revenue / totalPlatform) * 100.0;
                    final isFiltered = _salesShopFilter.toLowerCase() == shopName.toLowerCase();
                    final storeOrdersCount = _allOrders.where((o) => o.shopName == shopName && o.status != 'Cancelled').length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isFiltered ? const Color(0xFFF0FDF4) : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isFiltered ? AppColors.brandGreen : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _salesShopFilter = isFiltered ? 'All' : shopName;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.storefront_rounded, size: 14, color: AppColors.brandGreen),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    shopName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Rs. ${revenue.toStringAsFixed(0)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.brandGreenDark,
                                      ),
                                    ),
                                    Text(
                                      '$storeOrdersCount orders • ${sharePct.toStringAsFixed(0)}% share',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (revenue / totalPlatform).clamp(0.0, 1.0),
                                minHeight: 5,
                                backgroundColor: Colors.black.withValues(alpha: 0.06),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isFiltered ? AppColors.brandGreen : const Color(0xFF6CC51D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Platform Orders Ledger Title & Search ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Orders Ledger',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandGreenSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${orders.length} ${orders.length == 1 ? 'order' : 'orders'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandGreenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Search customer orders across all stores',
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          // Search Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _salesSearchController,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search order #, customer, store, item...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                suffixIcon: _salesSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                        onPressed: () {
                          _salesSearchController.clear();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Active Store filter badge if selected
          if (_salesShopFilter != 'All')
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded, size: 14, color: AppColors.brandGreenDark),
                  const SizedBox(width: 6),
                  Text(
                    'Filtering: $_salesShopFilter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandGreenDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _salesShopFilter = 'All';
                      });
                    },
                    child: const Icon(Icons.close_rounded, size: 14, color: AppColors.brandGreenDark),
                  ),
                ],
              ),
            ),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['All', 'Completed', 'Ready for Pickup', 'Pending', 'Cancelled'].map((status) {
                final isSelected = _salesStatusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _salesStatusFilter = status;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.brandGreen,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.brandGreen : AppColors.border,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // ─── Orders List or Empty State ───
          if (orders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No orders match your criteria',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try changing the date range, status, or search term.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _salesTimeRange = 'All Time';
                        _salesStatusFilter = 'All';
                        _salesShopFilter = 'All';
                        _salesSearchController.clear();
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset All Filters'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandGreenDark,
                      side: const BorderSide(color: AppColors.brandGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            )
          else
            ...orders.map((order) => _buildAdminOrderCard(order)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAdminOrderCard(StoreOrder order) {
    Color statusBg;
    Color statusFg;
    IconData statusIcon;

    switch (order.status.toLowerCase()) {
      case 'completed':
        statusBg = const Color(0xFFE8F8D8);
        statusFg = const Color(0xFF2E7D32);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'ready for pickup':
        statusBg = const Color(0xFFDBEAFE);
        statusFg = const Color(0xFF1D4ED8);
        statusIcon = Icons.store_rounded;
        break;
      case 'cancelled':
        statusBg = const Color(0xFFFEE2E2);
        statusFg = const Color(0xFFDC2626);
        statusIcon = Icons.cancel_rounded;
        break;
      case 'pending':
      default:
        statusBg = const Color(0xFFFEF3C7);
        statusFg = const Color(0xFFD97706);
        statusIcon = Icons.schedule_rounded;
        break;
    }

    final isPaidOnline = order.paymentMethod.toLowerCase().contains('online') ||
        order.paymentMethod.toLowerCase().contains('card');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showAdminOrderDetailsDialog(order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Order ID, Shop badge, Status chip
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.id.startsWith('#') ? order.id : '#${order.id}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 13, color: AppColors.brandGreen),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.shopName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 11, color: statusFg),
                          const SizedBox(width: 4),
                          Text(
                            order.status,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: statusFg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Customer info & pickup slot
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_rounded, size: 16, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${order.customerPhone} • ${order.pickupSlot}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Items summary container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.itemsSummary,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Bottom row: Payment badge, Total amount, Detail arrow
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPaidOnline ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isPaidOnline ? const Color(0xFF93C5FD) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaidOnline ? Icons.credit_card_rounded : Icons.payments_rounded,
                            size: 11,
                            color: isPaidOnline ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.paymentMethod,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isPaidOnline ? const Color(0xFF1E40AF) : const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandGreenDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAdminOrderDetailsDialog(StoreOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreenSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.brandGreenDark, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Details',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            order.id.startsWith('#') ? 'Order ${order.id}' : 'Order #${order.id}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Order Info
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Amount Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF539C14), Color(0xFF6CC51D)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandGreen.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Status',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.status,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total Value',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Store & Customer info section
                      Text(
                        'TRANSACTION INFORMATION',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildOrderMetaRow('Shop Name', order.shopName),
                            _buildOrderMetaRow('Customer', order.customerName),
                            _buildOrderMetaRow('Contact', order.customerPhone),
                            _buildOrderMetaRow('Pickup Slot', order.pickupSlot),
                            _buildOrderMetaRow('Payment Method', order.paymentMethod),
                            _buildOrderMetaRow(
                              'Placed At',
                              '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')} ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Items list section
                      Text(
                        'ORDER ITEMS SUMMARY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          order.itemsSummary,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Copy Order ID button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: order.id));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied Order #${order.id} to clipboard'),
                                backgroundColor: AppColors.brandGreenDark,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy Order ID'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderMetaRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: SHOPS MODERATION
  // ==========================================
  Widget _buildShopsTab() {
    final list = _filteredShops;

    return Column(
      children: [
        // Search & Filter Container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              // Search bar
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search shops by name, owner, city...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', '${_shops.length}'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', '${_pendingShops.length}', activeColor: const Color(0xFFFF7A00)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Approved', '${_shops.where((s) => s.isApproved).length}', activeColor: AppColors.brandGreen),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rejected', '${_shops.where((s) => s.isRejected).length}', activeColor: AppColors.error),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Shops List
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState(
                  icon: Icons.store_mall_directory_rounded,
                  title: 'No shops found',
                  subtitle: _searchQuery.isNotEmpty
                      ? 'No registered shops match "$_searchQuery".'
                      : 'No shops under the "$_shopFilter" filter.',
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _buildShopCard(list[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String count, {Color? activeColor}) {
    final isSelected = _shopFilter == label;
    final color = activeColor ?? AppColors.brandGreen;

    return GestureDetector(
      onTap: () => setState(() => _shopFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.85)])
              : null,
          color: isSelected ? null : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.2 : 0.8,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.3) : AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: CUSTOMERS
  // ==========================================
  Widget _buildCustomersTab() {
    final list = _customers;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search customers by name, phone, email...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              Text(
                '${list.length} Customers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandGreenSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Active',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandGreenDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState(
                  icon: Icons.person_off_rounded,
                  title: 'No Customers Found',
                  subtitle: _searchQuery.isNotEmpty
                      ? 'No registered customer matches "$_searchQuery".'
                      : 'No customer accounts registered yet in database.',
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _buildCustomerCard(list[index], index),
                ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 4: SHOP OWNERS
  // ==========================================
  Widget _buildShopOwnersTab() {
    final list = _shopOwners;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search shop owners by name, shop, phone...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              Text(
                '${list.length} Shop Owners',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sellers',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF7A00),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState(
                  icon: Icons.business_center_rounded,
                  title: 'No Shop Owners Found',
                  subtitle: _searchQuery.isNotEmpty
                      ? 'No shop owner matches "$_searchQuery".'
                      : 'No shop owners registered yet in database.',
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _buildOwnerCard(list[index]),
                ),
        ),
      ],
    );
  }

  // ==========================================
  // CARDS & COMPONENTS
  // ==========================================
  Widget _buildShopCard(ShopProfile shop) {
    final items = _getShopItems(shop);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: shop.isPending
              ? const Color(0xFFFFB86C).withValues(alpha: 0.6)
              : AppColors.border.withValues(alpha: 0.7),
          width: shop.isPending ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: shop.isPending
                ? const Color(0xFFFF8B38).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showShopDetailsSheet(shop, initialTab: 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: shop.isApproved
                              ? [const Color(0xFFE8F8D8), AppColors.brandGreenSoft]
                              : (shop.isPending
                                  ? [const Color(0xFFFFF2E6), const Color(0xFFFFE8CC)]
                                  : [const Color(0xFFFEE2E2), const Color(0xFFFECACA)]),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: shop.isApproved
                            ? AppColors.brandGreenDark
                            : (shop.isPending ? const Color(0xFFFF7A00) : AppColors.error),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  shop.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              _buildStatusBadge(shop.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Owner: ${shop.ownerName.isNotEmpty ? shop.ownerName : "Registered Seller"}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppColors.brandGreenSoft,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.inventory_2_rounded, size: 10.5, color: AppColors.brandGreenDark),
                                    const SizedBox(width: 3.5),
                                    Text(
                                      '${items.length} ${items.length == 1 ? "item" : "items"}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.brandGreenDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 13, color: AppColors.brandGreen.withValues(alpha: 0.8)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  shop.address.isNotEmpty ? shop.address : 'No address specified',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (shop.phone.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 3),
                                Text(
                                  shop.phone,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                if (shop.isRejected && shop.rejectionReason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            shop.rejectionReason,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons for moderation and inventory
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildCardAction(
                          icon: Icons.inventory_2_outlined,
                          label: 'Items (${items.length})',
                          color: AppColors.brandGreen,
                          filled: true,
                          onTap: () => _showShopDetailsSheet(shop, initialTab: 0),
                        ),
                        _buildCardAction(
                          icon: Icons.info_outline_rounded,
                          label: 'Details',
                          color: AppColors.textMuted,
                          onTap: () => _showShopDetailsSheet(shop, initialTab: 1),
                        ),
                        if (shop.isPending) ...[
                          _buildCardAction(
                            icon: Icons.close_rounded,
                            label: 'Reject',
                            color: AppColors.error,
                            filled: false,
                            onTap: () => _promptRejectShop(shop),
                          ),
                          _buildCardAction(
                            icon: Icons.check_rounded,
                            label: 'Approve',
                            color: AppColors.brandGreen,
                            filled: true,
                            onTap: () => _approveShop(shop),
                          ),
                        ] else if (shop.isApproved) ...[
                          _buildCardAction(
                            icon: Icons.pause_circle_outline_rounded,
                            label: 'Suspend',
                            color: const Color(0xFFFF8B38),
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await _authService.suspendShop(shop.id, userId: shop.id);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Shop "${shop.name}" suspended.'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            },
                          ),
                        ] else if (shop.isRejected) ...[
                          _buildCardAction(
                            icon: Icons.refresh_rounded,
                            label: 'Re-Approve',
                            color: AppColors.brandGreen,
                            filled: true,
                            onTap: () => _approveShop(shop),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardAction({
    required IconData icon,
    required String label,
    required Color color,
    bool filled = false,
    required VoidCallback onTap,
  }) {
    if (filled) {
      return Material(
        color: color,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(UserModel user, int index) {
    // Alternate subtle gradient background for every other card
    final isEven = index % 2 == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : AppColors.surfaceMuted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F8D8), Color(0xFFF1FCE8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'C',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: AppColors.brandGreenDark,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.phone_iphone_rounded, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      user.phoneNumber.isNotEmpty ? user.phoneNumber : 'No phone',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF1FCE8), Color(0xFFE5F8D5)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brandGreenSoft),
            ),
            child: Text(
              'Customer',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.brandGreenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard(UserModel user) {
    final status = user.shopStatus ?? 'approved';
    final isPending = status == 'pending';
    final matchingShop = _shops.firstWhere(
      (s) => s.id == user.id || s.name.toLowerCase() == (user.shopName ?? '').toLowerCase(),
      orElse: () => ShopProfile(
        id: user.id,
        name: user.shopName ?? 'Grocery Store',
        ownerName: user.fullName,
        ownerEmail: user.email,
        phone: user.phoneNumber,
        address: user.shopAddress ?? '',
        status: user.shopStatus ?? 'approved',
      ),
    );
    final items = _getShopItems(matchingShop);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending
              ? const Color(0xFFFFB86C).withValues(alpha: 0.6)
              : AppColors.border.withValues(alpha: 0.7),
          width: isPending ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isPending
                ? const Color(0xFFFF8B38).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showShopDetailsSheet(matchingShop, initialTab: 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF2E6), Color(0xFFFFE8CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.storefront_rounded, color: Color(0xFFFF7A00), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.shopName ?? 'Grocery Store',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Owner: ${user.fullName}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user.email,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            user.phoneNumber,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (user.shopAddress != null && user.shopAddress!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: AppColors.brandGreen),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user.shopAddress!,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildCardAction(
                      icon: Icons.inventory_2_outlined,
                      label: 'View Store Items (${items.length})',
                      color: AppColors.brandGreen,
                      filled: true,
                      onTap: () => _showShopDetailsSheet(matchingShop, initialTab: 0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
        bg = AppColors.brandGreenSoft;
        fg = AppColors.brandGreenDark;
        label = 'Verified';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        bg = AppColors.errorSoft;
        fg = AppColors.error;
        label = 'Rejected';
        icon = Icons.cancel_rounded;
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFFF2E6);
        fg = const Color(0xFFFF7A00);
        label = 'Pending';
        icon = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNavTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.surfaceMuted, AppColors.surfaceMuted.withValues(alpha: 0.5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 36, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PREMIUM STAT CARD WITH GRADIENT
// ==========================================
class _PremiumStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _PremiumStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


class _AdminShopDetailsAndItemsSheet extends StatefulWidget {
  final ShopProfile shop;
  final int initialTab;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSuspend;

  const _AdminShopDetailsAndItemsSheet({
    required this.shop,
    this.initialTab = 0,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
  });

  @override
  State<_AdminShopDetailsAndItemsSheet> createState() => _AdminShopDetailsAndItemsSheetState();
}

class _AdminShopDetailsAndItemsSheetState extends State<_AdminShopDetailsAndItemsSheet> {
  late int _selectedTab;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
    GroceryService().addListener(_onGroceryChange);
  }

  void _onGroceryChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    GroceryService().removeListener(_onGroceryChange);
    _searchController.dispose();
    super.dispose();
  }

  List<GroceryItem> _fetchItems() {
    return GroceryService().getItemsForShop(
      shopId: widget.shop.id,
      shopName: widget.shop.name,
      ownerName: widget.shop.ownerName,
      ownerEmail: widget.shop.ownerEmail,
    );
  }

  void _showProductDetailsDialog(BuildContext context, GroceryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(20),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  color: const Color(0xFFF8FAFC),
                  child: AppImageView(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 3),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreenSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Unit: ${item.unit}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandGreenDark,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Rs. ${item.price.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandGreenDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVENTORY & SUPPLIER DETAILS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPopupMetaRow('Stock Available', '${item.stockQuantity} units in shop inventory'),
                    _buildPopupMetaRow('Store Name', item.displaySellerShopName),
                    _buildPopupMetaRow('Seller Operator', item.displaySellerName),
                    _buildPopupMetaRow('Contact Number', item.displaySellerPhone),
                    _buildPopupMetaRow('Shop Location', item.displaySellerAddress, isLast: true),
                  ],
                ),
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'PRODUCT DESCRIPTION',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.brandGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMetaRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _fetchItems();

    // Unique categories
    final categories = <String>['All'];
    for (final item in allItems) {
      if (item.category.isNotEmpty && !categories.contains(item.category)) {
        categories.add(item.category);
      }
    }

    // Filter items
    var filteredItems = allItems;
    if (_selectedCategory != 'All') {
      filteredItems = filteredItems
          .where((i) => i.category.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((i) {
        return i.name.toLowerCase().contains(_searchQuery) ||
            i.category.toLowerCase().contains(_searchQuery) ||
            i.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    final inStockCount = allItems.where((i) => i.stockQuantity > 0).length;
    final lowStockCount = allItems.where((i) => i.stockQuantity > 0 && i.stockQuantity <= 10).length;

    final isApproved = widget.shop.isApproved;
    final isPending = widget.shop.isPending;
    final isRejected = widget.shop.isRejected;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isApproved
                          ? [const Color(0xFFE8F8D8), AppColors.brandGreenSoft]
                          : (isPending
                              ? [const Color(0xFFFFF2E6), const Color(0xFFFFE8CC)]
                              : [const Color(0xFFFEE2E2), const Color(0xFFFECACA)]),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: isApproved
                        ? AppColors.brandGreenDark
                        : (isPending ? const Color(0xFFFF7A00) : AppColors.error),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.shop.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(widget.shop.status),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Owner: ${widget.shop.ownerName.isNotEmpty ? widget.shop.ownerName : "Registered Seller"} • ${widget.shop.phone.isNotEmpty ? widget.shop.phone : "No phone"}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Moderation quick actions row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (isPending) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 15),
                      label: Text(
                        'Reject',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: widget.onReject,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 15),
                      label: Text(
                        'Approve Shop',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: widget.onApprove,
                    ),
                  ),
                ] else if (isApproved) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.pause_circle_outline_rounded, color: Color(0xFFFF8B38), size: 15),
                      label: Text(
                        'Suspend Shop',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFFF8B38)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF8B38)),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: widget.onSuspend,
                    ),
                  ),
                ] else if (isRejected) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 15),
                      label: Text(
                        'Re-Approve Shop',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: widget.onApprove,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab Switcher (Segmented Control)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: _selectedTab == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_rounded,
                            size: 15,
                            color: _selectedTab == 0 ? AppColors.brandGreenDark : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Shop Items (${allItems.length})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: _selectedTab == 0 ? FontWeight.w800 : FontWeight.w600,
                              color: _selectedTab == 0 ? AppColors.brandGreenDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: _selectedTab == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: _selectedTab == 1 ? AppColors.brandGreenDark : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Store Details & Hours',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: _selectedTab == 1 ? FontWeight.w800 : FontWeight.w600,
                              color: _selectedTab == 1 ? AppColors.brandGreenDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Main Tab Body
          Expanded(
            child: _selectedTab == 0
                ? _buildItemsTab(allItems, filteredItems, categories, inStockCount, lowStockCount)
                : _buildDetailsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTab(
    List<GroceryItem> allItems,
    List<GroceryItem> filteredItems,
    List<String> categories,
    int inStockCount,
    int lowStockCount,
  ) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search items in ${widget.shop.name}...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textPrimary),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(5)),
                      child: const Icon(Icons.close_rounded, size: 12, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Category filter chips
        if (categories.length > 1)
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, idx) {
                final cat = categories[idx];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brandGreen : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? AppColors.brandGreen : AppColors.border),
                    ),
                    child: Text(
                      cat == 'All' ? 'All (${allItems.length})' : cat,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 10),

        // Summary Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                '${filteredItems.length} Products Listed',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandGreenSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$inStockCount In Stock',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandGreenDark,
                  ),
                ),
              ),
              if (lowStockCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Text(
                    '$lowStockCount Low Stock',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC2410C),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Products List
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No Items Found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No items match "$_searchQuery".'
                              : 'No products listed under "$_selectedCategory".',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                              _selectedCategory = 'All';
                            });
                          },
                          child: Text(
                            'Reset Filter',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.brandGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final item = filteredItems[idx];
                    return _buildAdminProductCard(context, item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAdminProductCard(BuildContext context, GroceryItem item) {
    final isLowStock = item.stockQuantity > 0 && item.stockQuantity <= 10;
    final isOutOfStock = item.stockQuantity <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showProductDetailsDialog(context, item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Product Image
                Stack(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AppImageView(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (item.discountPercent != null && item.discountPercent! > 0)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${item.discountPercent}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 2),
                              Text(
                                item.rating.toStringAsFixed(1),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.category,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.unit,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Rs. ${item.price.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandGreenDark,
                            ),
                          ),
                          if (item.originalPrice != null) ...[
                            const SizedBox(width: 5),
                            Text(
                              'Rs. ${item.originalPrice!.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isOutOfStock
                                  ? AppColors.errorSoft
                                  : (isLowStock ? const Color(0xFFFFF7ED) : AppColors.brandGreenSoft),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isOutOfStock
                                    ? AppColors.error.withValues(alpha: 0.3)
                                    : (isLowStock ? const Color(0xFFFED7AA) : AppColors.brandGreen.withValues(alpha: 0.2)),
                              ),
                            ),
                            child: Text(
                              isOutOfStock
                                  ? 'Out of Stock'
                                  : (isLowStock ? 'Low: ${item.stockQuantity}' : 'Stock: ${item.stockQuantity}'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isOutOfStock
                                    ? AppColors.error
                                    : (isLowStock ? const Color(0xFFC2410C) : AppColors.brandGreenDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSheetDetailRow(Icons.person_rounded, 'Owner', widget.shop.ownerName.isNotEmpty ? widget.shop.ownerName : 'Registered Seller'),
                _buildSheetDetailRow(Icons.email_rounded, 'Email', widget.shop.ownerEmail.isNotEmpty ? widget.shop.ownerEmail : 'Not specified'),
                _buildSheetDetailRow(Icons.phone_rounded, 'Phone', widget.shop.phone.isNotEmpty ? widget.shop.phone : 'Not specified'),
                _buildSheetDetailRow(Icons.location_on_rounded, 'Address', widget.shop.address.isNotEmpty ? widget.shop.address : 'Not specified'),
                if (widget.shop.addressNote.isNotEmpty)
                  _buildSheetDetailRow(Icons.directions_rounded, 'Hint', widget.shop.addressNote),
                _buildSheetDetailRow(Icons.access_time_rounded, 'Weekday', widget.shop.weekdayHoursLabel),
                _buildSheetDetailRow(Icons.event_busy_rounded, 'Sunday', widget.shop.sundayHoursLabel),
                _buildSheetDetailRow(Icons.av_timer_rounded, 'Slots', '${widget.shop.slotMinutes} min interval (Max ${widget.shop.maxOrdersPerSlot}/slot)', isLast: true),
              ],
            ),
          ),

          if (widget.shop.isRejected && widget.shop.rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rejection Reason',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.shop.rejectionReason,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSheetDetailRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppColors.brandGreen),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
        bg = AppColors.brandGreenSoft;
        fg = AppColors.brandGreenDark;
        label = 'Verified';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        bg = AppColors.errorSoft;
        fg = AppColors.error;
        label = 'Rejected';
        icon = Icons.cancel_rounded;
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFFF2E6);
        fg = const Color(0xFFFF7A00);
        label = 'Pending';
        icon = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

