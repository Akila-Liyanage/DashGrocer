import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/grocery_item_model.dart';
import '../models/owner_profile.dart';
import '../models/product.dart';
import '../models/seller_order_model.dart';
import '../models/shop_order.dart';
import '../models/shop_profile.dart';
import 'grocery_service.dart';
import 'shop_repository.dart';

/// Connects the shop owner screens to the app's shared [GroceryService].
///
/// Orders and products are NOT stored separately for the shop owner. They are
/// read from, and written to, the same [GroceryService] the customer screens
/// use. That is what makes the two sides work together:
///
///   - a customer places an order  -> it appears on the shop owner dashboard
///   - the owner changes its status -> the customer sees the new status
///   - the owner adds or edits a product -> the customer catalog changes
///
/// Shop settings (opening hours, pickup slots) and the owner's own profile
/// have no place in [GroceryService], so they are handled by [profiles]
/// (Firestore when Firebase is running, in memory otherwise).
class GroceryShopRepository implements ShopRepository {
  GroceryShopRepository({
    required this._profiles,
    required this.sellerId,
    required this.sellerName,
    required this._fallbackOwner,
    GroceryService? service,
  }) : _service = service ?? GroceryService();

  final GroceryService _service;
  final ShopRepository _profiles;
  final OwnerProfile _fallbackOwner;

  /// The logged-in shop owner's user id and shop name, saved on products
  /// this owner adds.
  final String sellerId;
  final String sellerName;

  // Details the shop owner screens use that GroceryService has no field for.
  // They are kept here for as long as the app stays open.
  final Map<String, String> _cancelReasons = <String, String>{};
  final Map<String, DateTime> _completedAt = <String, DateTime>{};
  final Map<String, List<int>> _packed = <String, List<int>>{};
  final Map<String, _ProductExtras> _productExtras = <String, _ProductExtras>{};

  /// Maps the id used by the shop owner screens to the GroceryService id.
  final Map<String, String> _storeOrderIds = <String, String>{};

  /// Bumped when one of the maps above changes, so the lists are re-sent.
  final ValueNotifier<int> _localChanges = ValueNotifier<int>(0);

  @override
  bool get isDemo => false;

  @override
  List<String> get productCategories {
    final names = _service.categories.map((category) => category.name).toList();
    return List<String>.unmodifiable(names);
  }

  /// The customer catalog lists every product, so there is nothing for an
  /// "Online Availability" switch to control.
  @override
  bool get supportsCatalogVisibility => false;

  /// The email is the login email, which sign-in manages.
  @override
  bool get canEditEmail => false;

  /// A stream that sends [read]'s result now and after every change.
  Stream<T> _watch<T>(T Function() read) {
    late final StreamController<T> controller;
    void emit() {
      if (!controller.isClosed) controller.add(read());
    }

    controller = StreamController<T>(
      onListen: () {
        emit();
        _service.addListener(emit);
        _localChanges.addListener(emit);
      },
      onCancel: () {
        _service.removeListener(emit);
        _localChanges.removeListener(emit);
      },
    );
    return controller.stream;
  }

  // ----------------------------------------------------------------- orders

  /// GroceryService status words <-> the shop owner screens' statuses.
  static OrderStatus _statusFromWord(String word) {
    switch (word.trim().toLowerCase()) {
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready for pickup':
      case 'ready':
        return OrderStatus.ready;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.newOrder; // 'Pending'
    }
  }

  static String _wordForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// The id the shop owner screens use for an order: its order number.
  /// Order numbers are unique, but if a list ever holds the same number
  /// twice, the later ones get "~1", "~2" added so every row stays distinct.
  /// (The id must not depend on anything that can change, such as a time
  /// read back from Firestore, or an open order would "disappear".)
  static String _keyFor(StoreOrder order, Map<String, int> seen) {
    final count = seen[order.id] ?? 0;
    seen[order.id] = count + 1;
    return count == 0 ? order.id : '${order.id}~$count';
  }

