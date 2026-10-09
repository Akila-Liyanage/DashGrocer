import 'dart:async';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/shop_owner_theme.dart';
import '../../models/shop_order.dart';
import '../../services/chat_service.dart';
import '../../services/shop_repository.dart';
import '../../services/shop_store.dart';
import 'chat/messages_panel.dart';
import 'dashboard/dashboard_screen.dart';
import 'notifications/notifications_panel.dart';
import 'orders/order_details_screen.dart';
import 'orders/orders_screen.dart';
import 'products/products_screen.dart';
import 'profile/profile_screen.dart';
import 'profile/user_profile_screen.dart';
import 'sales/sales_summary_screen.dart';
import 'shop_actions.dart';
import 'widgets/dialogs.dart';
import 'widgets/shop_bottom_nav.dart';

/// Home of the shop owner side: the four tabs and the bottom navigation.
///
/// It is opened by `ShopOwnerDashboard` (shop_owner_dashboard.dart) after a
/// shop owner logs in. It owns the live data ([ShopStore]) and the actions
/// ([ShopActions]) and hands them to every screen.
class ShopOwnerShell extends StatefulWidget {
  const ShopOwnerShell({
    super.key,
    required this.repository,
    required this.shopId,
    required this.onLogout,
  });

  final ShopRepository repository;
  final String shopId;

  /// Called when the owner confirms "Log Out". Sign out and show the login
  /// screen here.
  final VoidCallback onLogout;

  @override
  State<ShopOwnerShell> createState() => _ShopOwnerShellState();
}

class _ShopOwnerShellState extends State<ShopOwnerShell> {
  static const int _dashboardTab = 0;
  static const int _ordersTab = 1;
  static const int _productsTab = 2;
  static const int _profileTab = 3;

  late final ShopStore _store;
  late final ShopActions _actions;
  StreamSubscription<ShopOrder>? _newOrderSub;

  int _index = _dashboardTab;

  /// Status filter of the Orders tab. Null means "All". Kept here so the
  /// Dashboard can open the Orders tab with a filter already chosen.
  OrderStatus? _ordersFilter;

  @override
  void initState() {
    super.initState();
    _store = ShopStore(repository: widget.repository, shopId: widget.shopId);
    _actions = ShopActions(_store);
    _newOrderSub = _store.newOrders.listen(_announceNewOrder);
  }

  @override
  void dispose() {
    _newOrderSub?.cancel();
    _store.dispose();
    super.dispose();
  }

  /// Tells the owner right away when an order arrives while the app is open.
  void _announceNewOrder(ShopOrder order) {
    if (!mounted || !_store.shop.orderNotifications) return;
    showAppMessage(
      ScaffoldMessenger.of(context),
      'New order #${order.orderNumber} from ${order.customerName}.',
    );
  }

  void _openOrders(OrderStatus? filter) {
    setState(() {
      _ordersFilter = filter;
      _index = _ordersTab;
    });
  }

  void _openProducts() => setState(() => _index = _productsTab);

  void _openOrder(ShopOrder order) {
    Navigator.of(context).push(
      shopRoute<void>(
        (context) => OrderDetailsScreen(
          store: _store,
          actions: _actions,
          orderId: order.id,
        ),
      ),
    );
  }

  void _openSales() {
    Navigator.of(context).push(
      shopRoute<void>((context) => SalesSummaryScreen(store: _store)),
    );
  }

  /// Opened by the profile icon in the header of every tab.
  void _openUserProfile() {
    Navigator.of(context).push(
      shopRoute<void>(
        (context) => UserProfileScreen(
          store: _store,
          actions: _actions,
          onOpenShopProfile: () => setState(() => _index = _profileTab),
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  void _openNotifications() {
    showNotificationsPanel(
      context,
      store: _store,
      actions: _actions,
      onOpenOrder: _openOrder,
      onOpenSettings: () => setState(() => _index = _profileTab),
    );
  }

  /// Opened by the round chat button above the bottom navigation.
  void _openChat() => showMessagesPanel(context);

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
                  color: ShopColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: ShopColors.primary.withValues(alpha: 0.35),
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
                    onTap: _openChat,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps each tab alive, so search text and scroll position
      // are still there when the owner comes back to a tab.
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            store: _store,
            actions: _actions,
            onOpenOrders: _openOrders,
            onOpenProducts: _openProducts,
            onOpenOrder: _openOrder,
            onOpenSales: _openSales,
            onOpenNotifications: _openNotifications,
            onOpenUserProfile: _openUserProfile,
            onOpenChat: _openChat,
          ),
          OrdersScreen(
            store: _store,
            actions: _actions,
            filter: _ordersFilter,
            onFilterChanged: (filter) =>
                setState(() => _ordersFilter = filter),
            onOpenOrder: _openOrder,
            onOpenNotifications: _openNotifications,
            onOpenUserProfile: _openUserProfile,
          ),
          ProductsScreen(
            store: _store,
            actions: _actions,
            onOpenNotifications: _openNotifications,
            onOpenUserProfile: _openUserProfile,
          ),
          ProfileScreen(
            store: _store,
            actions: _actions,
            onOpenNotifications: _openNotifications,
            onOpenUserProfile: _openUserProfile,
            onLogout: widget.onLogout,
          ),
        ],
      ),
      bottomNavigationBar: ShopBottomNav(
        currentIndex: _index,
        onChanged: (index) => setState(() => _index = index),
      ),
      floatingActionButton: _buildChatCircleButton(),
    );
  }
}
