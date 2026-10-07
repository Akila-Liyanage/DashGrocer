import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/grocery_item_model.dart';
import '../models/seller_order_model.dart';

class GroceryCategory {
  final String id;
  final String name;
  final IconData iconData;
  final Color bgColor;
  final Color iconColor;

  const GroceryCategory({
    required this.id,
    required this.name,
    required this.iconData,
    required this.bgColor,
    required this.iconColor,
  });
}

class GroceryService extends ChangeNotifier {
  static final GroceryService _instance = GroceryService._internal();
  factory GroceryService() => _instance;
  GroceryService._internal() {
    _initializeDefaultData();
    _listenToFirestoreProducts();
    _listenToFirestoreOrders();
  }

  final List<GroceryCategory> _categories = [
    const GroceryCategory(
      id: 'vegetables',
      name: 'Vegetables',
      iconData: Icons.eco_rounded,
      bgColor: Color(0xFFE8F6EB),
      iconColor: Color(0xFF48B02C),
    ),
    const GroceryCategory(
      id: 'fruits',
      name: 'Fruits',
      iconData: Icons.apple_rounded,
      bgColor: Color(0xFFFFF2E6),
      iconColor: Color(0xFFFF7A00),
    ),
    const GroceryCategory(
      id: 'beverages',
      name: 'Beverages',
      iconData: Icons.local_drink_rounded,
      bgColor: Color(0xFFFFF0E5),
      iconColor: Color(0xFFFF9800),
    ),
    const GroceryCategory(
      id: 'grocery',
      name: 'Grocery',
      iconData: Icons.shopping_bag_rounded,
      bgColor: Color(0xFFF3EBFA),
      iconColor: Color(0xFF9C27B0),
    ),
    const GroceryCategory(
      id: 'edible_oil',
      name: 'Edible oil',
      iconData: Icons.water_drop_rounded,
      bgColor: Color(0xFFE6F8FA),
      iconColor: Color(0xFF00ACC1),
    ),
    const GroceryCategory(
      id: 'household',
      name: 'Household',
      iconData: Icons.cleaning_services_rounded,
      bgColor: Color(0xFFEBF3FA),
      iconColor: Color(0xFF2196F3),
    ),
  ];

  late List<GroceryItem> _items;
  final Map<String, int> _cartQuantities = {};
  final List<String> _searchHistory = [
    'fresh Grocery',
    'bananas',
    'cheetos',
    'vegetables',
    'fruits',
    'discounted items',
    'fresh vegetables',
  ];
  final List<String> _discoverMore = [
    'fresh Grocery',
    'bananas',
    'cheetos',
    'vegetables',
    'fruits',
    'discounted items',
    'fresh vegetables',
  ];

