import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/grocery_item_model.dart';
import '../../models/seller_order_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/grocery_service.dart';
import 'add_product_screen.dart';
import 'seller_notifications_sheet.dart';

class ShopOwnerDashboard extends StatefulWidget {
  final UserModel user;

  const ShopOwnerDashboard({
    super.key,
    required this.user,
  });

  @override
  State<ShopOwnerDashboard> createState() => _ShopOwnerDashboardState();
}

class _ShopOwnerDashboardState extends State<ShopOwnerDashboard> {
  int _currentTabIndex = 0;
  bool _isOpenForPickup = true;
  String _selectedOrderFilter = 'All';
  String _productSearchQuery = '';

  void _openAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen(seller: widget.user),
      ),
    );
  }

  void _openNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SellerNotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final shopTitle = widget.user.shopName ?? 'GreenLeaf Fresh Mart';
    final shopLoc = widget.user.shopAddress ?? 'No. 42, High Level Road, Maharagama';

    return ListenableBuilder(
      listenable: Listenable.merge([GroceryService(), authService]),
      builder: (context, _) {
        final groceryService = GroceryService();
        final orders = groceryService.sellerOrders;
        final pendingCount = orders.where((o) => o.status == 'Pending').length;
        final unreadNotifs = groceryService.unreadNotificationsCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 16,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOpenForPickup ? AppColors.success : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOpenForPickup ? 'Open for Pickup' : 'Store Closed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isOpenForPickup ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  shopTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              // Store Open/Close Toggle
              IconButton(
                tooltip: _isOpenForPickup ? 'Set Closed' : 'Set Open',
                icon: Icon(
                  _isOpenForPickup ? Icons.store_rounded : Icons.store_mall_directory_outlined,
                  color: _isOpenForPickup ? AppColors.brandGreen : Colors.grey,
                  size: 22,
                ),
                onPressed: () {
                  setState(() => _isOpenForPickup = !_isOpenForPickup);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isOpenForPickup ? 'Store is now OPEN for pickup' : 'Store marked as CLOSED',
                        style: GoogleFonts.plusJakartaSans(),
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: _isOpenForPickup ? AppColors.brandGreen : const Color(0xFF475569),
                    ),
                  );
                },
              ),

              // Notification Bell with dynamic badge
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Store Notifications',
                    icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B), size: 22),
                    onPressed: _openNotificationsSheet,
                  ),
                  if (unreadNotifs > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadNotifs',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              // Logout Button
              IconButton(
                tooltip: 'Log Out',
                icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 20),
                onPressed: () => authService.logout(),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: IndexedStack(
            index: _currentTabIndex,
            children: [
              _buildOrdersTab(groceryService, orders, pendingCount, shopLoc),
              _buildProductsTab(groceryService),
              _buildAnalyticsTab(orders),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentTabIndex,
              onTap: (index) => setState(() => _currentTabIndex = index),
              elevation: 0,
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.brandGreen,
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500),
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.receipt_long_rounded),
                      if (pendingCount > 0)
                        Positioned(
                          right: -4,
                          top: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.brandGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Orders',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2_rounded),
                  label: 'Products',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded),
                  label: 'Analytics',
                ),
              ],
            ),
          ),
          floatingActionButton: _currentTabIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: _openAddProduct,
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Add Product',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                )
              : null,
        );
      },
    );
  }

  // ==========================================
  // TAB 1: ORDERS & STORE OVERVIEW
  // ==========================================
  Widget _buildOrdersTab(
    GroceryService groceryService,
    List<StoreOrder> orders,
    int pendingCount,
    String shopLoc,
  ) {
    // Filter orders
    final filteredOrders = orders.where((o) {
      if (_selectedOrderFilter == 'Pending') return o.status == 'Pending';
      if (_selectedOrderFilter == 'Ready') return o.status == 'Ready for Pickup';
      if (_selectedOrderFilter == 'Completed') return o.status == 'Completed';
      return true;
    }).toList();

    final totalRevenue = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: [
        // Store Pickup Location Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.brandGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shopLoc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3 Key Stats Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Today's Orders",
                value: '${orders.length}',
                icon: Icons.shopping_bag_outlined,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Pending Pickups',
                value: '$pendingCount',
                icon: Icons.timelapse_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: "Total Revenue",
                value: 'Rs. ${(totalRevenue / 1000).toStringAsFixed(1)}k',
                icon: Icons.payments_outlined,
                color: AppColors.brandGreen,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Incoming Pickup Orders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
                letterSpacing: -0.2,
              ),
            ),
            Text(
              '${filteredOrders.length} orders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Filter Pills [All] [Pending] [Ready] [Completed]
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildOrderFilterChip('All'),
              const SizedBox(width: 8),
              _buildOrderFilterChip('Pending'),
              const SizedBox(width: 8),
              _buildOrderFilterChip('Ready'),
              const SizedBox(width: 8),
              _buildOrderFilterChip('Completed'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Orders List
        if (filteredOrders.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 44, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No orders in this category',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          ...filteredOrders.map((order) {
            return _buildStoreOrderCard(order, groceryService);
          }),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildOrderFilterChip(String label) {
    final isSelected = _selectedOrderFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedOrderFilter = label),
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isSelected ? AppColors.brandGreen : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreOrderCard(StoreOrder order, GroceryService service) {
    final isPending = order.status == 'Pending';
    final isReady = order.status == 'Ready for Pickup';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady
              ? AppColors.brandGreen.withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
        ),
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
          // Order ID & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.id,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.formattedTotal,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandGreenDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isReady
                      ? AppColors.brandGreenSoft
                      : (isPending ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isReady
                        ? AppColors.brandGreenDark
                        : (isPending ? const Color(0xFFD97706) : const Color(0xFF475569)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Customer details
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                order.customerName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                order.customerPhone,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Items summary
          Row(
            children: [
              const Icon(Icons.shopping_basket_outlined, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.itemsSummary,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Pickup slot
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: AppColors.brandGreen),
              const SizedBox(width: 6),
              Text(
                'Pickup Slot: ${order.pickupSlot}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isPending) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () {
                    service.updateOrderStatus(order.id, 'Preparing');
                  },
                  child: Text(
                    'Preparing',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReady ? const Color(0xFF334155) : AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () {
                  if (isReady) {
                    service.updateOrderStatus(order.id, 'Completed');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order ${order.id} marked as Completed.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    service.updateOrderStatus(order.id, 'Ready for Pickup');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order ${order.id} marked as Ready for Pickup!'),
                        backgroundColor: AppColors.brandGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: Icon(
                  isReady ? Icons.check_circle_outline_rounded : Icons.check_rounded,
                  size: 16,
                ),
                label: Text(
                  isReady ? 'Mark Completed' : 'Mark Ready for Pickup',
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

  // ==========================================
  // TAB 2: PRODUCTS & INVENTORY MANAGEMENT
  // ==========================================
  Widget _buildProductsTab(GroceryService groceryService) {
    final allItems = groceryService.allItems;
    final filteredItems = allItems.where((it) {
      if (_productSearchQuery.isEmpty) return true;
      final q = _productSearchQuery.toLowerCase();
      return it.name.toLowerCase().contains(q) || it.category.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Top Action Bar with live sync badge
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _productSearchQuery = val),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search products by name or category...',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onPressed: _openAddProduct,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      'Add',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.sync_rounded, size: 14, color: AppColors.brandGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Direct Sync: All products appear live on Customer DashGrocer',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandGreenDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Product Catalog Grid / List
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Text(
                    'No products found matching "$_productSearchQuery"',
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildProductRow(item, groceryService);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductRow(GroceryItem item, GroceryService service) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Image thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 58,
              height: 58,
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.fastfood_rounded, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title, category, price
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NEW',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFF5722),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${item.unit}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stock: ${item.stockQuantity}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.stockQuantity < 10 ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.formattedPrice,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandGreenDark,
                  ),
                ),
              ],
            ),
          ),

          // Delete option
          IconButton(
            tooltip: 'Remove product',
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 20),
            onPressed: () {
              service.deleteProduct(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${item.name}" removed from catalog.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: RICH ANALYTICS DASHBOARD
  // ==========================================
  Widget _buildAnalyticsTab(List<StoreOrder> orders) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: [
        // Revenue Hero Card (Gradient)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF48B02C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2848B02C),
                blurRadius: 16,
                offset: Offset(0, 6),
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
                    'TOTAL GROSS REVENUE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+18.4% vs last week',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Rs. 48,250.00',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildSubStat(label: 'Avg Order', val: 'Rs. 1,650'),
                  const SizedBox(width: 20),
                  _buildSubStat(label: 'Fulfilled', val: '98.2%'),
                  const SizedBox(width: 20),
                  _buildSubStat(label: 'Return Customers', val: '84%'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Section Title: Weekly Sales Trend
        Text(
          'Weekly Sales Velocity',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),

        // Bar Chart Visualizer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Pickups (Last 7 Days)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    'Peak: Saturday (24 orders)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar('Mon', 12, 24),
                  _buildBar('Tue', 15, 24),
                  _buildBar('Wed', 8, 24),
                  _buildBar('Thu', 18, 24),
                  _buildBar('Fri', 20, 24),
                  _buildBar('Sat', 24, 24, isHighlight: true),
                  _buildBar('Sun', 16, 24),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Top Selling Leaderboard
        Text(
          'Top Selling Products',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 10),

        _buildLeaderboardItem(rank: '1', name: 'Fresh Broccoli', sales: '84 sold', revenue: 'Rs. 63,000'),
        _buildLeaderboardItem(rank: '2', name: 'Nadu Rice 5kg', sales: '62 sold', revenue: 'Rs. 91,760'),
        _buildLeaderboardItem(rank: '3', name: 'Chicken Breast 1KG', sales: '45 sold', revenue: 'Rs. 65,250'),
        _buildLeaderboardItem(rank: '4', name: 'Fresh Butter Avocado', sales: '38 sold', revenue: 'Rs. 26,600'),

        const SizedBox(height: 20),

        // Low Stock Inventory Warnings
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Inventory Alerts (Low Stock)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Vine Tomatoes: Only 4 units remaining\n• Red Onions (250g): Only 6 units remaining',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFFB45309),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildBar(String day, int count, int max, {bool isHighlight = false}) {
    final heightRatio = count / max;
    final barHeight = 80.0 * heightRatio;

    return Column(
      children: [
        Text(
          '$count',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isHighlight ? AppColors.brandGreen : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 18,
          height: barHeight,
          decoration: BoxDecoration(
            color: isHighlight ? AppColors.brandGreen : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w500,
            color: isHighlight ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem({
    required String rank,
    required String name,
    required String sales,
    required String revenue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rank == '1'
                  ? const Color(0xFFFEF3C7)
                  : (rank == '2' ? const Color(0xFFF1F5F9) : const Color(0xFFFFF7ED)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: rank == '1' ? const Color(0xFFD97706) : const Color(0xFF475569),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  sales,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            revenue,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.brandGreenDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat({required String label, required String val}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
