import 'dart:async';

import '../models/owner_profile.dart';
import '../models/product.dart';
import '../models/shop_order.dart';
import '../models/shop_profile.dart';
import 'demo_data.dart';
import 'shop_repository.dart';

/// In-memory stand-in for Firestore. Used automatically when Firebase is not
/// configured yet, so the whole app can be tried on a phone first.
/// Changes are lost when the app restarts.
class MockShopRepository implements ShopRepository {
  MockShopRepository({
    String shopId = 'demo_shop',
    ShopProfile? shop,
    OwnerProfile? owner,
  })  : _orders = demoOrders(shopId),
        _products = demoProducts(shopId),
        _shop = shop ?? demoShop(shopId),
        _owner = owner ?? demoOwner(shopId);

  /// Small delay so loading spinners can be seen, like a real network call.
  static const Duration _latency = Duration(milliseconds: 300);

  List<ShopOrder> _orders;
  List<Product> _products;
  ShopProfile _shop;
  OwnerProfile _owner;

  final StreamController<List<ShopOrder>> _orderEvents =
      StreamController<List<ShopOrder>>.broadcast();
  final StreamController<List<Product>> _productEvents =
      StreamController<List<Product>>.broadcast();
  final StreamController<ShopProfile> _shopEvents =
      StreamController<ShopProfile>.broadcast();
  final StreamController<OwnerProfile> _ownerEvents =
      StreamController<OwnerProfile>.broadcast();

  @override
  bool get isDemo => true;

  @override
  List<String> get productCategories => kProductCategories;

  @override
  bool get supportsCatalogVisibility => true;

  @override
  bool get canEditEmail => true;

  @override
  Stream<List<ShopOrder>> watchOrders(String shopId) async* {
    yield List<ShopOrder>.unmodifiable(_orders);
    yield* _orderEvents.stream;
  }

  @override
  Stream<List<Product>> watchProducts(String shopId) async* {
    yield List<Product>.unmodifiable(_products);
    yield* _productEvents.stream;
  }

  @override
  Stream<ShopProfile> watchShop(String shopId) async* {
    yield _shop;
    yield* _shopEvents.stream;
  }

  void _replaceOrder(String id, ShopOrder Function(ShopOrder) change) {
    _orders = [
      for (final order in _orders) order.id == id ? change(order) : order,
    ];
    _orderEvents.add(List<ShopOrder>.unmodifiable(_orders));
  }

  void _replaceProduct(String id, Product Function(Product) change) {
    _products = [
      for (final product in _products)
        product.id == id ? change(product) : product,
    ];
    _productEvents.add(List<Product>.unmodifiable(_products));
  }

  @override
  Future<void> updateOrderStatus(
    ShopOrder order,
    OrderStatus status, {
    String? cancelReason,
  }) async {
    await Future<void>.delayed(_latency);
    _replaceOrder(
      order.id,
      (existing) => existing.copyWith(
        status: status,
        cancelReason: status == OrderStatus.cancelled ? cancelReason : null,
        completedAt: status == OrderStatus.completed ? DateTime.now() : null,
      ),
    );
  }

  @override
  Future<void> setPackedItems(ShopOrder order, List<int> packedIndexes) async {
    _replaceOrder(
      order.id,
      (existing) => existing.copyWith(packedIndexes: packedIndexes),
    );
  }

  @override
  Future<void> addStock(Product product, int quantity) async {
    await Future<void>.delayed(_latency);
    _replaceProduct(
      product.id,
      (existing) => existing.copyWith(
        stock: existing.stock + quantity,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> setStock(Product product, int stock) async {
    await Future<void>.delayed(_latency);
    _replaceProduct(
      product.id,
      (existing) => existing.copyWith(stock: stock, updatedAt: DateTime.now()),
    );
  }

  @override
  Future<void> saveProduct(Product product) async {
    await Future<void>.delayed(_latency);
    final now = DateTime.now();
    if (product.id.isEmpty) {
      _products = [
        ..._products,
        product.copyWith(
          id: 'local_${now.microsecondsSinceEpoch}',
          updatedAt: now,
        ),
      ];
      _productEvents.add(List<Product>.unmodifiable(_products));
    } else {
      _replaceProduct(product.id, (_) => product.copyWith(updatedAt: now));
    }
  }

  @override
  Future<void> deleteProduct(Product product) async {
    await Future<void>.delayed(_latency);
    _products = [
      for (final existing in _products)
        if (existing.id != product.id) existing,
    ];
    _productEvents.add(List<Product>.unmodifiable(_products));
  }

  @override
  Future<void> saveShop(ShopProfile shop) async {
    _shop = shop;
    _shopEvents.add(_shop);
  }

  @override
  Stream<OwnerProfile> watchOwner(String userId) async* {
    yield _owner;
    yield* _ownerEvents.stream;
  }

  @override
  Future<void> saveOwner(OwnerProfile owner) async {
    await Future<void>.delayed(_latency);
    _owner = owner;
    _ownerEvents.add(_owner);
  }

  @override
  Future<void> ensureProfiles({
    required ShopProfile shop,
    required OwnerProfile owner,
  }) async {
    // The profiles passed to the constructor are already in place.
  }

  @override
  Future<void> seedDemoData(String shopId) async {
    // The demo data is already loaded.
  }
}