  /// "Today, 4.00 PM" or "Tomorrow, 9:00 AM - 9:30 AM" -> a real date and
  /// time, counted from the day the order was placed.
  static DateTime _parsePickup(String slot, DateTime createdAt) {
    final match = RegExp(r'(\d{1,2})[.:](\d{2})\s*([AaPp][Mm])')
        .firstMatch(slot);
    if (match == null) return createdAt.add(const Duration(hours: 1));

    var hour = int.parse(match.group(1)!) % 12;
    if (match.group(3)!.toLowerCase() == 'pm') hour += 12;
    final minute = int.parse(match.group(2)!);

    var day = DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (slot.toLowerCase().contains('tomorrow')) {
      day = day.add(const Duration(days: 1));
    }
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  /// "3 items (Carrots, Milk, Bread)" -> 3
  static int? _countFromSummary(String summary) {
    final match = RegExp(r'^\s*(\d+)\s+item').firstMatch(summary);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  ShopOrder _toShopOrder(StoreOrder order, Map<String, int> seen) {
    final key = _keyFor(order, seen);
    _storeOrderIds[key] = order.id;

    return ShopOrder(
      id: key,
      orderNumber: order.id.replaceFirst('#', ''),
      shopId: sellerId,
      customerId: '',
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      // GroceryService orders carry a text summary, not an item list.
      items: const <OrderItem>[],
      itemsSummary: order.itemsSummary,
      itemCountHint: _countFromSummary(order.itemsSummary),
      total: order.totalAmount,
      status: _statusFromWord(order.status),
      pickupTime: _parsePickup(order.pickupSlot, order.createdAt),
      createdAt: order.createdAt,
      // 'Pay at Store' or 'Paid Online (Card)', chosen by the customer.
      paymentMethod: order.paymentMethod,
      packedIndexes: _packed[key] ?? const <int>[],
      cancelReason: _cancelReasons[key],
      completedAt: _completedAt[key],
    );
  }

  @override
  Stream<List<ShopOrder>> watchOrders(String shopId) {
    return _watch(() {
      final seen = <String, int>{};
      return [
        for (final order in _service.sellerOrders) _toShopOrder(order, seen),
      ];
    });
  }

  @override
  Future<void> updateOrderStatus(
    ShopOrder order,
    OrderStatus status, {
    String? cancelReason,
  }) async {
    final storeId = _storeOrderIds[order.id];
    if (storeId == null) {
      throw StateError('Order ${order.orderNumber} was not found.');
    }

    // GroceryService changes the first order that has this number. A row
    // whose id has a "~1" style ending is a later duplicate, so stop instead
    // of changing the wrong order.
    if (storeId != order.id) {
      throw StateError(
        'Another order uses the number ${order.orderNumber}, so this one '
        'cannot be updated.',
      );
    }

    if (status == OrderStatus.cancelled && cancelReason != null) {
      _cancelReasons[order.id] = cancelReason;
    }
    if (status == OrderStatus.completed) {
      _completedAt[order.id] = DateTime.now();
    }
    // This is the same call the customer screens watch, so the customer
    // sees the new status straight away.
    _service.updateOrderStatus(storeId, _wordForStatus(status));
  }

  @override
  Future<void> setPackedItems(ShopOrder order, List<int> packedIndexes) async {
    _packed[order.id] = List<int>.unmodifiable(packedIndexes);
    _localChanges.value++;
  }

  // --------------------------------------------------------------- products

  Product _toProduct(GroceryItem item) {
    final extras = _productExtras[item.id];
    return Product(
      id: item.id,
      shopId: item.sellerId ?? sellerId,
      name: item.name,
      category: item.category,
      unit: item.unit,
      price: item.price,
      stock: item.stockQuantity,
      code: extras?.code ?? '',
      barcode: extras?.barcode ?? '',
      lowStockThreshold: extras?.lowStockThreshold ?? 10,
      imageUrl: item.imageUrl.isEmpty ? null : item.imageUrl,
    );
  }

  @override
  Stream<List<Product>> watchProducts(String shopId) {
    return _watch(() => _service.allItems.map(_toProduct).toList());
  }

  /// Finds the catalog item for a product. (GroceryService.getItemById is
  /// not used because it returns a different item when the id is missing.)
  GroceryItem _requireItem(Product product) {
    for (final item in _service.allItems) {
      if (item.id == product.id) return item;
    }
    throw StateError('${product.name} is no longer in the catalog.');
  }

  @override
  Future<void> addStock(Product product, int quantity) async {
    final item = _requireItem(product);
    final stock = item.stockQuantity + quantity;
    _service.updateProduct(item.copyWith(stockQuantity: stock < 0 ? 0 : stock));
  }

  @override
  Future<void> setStock(Product product, int stock) async {
    final item = _requireItem(product);
    _service.updateProduct(item.copyWith(stockQuantity: stock < 0 ? 0 : stock));
  }

  @override
  Future<void> saveProduct(Product product) async {
    final extras = _ProductExtras(
      code: product.code,
      barcode: product.barcode,
      lowStockThreshold: product.lowStockThreshold,
    );

    if (product.id.isEmpty) {
      final id = 'item_${DateTime.now().millisecondsSinceEpoch}';
      _productExtras[id] = extras;
      _service.addProduct(
        GroceryItem(
          id: id,
          name: product.name,
          unit: product.unit,
          price: product.price,
          category: product.category,
          imageUrl: product.imageUrl ?? '',
          isNew: true,
          sellerId: sellerId,
          sellerName: _fallbackOwner.fullName.isNotEmpty
              ? _fallbackOwner.fullName
              : sellerName,
          sellerShopName: sellerName,
          sellerPhone: _fallbackOwner.phoneNumber,
          stockQuantity: product.stock,
        ),
      );
      return;
    }

    final item = _requireItem(product);
    _productExtras[product.id] = extras;
    _service.updateProduct(
      item.copyWith(
        name: product.name,
        unit: product.unit,
        price: product.price,
        category: product.category,
        imageUrl: product.imageUrl ?? '',
        stockQuantity: product.stock,
      ),
    );
  }

  @override
  Future<void> deleteProduct(Product product) async {
    _productExtras.remove(product.id);
    _service.deleteProduct(product.id);
  }

  // ------------------------------------------------- shop and owner profile

  @override
  Stream<ShopProfile> watchShop(String shopId) => _profiles.watchShop(shopId);

  @override
  Future<void> saveShop(ShopProfile shop) => _profiles.saveShop(shop);

  /// Until the owner saves their profile, show the details they logged in
  /// with.
  @override
  Stream<OwnerProfile> watchOwner(String userId) {
    return _profiles.watchOwner(userId).map((saved) {
      final nothingSaved = saved.fullName.isEmpty && saved.email.isEmpty;
      if (!nothingSaved) return saved;
      return saved.hasPhoto
          ? _fallbackOwner.copyWith(photoUrl: saved.photoUrl)
          : _fallbackOwner;
    });
  }

  @override
  Future<void> saveOwner(OwnerProfile owner) => _profiles.saveOwner(owner);

  /// Only the shop's settings document is created here. The user document
  /// belongs to the login part, so it is never created from this side.
  @override
  Future<void> ensureProfiles({
    required ShopProfile shop,
    required OwnerProfile owner,
  }) {
    return _profiles.ensureProfiles(shop: shop, owner: owner);
  }

  @override
  Future<void> seedDemoData(String shopId) async {
    // GroceryService already comes with its own starting data.
  }
}

/// Product details the shop owner screens edit that GroceryItem cannot hold.
class _ProductExtras {
  const _ProductExtras({
    required this.code,
    required this.barcode,
    required this.lowStockThreshold,
  });

  final String code;
  final String barcode;
  final int lowStockThreshold;
}
