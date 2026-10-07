import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/formatters.dart';
import '../models/owner_profile.dart';
import '../models/product.dart';
import '../models/shop_alert.dart';
import '../models/shop_order.dart';
import '../models/shop_profile.dart';
import 'shop_repository.dart';

/// Holds the live data for one shop and tells the screens when it changes.
///
/// Every shop owner screen listens to this one object, so the Dashboard,
/// Orders, Products and Profile tabs always show the same numbers.
class ShopStore extends ChangeNotifier {
  ShopStore({required this.repository, required this.shopId})
      : shop = ShopProfile(id: shopId),
        owner = OwnerProfile(id: shopId) {
    _orderSub = repository.watchOrders(shopId).listen(
      _onOrders,
      onError: (Object error) {
        debugPrint('Orders stream failed: $error');
        ordersError = error;
        notifyListeners();
      },
    );
    _productSub = repository.watchProducts(shopId).listen(
      (list) {
        products = list;
        productsError = null;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Products stream failed: $error');
        productsError = error;
        notifyListeners();
      },
    );
    _shopSub = repository.watchShop(shopId).listen(
      (profile) {
        shop = profile;
        notifyListeners();
      },
      onError: (Object error) => debugPrint('Shop stream failed: $error'),
    );
    // One owner has one shop, so the owner's user id is the shop id.
    _ownerSub = repository.watchOwner(shopId).listen(
      (profile) {
        owner = profile;
        notifyListeners();
      },
      onError: (Object error) => debugPrint('Owner stream failed: $error'),
    );

    // Rebuild twice a minute so "in 35m" style labels keep counting down.
    _clock = Timer.periodic(
      const Duration(seconds: 30),
      (_) => notifyListeners(),
    );
  }

  final ShopRepository repository;
  final String shopId;

  /// Null until the first result arrives.
  List<ShopOrder>? orders;
  Object? ordersError;

  /// Null until the first result arrives.
  List<Product>? products;
  Object? productsError;

  ShopProfile shop;

  /// The logged-in owner's personal details (the "My Profile" screen).
  OwnerProfile owner;

  StreamSubscription<List<ShopOrder>>? _orderSub;
  StreamSubscription<List<Product>>? _productSub;
  StreamSubscription<ShopProfile>? _shopSub;
  StreamSubscription<OwnerProfile>? _ownerSub;
  Timer? _clock;
  bool _disposed = false;

  final Set<String> _busyIds = <String>{};
  Set<String>? _knownOrderIds;
  final StreamController<ShopOrder> _newOrderController =
      StreamController<ShopOrder>.broadcast();

  /// Fires when a new order arrives while the app is open.
  Stream<ShopOrder> get newOrders => _newOrderController.stream;

  bool get isDemo => repository.isDemo;

  // ----------------------------------------------------------------- orders

  void _onOrders(List<ShopOrder> list) {
    final known = _knownOrderIds;
    if (known != null) {
      final cutoff = DateTime.now().subtract(const Duration(minutes: 2));
      for (final order in list) {
        final isFresh = order.status == OrderStatus.newOrder &&
            !known.contains(order.id) &&
            order.createdAt.isAfter(cutoff);
        if (isFresh) _newOrderController.add(order);
      }
    }
    _knownOrderIds = list.map((order) => order.id).toSet();
    orders = list;
    ordersError = null;
    notifyListeners();
  }

  ShopOrder? orderById(String id) {
    for (final order in orders ?? const <ShopOrder>[]) {
      if (order.id == id) return order;
    }
    return null;
  }

  /// Null while orders are still loading.
  int? countByStatus(OrderStatus status) {
    return orders?.where((order) => order.status == status).length;
  }

  /// New and Preparing orders, the most urgent pickup first.
  List<ShopOrder> get actionQueue {
    final queue = (orders ?? const <ShopOrder>[])
        .where((order) => order.needsAction)
        .toList()
      ..sort((a, b) => a.pickupTime.compareTo(b.pickupTime));
    return queue;
  }

  // --------------------------------------------------------------- products

  Product? productById(String id) {
    for (final product in products ?? const <Product>[]) {
      if (product.id == id) return product;
    }
    return null;
  }

  /// Products at or below their low stock level, the emptiest first.
  List<Product> get lowStockProducts {
    final low = (products ?? const <Product>[])
        .where((product) => product.isLowStock)
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));
    return low;
  }

  // ----------------------------------------------------------------- alerts

  /// The notifications panel content, unread first and newest first.
  List<ShopAlert> get alerts {
    final now = DateTime.now();
    final readAt = shop.notificationsReadAt;

    bool isUnread(DateTime? time) {
      if (readAt == null) return true;
      return time != null && time.isAfter(readAt);
    }

    final result = <ShopAlert>[];

    for (final order in orders ?? const <ShopOrder>[]) {
      if (order.status == OrderStatus.newOrder && shop.orderNotifications) {
        result.add(
          ShopAlert(
            id: 'new_${order.id}',
            type: ShopAlertType.newOrder,
            title: 'New Order #${order.orderNumber}',
            body: '${order.customerName} ordered ${order.itemCountLabel} '
                '(${formatRs(order.total)}) for '
                '${formatClock(order.pickupTime)} pickup.',
            time: order.createdAt,
            unread: isUnread(order.createdAt),
            order: order,
          ),
        );
      }

      final dueFrom = order.pickupTime.subtract(const Duration(minutes: 15));
      if (order.needsAction && !now.isBefore(dueFrom)) {
        result.add(
          ShopAlert(
            id: 'due_${order.id}',
            type: ShopAlertType.pickupDue,
            title: 'Pickup due: Order #${order.orderNumber}',
            body: '${order.customerName} collects at '
                '${formatClock(order.pickupTime)} and the order is not '
                'ready yet.',
            time: dueFrom,
            unread: isUnread(dueFrom),
            order: order,
          ),
        );
      }
    }

    for (final product in lowStockProducts) {
      final units = product.stock == 1 ? '1 unit' : '${product.stock} units';
      result.add(
        ShopAlert(
          id: 'stock_${product.id}',
          type: ShopAlertType.lowStock,
          title: product.isOutOfStock
              ? 'Out of Stock: ${product.name}'
              : 'Low Stock: ${product.name}',
          body: product.isOutOfStock
              ? 'Customers cannot order this until it is restocked.'
              : 'Only $units remaining on the shelf.',
          time: product.updatedAt,
          unread: isUnread(product.updatedAt),
          product: product,
        ),
      );
    }

    final oldest = DateTime.fromMillisecondsSinceEpoch(0);
    result.sort((a, b) {
      if (a.unread != b.unread) return a.unread ? -1 : 1;
      return (b.time ?? oldest).compareTo(a.time ?? oldest);
    });
    return result;
  }

  int get unreadAlertCount => alerts.where((alert) => alert.unread).length;

  // ------------------------------------------------------------- busy state

  /// True while a change to this order or product is being saved.
  bool isBusy(String id) => _busyIds.contains(id);

  void setBusy(String id, bool busy) {
    if (busy) {
      _busyIds.add(id);
    } else {
      _busyIds.remove(id);
    }
    notifyListeners();
  }

  @override
  void notifyListeners() {
    // A save can finish after the owner has logged out and this was disposed.
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _clock?.cancel();
    _orderSub?.cancel();
    _productSub?.cancel();
    _shopSub?.cancel();
    _ownerSub?.cancel();
    _newOrderController.close();
    super.dispose();
  }
}
