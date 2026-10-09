import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../core/formatters.dart';
import '../../../models/shop_order.dart';
import '../../../models/shop_profile.dart';
import '../../../services/shop_store.dart';
import '../shop_actions.dart';
import '../widgets/dialogs.dart';
import '../widgets/info_card.dart';
import '../widgets/shop_owner_app_bar.dart';
import 'widgets/customer_inquiries_section.dart';
import 'widgets/low_stock_list.dart';
import 'widgets/order_action_card.dart';
import 'widgets/overview_grid.dart';
import 'widgets/quick_actions_panel.dart';
import 'widgets/section_header.dart';

/// Shop Owner Dashboard.
///
/// Requirements covered:
///   FR-08  view incoming customer orders
///   FR-06  change order status (Start Preparing / Mark Ready)
///   FR-07  the customer is notified when an order is marked ready
///   FR-05  restock products that are running out
///   NFR-02 every action gives clear feedback (spinner, then a message)
///   NFR-06 the next step for each order is one tap away
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.store,
    required this.actions,
    required this.onOpenOrders,
    required this.onOpenProducts,
    required this.onOpenOrder,
    required this.onOpenSales,
    required this.onOpenNotifications,
    required this.onOpenUserProfile,
    this.onOpenChat,
  });

  final ShopStore store;
  final ShopActions actions;

  /// Switch to the Orders tab. The filter is null for "all orders".
  final void Function(OrderStatus? filter) onOpenOrders;

  /// Switch to the Products tab.
  final VoidCallback onOpenProducts;

  /// Open the Order Details screen.
  final ValueChanged<ShopOrder> onOpenOrder;
  final VoidCallback onOpenSales;
  final VoidCallback onOpenNotifications;
  final VoidCallback? onOpenChat;

  /// Opens the owner's "My Profile" screen (the profile icon in the header).
  final VoidCallback onOpenUserProfile;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const int _maxOrderCards = 3;
  static const int _maxLowStockRows = 3;

  bool _seeding = false;

  ShopStore get _store => widget.store;
  ShopActions get _actions => widget.actions;

  Future<void> _seedDemoData() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _seeding = true);
    try {
      await _store.repository
          .seedDemoData(_store.shopId)
          .timeout(const Duration(seconds: 10));
      showAppMessage(messenger, 'Demo orders and products added.');
    } catch (error) {
      debugPrint('seedDemoData failed: $error');
      showAppMessage(
        messenger,
        'Could not add demo data. Check your Firestore rules and connection.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  /// "Today: Rs. 4,250 from 3 orders" for the Sales Summary shortcut.
  String _salesTodayLabel() {
    final orders = _store.orders;
    if (orders == null) return 'Loading...';
    final now = DateTime.now();
    final today = orders.where(
      (order) =>
          order.status == OrderStatus.completed &&
          isSameDay(order.saleDate, now),
    );
    if (today.isEmpty) return 'No completed orders yet today';
    final total = today.fold<double>(0, (sum, order) => sum + order.total);
    final count = today.length;
    return 'Today: ${formatRs(total)} from '
        '${count == 1 ? '1 order' : '$count orders'}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, child) {
        return Scaffold(
          appBar: ShopOwnerAppBar(
            owner: _store.owner,
            onProfile: widget.onOpenUserProfile,
            onNotifications: widget.onOpenNotifications,
            onChat: widget.onOpenChat,
            unreadCount: _store.unreadAlertCount,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              if (_store.isDemo) const _DemoBanner(),
              _buildApprovalStatusBanner(_store.shop),
              const SizedBox(height: 16),
              const SectionCaption('Overview'),
              OverviewGrid(
                newOrders: _store.countByStatus(OrderStatus.newOrder),
                preparing: _store.countByStatus(OrderStatus.preparing),
                ready: _store.countByStatus(OrderStatus.ready),
                products: _store.products?.length,
                onTapNewOrders: () =>
                    widget.onOpenOrders(OrderStatus.newOrder),
                onTapPreparing: () =>
                    widget.onOpenOrders(OrderStatus.preparing),
                onTapReady: () => widget.onOpenOrders(OrderStatus.ready),
                onTapProducts: widget.onOpenProducts,
              ),
              const SizedBox(height: 32),
              const SectionCaption('Orders and Stocks'),
              QuickActionsPanel(
                newOrderCount: _store.countByStatus(OrderStatus.newOrder) ?? 0,
                salesTodayLabel: _salesTodayLabel(),
                onViewOrders: () => widget.onOpenOrders(null),
                onManageStock: widget.onOpenProducts,
                onOpenSales: widget.onOpenSales,
              ),
              const SizedBox(height: 32),
              const CustomerInquiriesSection(),
              const SizedBox(height: 32),
              SectionHeader(
                title: 'Orders to Handle',
                linkLabel: 'All Orders',
                onLinkTap: () => widget.onOpenOrders(null),
              ),
              const SizedBox(height: 4),
              ..._buildOrderQueue(),
              const SizedBox(height: 32),
              SectionHeader(
                title: 'Low Stock',
                leadingIcon: Icons.warning_amber_rounded,
                linkLabel: 'view',
                onLinkTap: widget.onOpenProducts,
              ),
              const SizedBox(height: 4),
              _buildLowStock(),
            ],
          ),
        );
      },
    );
  }

  /// New and Preparing orders, the most urgent pickup first.
  List<Widget> _buildOrderQueue() {
    if (_store.ordersError != null && _store.orders == null) {
      return [InfoCard.loadError(what: 'orders')];
    }
    final orders = _store.orders;
    if (orders == null) return const [LoadingCard()];

    final queue = _store.actionQueue;
    if (queue.isEmpty) {
      // A brand new Firebase project has no data at all, so debug builds
      // offer to fill it with sample orders and products.
      final canSeed = kDebugMode &&
          !_store.isDemo &&
          orders.isEmpty &&
          (_store.products?.isEmpty ?? false);

      return [
        InfoCard(
          icon: Icons.check_circle_outline,
          title: 'No orders need action',
          message: 'New pre-orders will appear here as soon as they arrive.',
          action: canSeed
              ? TextButton(
                  onPressed: _seeding ? null : _seedDemoData,
                  child: Text(_seeding ? 'Adding...' : 'Add demo data'),
                )
              : null,
        ),
      ];
    }

    final now = DateTime.now();
    final hidden = queue.length - _maxOrderCards;

    return [
      for (final order in queue.take(_maxOrderCards))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OrderActionCard(
            order: order,
            now: now,
            busy: _store.isBusy(order.id),
            onViewDetails: () => widget.onOpenOrder(order),
            onPrimaryAction: () => order.status == OrderStatus.preparing
                ? _actions.markReady(context, order)
                : _actions.startPreparing(context, order),
          ),
        ),
      if (hidden > 0)
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: () => widget.onOpenOrders(null),
            child: Text(
              hidden == 1 ? 'View 1 more order' : 'View $hidden more orders',
            ),
          ),
        ),
    ];
  }

  /// Products at or below their low stock level, the emptiest first.
  Widget _buildLowStock() {
    if (_store.productsError != null && _store.products == null) {
      return InfoCard.loadError(what: 'products');
    }
    if (_store.products == null) return const LoadingCard();

    final lowStock = _store.lowStockProducts;
    if (lowStock.isEmpty) {
      return const InfoCard(
        icon: Icons.inventory_2_outlined,
        title: 'Stock levels look good',
        message: 'Products that are running low will be listed here.',
      );
    }

    return LowStockList(
      products: lowStock.take(_maxLowStockRows).toList(),
      isBusy: _store.isBusy,
      onQuickAdd: (product) => _actions.addStock(
        context,
        product,
        ShopActions.quickAddAmount,
      ),
      onRestock: (product) => _actions.restock(context, product),
    );
  }

  Widget _buildApprovalStatusBanner(ShopProfile shop) {
    if (shop.isPending) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Store Registration Under Review',
                    style: ShopText.title.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Your grocery shop registration is pending admin approval. Once approved by DashGrocer administrators, your shop will be listed and customers can place orders.',
                    style: ShopText.body.copyWith(
                      fontSize: 11,
                      color: const Color(0xFFB45309),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (shop.isRejected) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ShopColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registration Not Approved',
                    style: ShopText.title.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    shop.rejectionReason.isNotEmpty
                        ? 'Admin notice: ${shop.rejectionReason}. Please contact DashGrocer administration.'
                        : 'Your shop registration was not approved. Please contact DashGrocer administration for details.',
                    style: ShopText.body.copyWith(
                      fontSize: 11,
                      color: const Color(0xFFB91C1C),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Approved: verified partner badge
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: ShopColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verified Partner Store • Listed on DashGrocer Marketplace',
              style: ShopText.body.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF166534),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown at the top while the app runs on sample data instead of Firestore.
class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ShopColors.greenContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: ShopColors.onGreenContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Demo data. Firebase is not connected yet, so changes are '
              'lost when the app restarts.',
              style: ShopText.body.copyWith(color: ShopColors.onGreenContainer),
            ),
          ),
        ],
      ),
    );
  }
}
