import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/grocery_item_model.dart';
import '../../models/seller_order_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/grocery_service.dart';
import '../common/app_image_view.dart';
import 'add_product_screen.dart';
import 'chat/shop_owner_conversations_screen.dart';
import 'dashboard/widgets/customer_inquiries_section.dart';
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
  String _productStatusFilter = 'All';

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
    final shopLoc = widget.user.shopAddress ?? 'High Level Road, Maharagama';

    return ListenableBuilder(
      listenable: Listenable.merge([GroceryService(), authService]),
      builder: (context, _) {
        final groceryService = GroceryService();
        final orders = groceryService.sellerOrders;
        final pendingCount = orders.where((o) => o.status == 'Pending').length;
        final unreadNotifs = groceryService.unreadNotificationsCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: _buildAppBar(shopTitle, shopLoc, unreadNotifs, authService),
          body: IndexedStack(
            index: _currentTabIndex,
            children: [
              _buildOrdersTab(groceryService, orders, pendingCount),
              _buildProductsTab(groceryService),
              _buildAnalyticsTab(orders),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(pendingCount),
          floatingActionButton: _buildChatCircleButton(),
        );
      },
    );
  }

  // ==========================================
  // MODERN CLEAN APP BAR
  // ==========================================
  PreferredSizeWidget _buildAppBar(
    String shopTitle,
    String shopLoc,
    int unreadNotifs,
    AuthService authService,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      titleSpacing: 16,
      title: Row(
        children: [
          // Store Avatar Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFF2EB844),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Store Name & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  shopTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                GestureDetector(
                  onTap: () {
                    setState(() => _isOpenForPickup = !_isOpenForPickup);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isOpenForPickup
                              ? 'Store is now open for pickup'
                              : 'Store marked as closed',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _isOpenForPickup
                              ? const Color(0xFF2EB844)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isOpenForPickup ? 'Open for Pickup' : 'Store Closed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isOpenForPickup
                              ? const Color(0xFF2EB844)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Notification bell with clean badge
        IconButton(
          tooltip: 'Notifications',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF374151),
                size: 24,
              ),
              if (unreadNotifs > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: _openNotificationsSheet,
        ),
        // Logout button
        IconButton(
          tooltip: 'Log out',
          icon: const Icon(
            Icons.logout_rounded,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          onPressed: () => authService.logout(),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: const Color(0xFFF3F4F6),
          height: 1,
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: CLEAN ORDERS TAB
  // ==========================================
  Widget _buildOrdersTab(
    GroceryService groceryService,
    List<StoreOrder> orders,
    int pendingCount,
  ) {
    final filteredOrders = orders.where((o) {
      if (_selectedOrderFilter == 'Pending') return o.status == 'Pending';
      if (_selectedOrderFilter == 'Ready') return o.status == 'Ready for Pickup';
      if (_selectedOrderFilter == 'Completed') return o.status == 'Completed';
      return true;
    }).toList();

    final totalRev = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // ─── Metrics Overview Strip ───
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: 'Total Orders',
                value: '${orders.length}',
                color: const Color(0xFF2563EB),
                bg: const Color(0xFFEFF6FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                label: 'Pending',
                value: '$pendingCount',
                color: const Color(0xFFD97706),
                bg: const Color(0xFFFFFBEB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                label: 'Revenue',
                value: 'Rs. ${(totalRev / 1000).toStringAsFixed(1)}k',
                color: const Color(0xFF16A34A),
                bg: const Color(0xFFF0FDF4),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ─── Filter Pills ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Incoming Pickup Orders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${filteredOrders.length} total',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Clean Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip('All', orders.length),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Pending',
                orders.where((o) => o.status == 'Pending').length,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Ready',
                orders.where((o) => o.status == 'Ready for Pickup').length,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Completed',
                orders.where((o) => o.status == 'Completed').length,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ─── Order Cards ───
        if (filteredOrders.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 10),
                Text(
                  'No orders in this status',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          )
        else
          ...filteredOrders.map((order) {
            return _buildCleanOrderCard(order, groceryService);
          }),

        const SizedBox(height: 20),

        // ─── Customer Inquiries Strip ───
        const CustomerInquiriesSection(),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedOrderFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedOrderFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2EB844) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2EB844) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanOrderCard(StoreOrder order, GroceryService service) {
    final isPending = order.status == 'Pending';
    final isReady = order.status == 'Ready for Pickup';
    final isCompleted = order.status == 'Completed';

    Color statusColor;
    Color statusBg;
    if (isReady) {
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
    } else if (isPending) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
    } else {
      statusColor = const Color(0xFF4B5563);
      statusBg = const Color(0xFFF3F4F6);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady
              ? const Color(0xFF2EB844).withValues(alpha: 0.3)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID + Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.id,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Customer Name & Phone
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 15,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
              Text(
                order.customerName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${order.customerPhone}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Items summary
          Row(
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 15,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.itemsSummary,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF4B5563),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Pickup slot
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: Color(0xFF2EB844),
              ),
              const SizedBox(width: 6),
              Text(
                order.pickupSlot,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),

          // Bottom Bar: Price + Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  Text(
                    order.formattedTotal,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2EB844),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),

              // Action button
              if (!isCompleted)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReady
                        ? const Color(0xFF1F2937)
                        : const Color(0xFF2EB844),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () {
                    if (isReady) {
                      service.updateOrderStatus(order.id, 'Completed');
                    } else {
                      service.updateOrderStatus(order.id, 'Ready for Pickup');
                    }
                  },
                  child: Text(
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
  // TAB 2: CLEAN PRODUCTS TAB
  // ==========================================
  Widget _buildProductFilterChip(String label, int count) {
    final isSelected = _productStatusFilter == label;
    return InkWell(
      onTap: () => setState(() => _productStatusFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2EB844) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2EB844) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab(GroceryService groceryService) {
    final allItems = groceryService.allItems;
    final activeCount = allItems.where((it) => it.isAvailable && it.stockQuantity > 0).length;
    final inactiveCount = allItems.where((it) => !it.isAvailable).length;
    final outOfStockCount = allItems.where((it) => it.stockQuantity <= 0).length;

    final filteredItems = allItems.where((it) {
      if (_productSearchQuery.isNotEmpty) {
        final q = _productSearchQuery.toLowerCase();
        final matches = it.name.toLowerCase().contains(q) ||
            it.category.toLowerCase().contains(q);
        if (!matches) return false;
      }
      if (_productStatusFilter == 'Active') {
        return it.isAvailable && it.stockQuantity > 0;
      } else if (_productStatusFilter == 'Inactive') {
        return !it.isAvailable;
      } else if (_productStatusFilter == 'Out of Stock') {
        return it.stockQuantity <= 0;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Top Bar: Search + Add Product Button
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  // Search box
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (val) =>
                            setState(() => _productSearchQuery = val),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search products or category...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: const Color(0xFF9CA3AF),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: Color(0xFF9CA3AF),
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Add Product Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2EB844),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onPressed: _openAddProduct,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      'Add Product',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Direct sync status row (required by tests & informative for user)
              Row(
                children: [
                  const Icon(
                    Icons.sync_rounded,
                    size: 14,
                    color: Color(0xFF2EB844),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Direct Sync: All products appear live on Customer DashGrocer',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Status Filter Chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildProductFilterChip('All', allItems.length),
                const SizedBox(width: 8),
                _buildProductFilterChip('Active', activeCount),
                const SizedBox(width: 8),
                _buildProductFilterChip('Inactive', inactiveCount),
                const SizedBox(width: 8),
                _buildProductFilterChip('Out of Stock', outOfStockCount),
              ],
            ),
          ),
        ),

        const Divider(height: 1, color: Color(0xFFE5E7EB)),

        // Product Catalog List
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Text(
                    'No products found matching filters',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildCleanProductCard(item, groceryService);
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showEditStockDialog(
    BuildContext context,
    GroceryItem item,
    GroceryService service,
  ) async {
    final controller = TextEditingController(text: item.stockQuantity.toString());
    final newStock = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Update Stock',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Units in Stock',
                hintText: 'Enter quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2EB844),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed >= 0) {
                Navigator.pop(ctx, parsed);
              }
            },
            child: Text(
              'Update',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (newStock != null) {
      service.setProductStock(item.id, newStock);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock for "${item.name}" updated to $newStock'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteProduct(
    BuildContext context,
    GroceryItem item,
    GroceryService service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Product?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${item.name}" from your catalog and customer store? This cannot be undone.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF4B5563),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      service.deleteProduct(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.name}" removed from catalog'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildCleanProductCard(GroceryItem item, GroceryService service) {
    final isOut = item.stockQuantity <= 0;
    final isInactive = !item.isAvailable;

    Color badgeBg;
    Color badgeColor;
    String badgeText;

    if (isInactive) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeColor = const Color(0xFFD97706);
      badgeText = 'Inactive';
    } else if (isOut) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeColor = const Color(0xFFDC2626);
      badgeText = 'Out of Stock';
    } else {
      badgeBg = const Color(0xFFDCFCE7);
      badgeColor = const Color(0xFF16A34A);
      badgeText = 'Active';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInactive
              ? const Color(0xFFFDE68A)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 58,
                  height: 58,
                  color: const Color(0xFFF9FAFB),
                  child: AppImageView(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Information
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
                              color: const Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.category} • ${item.unit}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          item.formattedPrice,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2EB844),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Tap to edit stock
                        InkWell(
                          onTap: () => _showEditStockDialog(context, item, service),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Stock: ${item.stockQuantity}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isOut ? const Color(0xFFDC2626) : const Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.edit_outlined, size: 11, color: Color(0xFF6B7280)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete action
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
                onPressed: () => _confirmDeleteProduct(context, item, service),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 8),

          // Bottom Quick Controls: Active toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    item.isAvailable ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: 15,
                    color: item.isAvailable ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.isAvailable ? 'Visible to Customers' : 'Hidden from Customers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: item.isAvailable ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    item.isAvailable ? 'Active' : 'Inactive',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 28,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Switch(
                        value: item.isAvailable,
                        activeThumbColor: const Color(0xFF2EB844),
                        onChanged: (val) {
                          service.setProductAvailability(item.id, val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                val
                                    ? '"${item.name}" is now Active on customer home'
                                    : '"${item.name}" hidden from customer home',
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: CLEAN MODERN ANALYTICS
  // ==========================================
  Widget _buildAnalyticsTab(List<StoreOrder> orders) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // ─── Clean Revenue Banner ───
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
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
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9CA3AF),
                      letterSpacing: 0.8,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2EB844).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+18.4% this week',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4ADE80),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rs. 48,250.00',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFF374151)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCleanStat('Avg Order', 'Rs. 1,650'),
                  _buildCleanStat('Fulfilled', '98.2%'),
                  _buildCleanStat('Repeat Buyers', '84%'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ─── Weekly Velocity Card ───
        Text(
          'Weekly Sales Velocity',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    'Peak: Saturday',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2EB844),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildModernBar('Mon', 12, 24),
                  _buildModernBar('Tue', 15, 24),
                  _buildModernBar('Wed', 8, 24),
                  _buildModernBar('Thu', 18, 24),
                  _buildModernBar('Fri', 20, 24),
                  _buildModernBar('Sat', 24, 24, isHighlight: true),
                  _buildModernBar('Sun', 16, 24),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ─── Top Selling Products ───
        Text(
          'Top Selling Products',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),

        _buildCleanLeaderboardItem('1', 'Fresh Broccoli', '84 sold', 'Rs. 63,000'),
        _buildCleanLeaderboardItem('2', 'Nadu Rice 5kg', '62 sold', 'Rs. 91,760'),
        _buildCleanLeaderboardItem('3', 'Chicken Breast 1KG', '45 sold', 'Rs. 65,250'),
        _buildCleanLeaderboardItem('4', 'Fresh Butter Avocado', '38 sold', 'Rs. 26,600'),
      ],
    );
  }

  Widget _buildCleanStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildModernBar(String day, int count, int max, {bool isHighlight = false}) {
    final ratio = count / max;
    final barHeight = 72.0 * ratio;

    return Column(
      children: [
        Text(
          '$count',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isHighlight
                ? const Color(0xFF2EB844)
                : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 14,
          height: barHeight,
          decoration: BoxDecoration(
            color: isHighlight
                ? const Color(0xFF2EB844)
                : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            color: isHighlight
                ? const Color(0xFF111827)
                : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildCleanLeaderboardItem(
    String rank,
    String name,
    String sales,
    String revenue,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rank == '1'
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: rank == '1'
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF6B7280),
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
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  sales,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
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
              color: const Color(0xFF2EB844),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomNav(int pendingCount) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2EB844),
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.receipt_long_rounded),
                if (pendingCount > 0)
                  Positioned(
                    right: -3,
                    top: -1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2EB844),
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
    );
  }

  Widget _buildChatCircleButton() {
    final chatService = ChatService();
    return ListenableBuilder(
      listenable: chatService,
      builder: (context, _) {
        final unread = chatService.sellerUnreadCount;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Tooltip(
            message: 'Customer Chat',
            child: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              backgroundColor: const Color(0xFFEF4444),
              largeSize: 20,
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              offset: const Offset(-2, 2),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2EB844),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2EB844).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShopOwnerConversationsScreen(),
                        ),
                      );
                    },
                    child: const Center(
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
