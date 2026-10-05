import 'package:flutter/material.dart';

import '../../core/theme/shop_owner_theme.dart';
import '../../models/shop_order.dart';
import '../../services/shop_store.dart';
import '../dashboard/shop_actions.dart';
import '../dashboard/widgets/filter_pill.dart';
import '../dashboard/widgets/info_card.dart';
import '../dashboard/widgets/shop_owner_app_bar.dart';
import 'order_card.dart';

enum OrderSort {
  earliestPickup('Pickup: Earliest First'),
  latestPickup('Pickup: Latest First'),
  newest('Newest Orders First');

  const OrderSort(this.label);

  final String label;
}

/// Order Queue (FR-08): every order for the shop, with search, status
/// filters and sorting. Each card has the next step as its main button
/// (FR-06).
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    required this.store,
    required this.actions,
    required this.filter,
    required this.onFilterChanged,
    required this.onOpenOrder,
    required this.onOpenNotifications,
    required this.onOpenUserProfile,
  });

  final ShopStore store;
  final ShopActions actions;

  /// Selected status filter. Null means "All". It is owned by the shell so
  /// the Dashboard can open this tab with a filter already chosen.
  final OrderStatus? filter;
  final ValueChanged<OrderStatus?> onFilterChanged;
  final ValueChanged<ShopOrder> onOpenOrder;
  final VoidCallback onOpenNotifications;

  /// Opens the owner's "My Profile" screen (the profile icon in the header).
  final VoidCallback onOpenUserProfile;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _search = TextEditingController();
  OrderSort _sort = OrderSort.earliestPickup;

  ShopStore get _store => widget.store;
  ShopActions get _actions => widget.actions;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Orders matching the filter chip and the search text, in sort order.
  List<ShopOrder> _visibleOrders(List<ShopOrder> orders) {
    final query = _search.text.trim().toLowerCase();

    final result = orders.where((order) {
      if (widget.filter != null && order.status != widget.filter) return false;
      if (query.isEmpty) return true;
      return order.orderNumber.toLowerCase().contains(query) ||
          order.customerName.toLowerCase().contains(query) ||
          order.customerPhone.contains(query);
    }).toList();

    switch (_sort) {
      case OrderSort.earliestPickup:
        result.sort((a, b) => a.pickupTime.compareTo(b.pickupTime));
      case OrderSort.latestPickup:
        result.sort((a, b) => b.pickupTime.compareTo(a.pickupTime));
      case OrderSort.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return result;
  }

  void _runNextAction(ShopOrder order) {
    switch (order.status) {
      case OrderStatus.newOrder:
        _actions.startPreparing(context, order);
      case OrderStatus.preparing:
        _actions.markReady(context, order);
      case OrderStatus.ready:
        _actions.completeOrder(context, order);
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, child) {
        final orders = _store.orders;

        return Scaffold(
          appBar: ShopOwnerAppBar(
            owner: _store.owner,
            onProfile: widget.onOpenUserProfile,
            onNotifications: widget.onOpenNotifications,
            unreadCount: _store.unreadAlertCount,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Order Queue', style: ShopText.heading),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _search,
                      style: ShopText.input,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      decoration: ShopDecor.input(
                        hint: 'Search order number or customer',
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: ShopColors.primary,
                        ),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              FilterPillRow(
                children: [
                  FilterPill(
                    label: 'All',
                    count: orders?.length,
                    selected: widget.filter == null,
                    onTap: () => widget.onFilterChanged(null),
                  ),
                  for (final status in OrderStatus.values)
                    FilterPill(
                      label: status.label,
                      count: _store.countByStatus(status),
                      selected: widget.filter == status,
                      onTap: () => widget.onFilterChanged(status),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _SortMenu(
                    value: _sort,
                    onChanged: (sort) => setState(() => _sort = sort),
                  ),
                ),
              ),
              Expanded(child: _buildList(orders)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(List<ShopOrder>? orders) {
    const listPadding = EdgeInsets.fromLTRB(16, 4, 16, 24);

    if (_store.ordersError != null && orders == null) {
      return ListView(
        padding: listPadding,
        children: [InfoCard.loadError(what: 'orders')],
      );
    }
    if (orders == null) {
      return ListView(padding: listPadding, children: const [LoadingCard()]);
    }

    final visible = _visibleOrders(orders);
    if (visible.isEmpty) {
      final searching = _search.text.trim().isNotEmpty;
      final filterLabel = widget.filter?.label.toLowerCase();
      return ListView(
        padding: listPadding,
        children: [
          InfoCard(
            icon: searching ? Icons.search_off : Icons.assignment_outlined,
            title: searching ? 'No matching orders' : 'No orders here',
            message: searching
                ? 'Check the order number or customer name and try again.'
                : filterLabel == null
                    ? 'Customer pre-orders will appear here.'
                    : 'There are no $filterLabel orders right now.',
          ),
        ],
      );
    }

    final now = DateTime.now();
    return ListView.separated(
      padding: listPadding,
      itemCount: visible.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = visible[index];
        return OrderCard(
          key: ValueKey(order.id),
          order: order,
          now: now,
          busy: _store.isBusy(order.id),
          onDetails: () => widget.onOpenOrder(order),
          onCall: () => _actions.callCustomer(context, order.customerPhone),
          onAction: () => _runNextAction(order),
        );
      },
    );
  }
}

/// The "Pickup: Earliest First" drop-down above the list.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.value, required this.onChanged});

  final OrderSort value;
  final ValueChanged<OrderSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<OrderSort>(
      tooltip: 'Sort orders',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final sort in OrderSort.values)
          PopupMenuItem<OrderSort>(value: sort, child: Text(sort.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: ShopDecor.tile(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.label,
              style: ShopText.label.copyWith(color: ShopColors.textPrimary),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.expand_more,
              size: 16,
              color: ShopColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