  final List<StoreOrder> _customerOrders = [
    StoreOrder(
      id: 'ORD-8821',
      customerName: 'Kasun Perera',
      customerPhone: '+94 77 123 4567',
      itemsSummary: '2x Red Tomatoes, 1x Highland Carrots',
      totalAmount: 1850.00,
      pickupSlot: 'Today, 5:30 PM - 6:00 PM',
      shopName: 'GreenLeaf Fresh Mart',
      status: 'Ready for Pickup',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];

  List<StoreOrder> get customerOrders => List.unmodifiable(_customerOrders);

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _productsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;

  void _listenToFirestoreProducts() {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      _productsSub?.cancel();
      _productsSub = firestore.collection('products').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final firestoreItems = <GroceryItem>[];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              firestoreItems.add(GroceryItem.fromMap(data, doc.id));
            } catch (e) {
              debugPrint('Error parsing Firestore product doc ${doc.id}: $e');
            }
          }
          if (firestoreItems.isNotEmpty) {
            _items = firestoreItems;
            notifyListeners();
          }
        } else {
          // If Firestore products collection is empty, seed defaults safely
          for (final item in _items) {
            firestore.collection('products').doc(item.id).set(item.toMap(), SetOptions(merge: true)).catchError((_) {});
          }
        }
      }, onError: (e) {
        debugPrint('[GroceryService] Firestore products listener notice: $e');
      });
    } catch (e) {
      debugPrint('[GroceryService] Could not attach Firestore products listener: $e');
    }
  }

  void _listenToFirestoreOrders() {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      _ordersSub?.cancel();
      _ordersSub = firestore.collection('orders').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final firestoreOrders = <StoreOrder>[];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              // A document with no customer and no total is not a real
              // order (status-only documents were written by an older
              // version when a sample order was updated). Skip it.
              if (data['customerName'] == null && data['totalAmount'] == null) {
                continue;
              }
              firestoreOrders.add(StoreOrder(
                id: doc.id,
                customerName: data['customerName'] as String? ?? 'Customer',
                customerPhone: data['customerPhone'] as String? ?? '',
                itemsSummary: data['itemsSummary'] as String? ?? '',
                totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
                pickupSlot: data['pickupSlot'] as String? ?? 'Today',
                shopName: data['shopName'] as String? ?? 'GreenLeaf Fresh Mart',
                status: data['status'] as String? ?? 'Pending',
                createdAt: data['createdAt'] != null
                    ? (data['createdAt'] is Timestamp
                        ? (data['createdAt'] as Timestamp).toDate()
                        : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
                    : DateTime.now(),
                isRead: data['isRead'] as bool? ?? false,
                paymentMethod: data['paymentMethod'] as String? ?? 'Pay at Store',
              ));
            } catch (e) {
              debugPrint('Error parsing Firestore order doc ${doc.id}: $e');
            }
          }
          if (firestoreOrders.isNotEmpty) {
            // Newest first, the same order placeOrder() keeps locally.
            firestoreOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _sellerOrders.clear();
            _sellerOrders.addAll(firestoreOrders);
            notifyListeners();
          }
        }
      }, onError: (e) {
        debugPrint('[GroceryService] Firestore orders listener notice: $e');
      });
    } catch (e) {
      debugPrint('[GroceryService] Could not attach Firestore orders listener: $e');
    }
  }

  final List<StoreOrder> _sellerOrders = [];
  final List<SellerNotification> _sellerNotifications = [];
  final List<CustomerNotification> _customerNotifications = [];

  List<CustomerNotification> get customerNotifications => List.unmodifiable(_customerNotifications);
  int get unreadCustomerNotificationsCount => _customerNotifications.where((n) => !n.isRead).length;

  List<GroceryCategory> get categories => List.unmodifiable(_categories);
  List<GroceryItem> get allItems => List.unmodifiable(_items);
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  List<String> get discoverMore => List.unmodifiable(_discoverMore);
  List<StoreOrder> get sellerOrders => List.unmodifiable(_sellerOrders);
  List<SellerNotification> get sellerNotifications => List.unmodifiable(_sellerNotifications);
  int get unreadNotificationsCount => _sellerNotifications.where((n) => !n.isRead).length;

  void _initializeDefaultData() {
    _sellerOrders.addAll([
      StoreOrder(
        id: '#FP-2028-0142',
        customerName: 'Kasun Perera',
        customerPhone: '+94 77 123 4567',
        itemsSummary: '3 items (Carrots, Milk, Bread)',
        totalAmount: 940.0,
        pickupSlot: 'Today, 4:30 PM - 5:00 PM',
        shopName: 'GreenLeaf Fresh Mart',
        status: 'Pending',
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        isRead: false,
      ),
      StoreOrder(
        id: '#FP-2028-0141',
        customerName: 'Nimali Silva',
        customerPhone: '+94 71 888 2341',
        itemsSummary: '5 items (Eggs, Apples, Potatoes)',
        totalAmount: 1850.0,
        pickupSlot: 'Today, 5:00 PM - 5:30 PM',
        shopName: 'GreenLeaf Fresh Mart',
        status: 'Ready for Pickup',
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
        isRead: true,
      ),
      StoreOrder(
        id: '#FP-2028-0140',
        customerName: 'Chathura Fernando',
        customerPhone: '+94 76 555 9012',
        itemsSummary: '2 items (Rice 5kg, Dhal 1kg)',
        totalAmount: 1600.0,
        pickupSlot: 'Yesterday, 3:00 PM - 3:30 PM',
        shopName: 'GreenLeaf Fresh Mart',
        status: 'Completed',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ]);

    _sellerNotifications.addAll([
      SellerNotification(
        id: 'notif_init_1',
        title: 'New Pickup Order #FP-2028-0142',
        message: 'Kasun Perera placed an order for Rs. 940. Pickup slot: Today, 4:30 PM.',
        time: DateTime.now().subtract(const Duration(minutes: 12)),
        orderId: '#FP-2028-0142',
        isRead: false,
      ),
      SellerNotification(
        id: 'notif_init_2',
        title: 'Order Confirmed: #FP-2028-0141',
        message: 'Nimali Silva confirmed order pickup for 5:00 PM today.',
        time: DateTime.now().subtract(const Duration(hours: 1)),
        orderId: '#FP-2028-0141',
        isRead: true,
      ),
    ]);

    _items = [
      const GroceryItem(
        id: 'pumpkin',
        name: 'Fresh Pumpkin',
        unit: '1 kg',
        price: 420.00,
        originalPrice: 480.00,
        discountPercent: 12,
        isFavorite: true,
        circleColor: Color(0xFFFFF3E0),
        imageUrl: 'assets/images/pumpkin.png',
        category: 'Vegetables',
        rating: 4.8,
        reviewsCount: 64,
        description: 'Farm-fresh golden pumpkin with rich, velvety orange flesh and natural sweetness. Cut fresh upon order with firm rind and intact seeds. Packed with Vitamin A, beta-carotene, and dietary fiber, perfect for traditional Sri Lankan coconut curries, roasted wedges, and velvety soups.',
      ),
      const GroceryItem(
        id: 'tomato',
        name: 'Ripe Tomatoes',
        unit: '500 g',
        price: 280.00,
        originalPrice: 320.00,
        discountPercent: 12,
        isNew: true,
        circleColor: Color(0xFFFDECEB),
        imageUrl: 'assets/images/tomato.png',
        category: 'Vegetables',
        rating: 4.9,
        reviewsCount: 98,
        description: 'Sun-ripened, succulent red tomatoes picked at peak maturity. Plump, juicy, and packed with natural sweetness and vibrant acidity. Rich in lycopene, Vitamin C, and antioxidants. Essential for everyday curries, lunu miris, fresh salads, and homemade sauces.',
      ),
      const GroceryItem(
        id: 'red_onion',
        name: 'Crisp Red Onions',
        unit: '500 g',
        price: 380.00,
        originalPrice: 420.00,
        discountPercent: 10,
        circleColor: Color(0xFFF6ECFB),
        imageUrl: 'assets/images/red_onion.png',
        category: 'Vegetables',
        rating: 4.7,
        reviewsCount: 82,
        description: 'Premium pungent red onions with crisp outer skins and deep purplish layers. Delivers a sharp, aromatic punch when raw and a rich, sweet caramelization when sautéed. Rich in quercetin and antioxidants. The indispensable base for traditional tempering, curries, and garnishes.',
      ),
      const GroceryItem(
        id: 'beans',
        name: 'Fresh Green Beans',
        unit: '250 g',
        price: 240.00,
        originalPrice: 280.00,
        discountPercent: 14,
        isFavorite: true,
        circleColor: Color(0xFFE8F6EB),
        imageUrl: 'assets/images/beans.png',
        category: 'Vegetables',
        rating: 4.8,
        reviewsCount: 56,
        description: 'Crisp, tender stringless snap green beans harvested fresh at dawn from highland gardens. Vibrant emerald color with a refreshing crunch and sweet vegetable flavor. High in dietary fiber, Vitamin K, and folate. Ideal for Sri Lankan coconut bean curries, garlic stir-fries, and quick steaming.',
      ),
      const GroceryItem(
        id: 'carrot',
        name: 'Highland Carrots',
        unit: '500 g',
        price: 340.00,
        originalPrice: 390.00,
        discountPercent: 13,
        isNew: true,
        circleColor: Color(0xFFFFF0E6),
        imageUrl: 'assets/images/carrot.png',
        category: 'Vegetables',
        rating: 4.9,
        reviewsCount: 110,
        description: 'Sweet, crunchy highland farm carrots freshly pulled and washed with green tops. Vibrant orange hue packed with beta-carotene, lutein, and essential minerals for radiant health and vision. Delicious raw as crunchy snack sticks, or slow-cooked in curries, hearty stews, and fresh juices.',
      ),
      const GroceryItem(
        id: 'fresh_milk',
        name: 'Fresh Dairy Milk',
        unit: '1 L',
        price: 450.00,
        originalPrice: 500.00,
        discountPercent: 10,
        isNew: true,
        circleColor: Color(0xFFFFF0E5),
        imageUrl: 'assets/images/pumpkin.png',
        category: 'Beverages',
        rating: 4.9,
        reviewsCount: 88,
        description: 'Pure, fresh pasteurized whole dairy milk rich in calcium, protein, and essential nutrients. Daily morning delivery from local highland dairy farms.',
        sellerShopName: 'Daily Superette',
        sellerName: 'Kamal Perera',
        sellerPhone: '+94 77 234 5678',
        sellerAddress: 'No. 18, Station Road, Maharagama',
      ),
      const GroceryItem(
        id: 'farm_eggs',
        name: 'Farm Fresh Brown Eggs',
        unit: '10 Pack',
        price: 560.00,
        originalPrice: 620.00,
        discountPercent: 10,
        circleColor: Color(0xFFFFF3E0),
        imageUrl: 'assets/images/carrot.png',
        category: 'Grocery',
        rating: 4.8,
        reviewsCount: 74,
        description: 'Grade-A farm fresh brown eggs with rich golden yolks, high in protein and vitamins. Sourced daily from certified local poultry farms.',
        sellerShopName: 'Daily Superette',
        sellerName: 'Kamal Perera',
        sellerPhone: '+94 77 234 5678',
        sellerAddress: 'No. 18, Station Road, Maharagama',
      ),
      const GroceryItem(
        id: 'ceylon_tea',
        name: 'Ceylon Premium Black Tea',
        unit: '200 g',
        price: 480.00,
        originalPrice: 540.00,
        discountPercent: 11,
        isFavorite: true,
        circleColor: Color(0xFFF3EBFA),
        imageUrl: 'assets/images/beans.png',
        category: 'Beverages',
        rating: 4.9,
        reviewsCount: 105,
        description: 'Finest handpicked Ceylon BOPF black tea leaves from misty central hill country estates. Rich aroma with a bright golden infusion.',
        sellerShopName: 'Daily Superette',
        sellerName: 'Kamal Perera',
        sellerPhone: '+94 77 234 5678',
        sellerAddress: 'No. 18, Station Road, Maharagama',
      ),
      const GroceryItem(
        id: 'mysore_dhal',
        name: 'Mysore Red Dhal',
        unit: '1 kg',
        price: 390.00,
        originalPrice: 430.00,
        discountPercent: 9,
        circleColor: Color(0xFFFFF0E6),
        imageUrl: 'assets/images/red_onion.png',
        category: 'Grocery',
        rating: 4.7,
        reviewsCount: 62,
        description: 'Premium cleaned Mysore red lentils, quick-cooking and naturally high in iron and plant protein. Perfect for authentic Sri Lankan parippu curry.',
        sellerShopName: 'Daily Superette',
        sellerName: 'Kamal Perera',
        sellerPhone: '+94 77 234 5678',
        sellerAddress: 'No. 18, Station Road, Maharagama',
      ),
    ];

    // Seed default cart with the new fresh products:
    _cartQuantities['carrot'] = 2;
    _cartQuantities['tomato'] = 3;
    _cartQuantities['beans'] = 1;
    _cartQuantities['pumpkin'] = 1;
  }

  // Cart operations
  int getQuantity(String itemId) => _cartQuantities[itemId] ?? 0;

  int get totalCartItemCount {
    return _cartQuantities.values.fold(0, (total, qty) => total + qty);
  }

  List<GroceryItem> get cartItems {
    final list = <GroceryItem>[];
    for (final entry in _cartQuantities.entries) {
      if (entry.value > 0) {
        final item = getItemById(entry.key);
        if (item != null) {
          list.add(item.copyWith(inCartQuantity: entry.value));
        }
      }
    }
    return list;
  }

  double get subtotal {
    double sum = 0;
    for (final entry in _cartQuantities.entries) {
      final item = getItemById(entry.key);
      if (item != null) {
        sum += item.price * entry.value;
      }
    }
    return sum;
  }

  double get shippingFee => subtotal > 0 ? 450.0 : 0.0;
  double get totalOrderPrice => subtotal + shippingFee;

  void addToCart(String itemId, [int count = 1]) {
    final current = _cartQuantities[itemId] ?? 0;
    _cartQuantities[itemId] = current + count;
    notifyListeners();
  }

  void incrementQuantity(String itemId) {
    addToCart(itemId, 1);
  }

  void decrementQuantity(String itemId) {
    final current = _cartQuantities[itemId] ?? 0;
    if (current > 1) {
      _cartQuantities[itemId] = current - 1;
    } else {
      _cartQuantities.remove(itemId);
    }
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    _cartQuantities.remove(itemId);
    notifyListeners();
  }

  void clearCart() {
    _cartQuantities.clear();
    notifyListeners();
  }

  // Favorite toggle
  void toggleFavorite(String itemId) {
    final index = _items.indexWhere((element) => element.id == itemId);
    if (index != -1) {
      final item = _items[index];
      _items[index] = item.copyWith(isFavorite: !item.isFavorite);
      notifyListeners();
    }
  }

  List<GroceryItem> get favoriteItems {
    return _items.where((element) => element.isFavorite).toList();
  }

  GroceryItem? getItemById(String id) {
    try {
      return _items.firstWhere((element) => element.id == id);
    } catch (_) {
      if (_items.isNotEmpty) return _items.first;
      return null;
    }
  }

  List<GroceryItem> getCategoryItems(String category) {
    final cat = category.toLowerCase().trim();
    if (cat.isEmpty || cat == 'all' || cat == 'vegetables') {
      return _items;
    }
    final filtered = _items.where((item) => item.category.toLowerCase() == cat).toList();
    return filtered.isNotEmpty ? filtered : _items;
  }

  /// Returns all products belonging to a specific shop.
  List<GroceryItem> getItemsByShop(String shopName) {
    final target = shopName.trim().toLowerCase();
    if (target.isEmpty) return _items;
    final isGreenLeaf = target.contains('greenleaf') ||
        target.contains('green leaf') ||
        target.contains('green mart');

    final matched = _items.where((item) {
      final itemShop = item.displaySellerShopName.trim().toLowerCase();
      final itemSeller = (item.sellerName ?? '').trim().toLowerCase();
      final itemSellerShop = (item.sellerShopName ?? '').trim().toLowerCase();

      if (itemShop == target || itemSeller == target || itemSellerShop == target) {
        return true;
      }
      if (itemShop.contains(target) || target.contains(itemShop)) {
        return true;
      }
      if (isGreenLeaf &&
          (itemSellerShop.isEmpty ||
              itemSellerShop == 'greenleaf fresh mart' ||
              itemSellerShop == 'green mart')) {
        return true;
      }
      return false;
    }).toList();

    return matched;
  }

  // Search
  void addSearchQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _searchHistory.remove(trimmed);
    _searchHistory.insert(0, trimmed);
    if (_searchHistory.length > 15) {
      _searchHistory.removeLast();
    }
    notifyListeners();
  }

  void clearSearchHistory() {
    _searchHistory.clear();
    notifyListeners();
  }

  void clearDiscoverMore() {
    _discoverMore.clear();
    notifyListeners();
  }

  List<GroceryItem> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return _items.where((item) {
      return item.name.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();
  }

  // Seller Product Management (Adds directly to live catalog for Customers)
  void addProduct(GroceryItem item) {
    final index = _items.indexWhere((it) => it.id == item.id);
    if (index == -1) {
      _items.insert(0, item);
    } else {
      _items[index] = item;
    }
    notifyListeners();

    final firestore = _firestore;
    if (firestore != null) {
      firestore.collection('products').doc(item.id).set(item.toMap(), SetOptions(merge: true)).catchError((e) {
        debugPrint('Firestore save product error: $e');
      });
    }
  }

  void updateProduct(GroceryItem updatedItem) {
    final index = _items.indexWhere((it) => it.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();

      final firestore = _firestore;
      if (firestore != null) {
        firestore.collection('products').doc(updatedItem.id).set(updatedItem.toMap(), SetOptions(merge: true)).catchError((e) {
          debugPrint('Firestore update product error: $e');
        });
      }
    }
  }

  void deleteProduct(String id) {
    _items.removeWhere((it) => it.id == id);
    _cartQuantities.remove(id);
    notifyListeners();

    final firestore = _firestore;
    if (firestore != null) {
      firestore.collection('products').doc(id).delete().catchError((e) {
        debugPrint('Firestore delete product error: $e');
      });
    }
  }

  // Customer Order Placement with instant Seller Notification trigger
  /// The whole order as saved in Firestore. Status changes save this full
  /// map, so an order document never ends up holding only a status.
  Map<String, dynamic> _orderToMap(StoreOrder order) {
    return {
      'id': order.id,
      'customerName': order.customerName,
      'customerPhone': order.customerPhone,
      'itemsSummary': order.itemsSummary,
      'totalAmount': order.totalAmount,
      'pickupSlot': order.pickupSlot,
      'shopName': order.shopName,
      'status': order.status,
      'createdAt': order.createdAt.toIso8601String(),
      'isRead': order.isRead,
      'paymentMethod': order.paymentMethod,
    };
  }

  /// A new order number that no existing order uses, for example
  /// "#FP-41562237". It is based on the clock, so two phones do not produce
  /// the same number.
  String _newOrderId() {
    final stamp = (DateTime.now().millisecondsSinceEpoch % 100000000)
        .toString()
        .padLeft(8, '0');
    var id = '#FP-$stamp';
    var attempt = 1;
    while (_sellerOrders.any((o) => o.id == id)) {
      id = '#FP-$stamp-${attempt++}';
    }
    return id;
  }

  /// The order with this number, or null when there is none.
  StoreOrder? orderById(String orderId) {
    for (final order in _sellerOrders) {
      if (order.id == orderId) return order;
    }
    return null;
  }

  /// One customer's orders (matched by name or phone), newest first.
  List<StoreOrder> ordersForCustomer({required String name, String phone = ''}) {
    final wantedName = name.trim().toLowerCase();
    if (wantedName.isEmpty && phone.isEmpty) return const <StoreOrder>[];
    return _sellerOrders.where((o) {
      final sameName =
          wantedName.isNotEmpty && o.customerName.trim().toLowerCase() == wantedName;
      final samePhone = phone.isNotEmpty && o.customerPhone == phone;
      return sameName || samePhone;
    }).toList();
  }

  /// One customer's orders that are still in progress (not completed and
  /// not cancelled), newest first.
  List<StoreOrder> activeOrdersFor({required String name, String phone = ''}) {
    return ordersForCustomer(name: name, phone: phone)
        .where((o) => o.status != 'Completed' && o.status != 'Cancelled')
        .toList();
  }

  String placeOrder({
    required String customerName,
    required String customerPhone,
    required String pickupSlot,
    required double totalAmount,
    required String shopName,
    String? orderId,
    String paymentMethod = 'Pay at Store',
  }) {
    // Every order needs its own number. If the number passed in is already
    // used by another order, a fresh one is generated instead. Otherwise the
    // new order would overwrite the old one in Firestore.
    var generatedId = orderId ?? _newOrderId();
    if (_sellerOrders.any((o) => o.id == generatedId)) {
      generatedId = _newOrderId();
    }
    final itemsCount = totalCartItemCount;
    final itemsSummaryDesc = itemsCount > 0
        ? '$itemsCount items (${cartItems.map((e) => e.name).take(3).join(', ')}${itemsCount > 3 ? '...' : ''})'
        : '3 items (Selected Groceries)';

    final order = StoreOrder(
      id: generatedId,
      customerName: customerName,
      customerPhone: customerPhone,
      itemsSummary: itemsSummaryDesc,
      totalAmount: totalAmount,
      pickupSlot: pickupSlot,
      shopName: shopName,
      status: 'Pending',
      createdAt: DateTime.now(),
      isRead: false,
      paymentMethod: paymentMethod,
    );

    _sellerOrders.insert(0, order);

    final firestore = _firestore;
    if (firestore != null) {
      firestore.collection('orders').doc(order.id).set(_orderToMap(order), SetOptions(merge: true)).catchError((e) {
        debugPrint('Firestore save order error: $e');
      });
    }

    // Push notification for the seller
    final notification = SellerNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Order: $generatedId',
      message: '$customerName placed a pickup order for Rs. ${totalAmount.toStringAsFixed(0)} ($pickupSlot). Payment: $paymentMethod.',
      time: DateTime.now(),
      orderId: generatedId,
      isRead: false,
    );

    _sellerNotifications.insert(0, notification);

    // Confirmation notification for the customer
    _customerNotifications.insert(
      0,
      CustomerNotification(
        id: 'cnotif_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Order Placed: $generatedId',
        message: 'Your order at $shopName was placed successfully. Pickup: $pickupSlot. Total: Rs. ${totalAmount.toStringAsFixed(0)}.',
        time: DateTime.now(),
        orderId: generatedId,
      ),
    );
    clearCart();
    notifyListeners();
    return generatedId;
  }

  void addSellerNotification({
    required String title,
    required String message,
    String? orderId,
  }) {
    final notification = SellerNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      time: DateTime.now(),
      orderId: orderId,
      isRead: false,
    );
    _sellerNotifications.insert(0, notification);
    notifyListeners();
  }

  void toggleOrderReady(String orderId) {
    final index = _sellerOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _sellerOrders[index];
      final newStatus = order.status == 'Ready for Pickup' ? 'Pending' : 'Ready for Pickup';
      _sellerOrders[index] = order.copyWith(status: newStatus);
      notifyListeners();

      final firestore = _firestore;
      if (firestore != null) {
        firestore.collection('orders').doc(orderId).set(_orderToMap(_sellerOrders[index]), SetOptions(merge: true)).catchError((e) {
          debugPrint('Firestore toggle order ready error: $e');
        });
      }
    }
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final index = _sellerOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _sellerOrders[index] = _sellerOrders[index].copyWith(status: newStatus);
      notifyListeners();

      final firestore = _firestore;
      if (firestore != null) {
        firestore.collection('orders').doc(orderId).set(_orderToMap(_sellerOrders[index]), SetOptions(merge: true)).catchError((e) {
          debugPrint('Firestore update order status error: $e');
        });
      }
    }
  }

  void markCustomerNotificationsRead() {
    for (int i = 0; i < _customerNotifications.length; i++) {
      _customerNotifications[i] = _customerNotifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void markNotificationsRead() {
    for (int i = 0; i < _sellerNotifications.length; i++) {
      _sellerNotifications[i] = _sellerNotifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }
}
