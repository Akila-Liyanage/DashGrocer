import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/owner_profile.dart';
import '../models/product.dart';
import '../models/shop_order.dart';
import '../models/shop_profile.dart';
import 'demo_data.dart';
import 'shop_repository.dart';

/// Firestore storage for the shop owner side. In this app only the shop
/// settings and owner profile parts are used (through GroceryShopRepository);
/// orders and products come from the shared GroceryService instead.
/// Collections used:
///
///   users/{userId}           see OwnerProfile.toMap
///   shops/{shopId}           see ShopProfile.toMap
///   orders/{orderId}         see ShopOrder.toMap
///   products/{productId}     see Product.toMap
///   notifications/{id}       messages for customers (FR-07)
///
/// The order and product queries filter on `shopId` only and the screens sort
/// on the phone, so no composite Firestore index is needed.
class FirestoreShopRepository implements ShopRepository {
  FirestoreShopRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _shops =>
      _db.collection('shops');

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  @override
  bool get isDemo => false;

  @override
  List<String> get productCategories => kProductCategories;

  @override
  bool get supportsCatalogVisibility => true;

  @override
  bool get canEditEmail => true;

  @override
  Stream<List<ShopOrder>> watchOrders(String shopId) {
    return _orders.where('shopId', isEqualTo: shopId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ShopOrder.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<Product>> watchProducts(String shopId) {
    return _products.where('shopId', isEqualTo: shopId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Stream<ShopProfile> watchShop(String shopId) {
    // A shop with no document yet simply shows the default settings.
    return _shops.doc(shopId).snapshots().map(
          (doc) => ShopProfile.fromMap(
            doc.id,
            doc.data() ?? const <String, dynamic>{},
          ),
        );
  }

  @override
  Future<void> updateOrderStatus(
    ShopOrder order,
    OrderStatus status, {
    String? cancelReason,
  }) {
    final batch = _db.batch();

    final changes = <String, dynamic>{
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == OrderStatus.completed) {
      changes['completedAt'] = FieldValue.serverTimestamp();
    }
    if (status == OrderStatus.cancelled) {
      changes['cancelReason'] = cancelReason ?? '';
    }
    batch.update(_orders.doc(order.id), changes);

    // FR-07: tell the customer. The customer app reads this collection
    // filtered by `userId`.
    String? title;
    String? body;
    String? type;
    if (status == OrderStatus.ready) {
      type = 'order_ready';
      title = 'Order #${order.orderNumber} is ready';
      body = 'Your order is packed and ready for pickup.';
    } else if (status == OrderStatus.cancelled) {
      type = 'order_cancelled';
      title = 'Order #${order.orderNumber} was cancelled';
      body = (cancelReason == null || cancelReason.isEmpty)
          ? 'The shop could not accept your order.'
          : 'The shop could not accept your order: $cancelReason';
    }
    if (type != null && order.customerId.isNotEmpty) {
      batch.set(_notifications.doc(), <String, dynamic>{
        'userId': order.customerId,
        'shopId': order.shopId,
        'orderId': order.id,
        'type': type,
        'title': title,
        'body': body,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return batch.commit();
  }

  @override
  Future<void> setPackedItems(ShopOrder order, List<int> packedIndexes) {
    return _orders.doc(order.id).update(<String, dynamic>{
      'packedIndexes': packedIndexes,
    });
  }

  @override
  Future<void> addStock(Product product, int quantity) {
    return _products.doc(product.id).update(<String, dynamic>{
      'stock': FieldValue.increment(quantity),
      'stockQuantity': FieldValue.increment(quantity),
      'isAvailable': true,
      'isActive': true,
      'status': 'active',
      'productStatus': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setStock(Product product, int stock) {
    final effectiveStock = stock < 0 ? 0 : stock;
    final isAvail = effectiveStock > 0;
    return _products.doc(product.id).update(<String, dynamic>{
      'stock': effectiveStock,
      'stockQuantity': effectiveStock,
      'isAvailable': isAvail,
      'isActive': isAvail,
      'status': isAvail ? 'active' : 'inactive',
      'productStatus': isAvail ? 'active' : 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> saveProduct(Product product) async {
    final data = product.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    if (product.id.isEmpty) {
      await _products.add(data);
    } else {
      await _products.doc(product.id).set(data, SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteProduct(Product product) {
    return _products.doc(product.id).delete();
  }

  @override
  Future<void> saveShop(ShopProfile shop) {
    return _shops.doc(shop.id).set(shop.toMap(), SetOptions(merge: true));
  }

  @override
  Stream<OwnerProfile> watchOwner(String userId) {
    // A user with no document yet simply shows an empty profile.
    return _users.doc(userId).snapshots().map(
          (doc) => OwnerProfile.fromMap(
            doc.id,
            doc.data() ?? const <String, dynamic>{},
          ),
        );
  }

  @override
  Future<void> saveOwner(OwnerProfile owner) {
    final data = owner.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    // merge: true changes only these fields. The user's role, shop name and
    // everything else saved by the login part are left exactly as they are.
    return _users.doc(owner.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> ensureProfiles({
    required ShopProfile shop,
    required OwnerProfile owner,
  }) async {
    final shopDoc = _shops.doc(shop.id);
    if (!(await shopDoc.get()).exists) {
      await shopDoc.set(shop.toMap());
    }
    // The user document is created by the login part when the account is
    // registered, so it is never created here.
  }

  @override
  Future<void> seedDemoData(String shopId) {
    final batch = _db.batch();
    for (final order in demoOrders(shopId)) {
      batch.set(_orders.doc(order.id), order.toMap());
    }
    for (final product in demoProducts(shopId)) {
      final data = product.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      batch.set(_products.doc(product.id), data);
    }
    return batch.commit();
  }
}
