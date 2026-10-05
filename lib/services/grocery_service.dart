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

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  final List<StoreOrder> _sellerOrders = [];
  final List<SellerNotification> _sellerNotifications = [];

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
        id: 'nadu_rice',
        name: 'Nadu Rice',
        unit: '5 kg',
        price: 1480.00,
        circleColor: Color(0xFFF7EFE5),
        imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=500&q=80',
        category: 'Grocery',
        rating: 4.8,
        reviewsCount: 92,
        description: 'Authentic Nadu Rice selected from supreme crop harvests. Perfect long grains, naturally aromatic and cleaned with modern optical sorters.',
      ),
      const GroceryItem(
        id: 'avocado',
        name: 'Avacodo',
        unit: '500g',
        price: 700.00,
        isNew: true,
        circleColor: Color(0xFFEBF6EC),
        imageUrl: 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?auto=format&fit=crop&w=500&q=80',
        category: 'Fruits',
        rating: 4.7,
        reviewsCount: 48,
        description: 'Fresh butter avocado harvested at peak ripeness. Loaded with heart-healthy monounsaturated fatty acids and dietary potassium.',
      ),
      const GroceryItem(
        id: 'pineapple',
        name: 'Pineapple',
        unit: '250g',
        price: 300.00,
        isFavorite: true,
        circleColor: Color(0xFFFFF8E5),
        imageUrl: 'https://images.unsplash.com/photo-1550258987-190a2d41a8ba?auto=format&fit=crop&w=500&q=80',
        category: 'Fruits',
        rating: 4.6,
        reviewsCount: 34,
        description: 'Sweet, tropical pineapple cubes freshly sliced and sealed for hygiene. Packed with natural bromelain enzyme and immune boosting vitamin C.',
      ),
      const GroceryItem(
        id: 'fresh_fish',
        name: 'Fresh Fish',
        unit: '250g',
        price: 850.00,
        originalPrice: 1010.00,
        discountPercent: 16,
        circleColor: Color(0xFFFDECEC),
        imageUrl: 'https://images.unsplash.com/photo-1534948216015-843149f72be3?auto=format&fit=crop&w=500&q=80',
        category: 'Meat',
        rating: 4.5,
        reviewsCount: 56,
        description: 'Daily fresh catch from coastal fisheries. De-scaled, cleaned, and chilled to 2°C to ensure unparalleled freshness and flavor for curries or baking.',
      ),
      const GroceryItem(
        id: 'fresh_milk',
        name: 'Fresh Milk',
        unit: '1 l',
        price: 1500.00,
        isNew: true,
        circleColor: Color(0xFFEEF3FA),
        imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=500&q=80',
        category: 'Dairy',
        rating: 4.9,
        reviewsCount: 112,
        description: 'Pasteurized whole milk from local dairy farms. Wholesome nutrition for the entire family without any synthetic additives.',
      ),
      const GroceryItem(
        id: 'fresh_broccoli',
        name: 'Fresh Broccoli',
        unit: '1 kg',
        price: 750.00,
        isFavorite: true,
        circleColor: Color(0xFFE8F6EB),
        imageUrl: 'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?auto=format&fit=crop&w=500&q=80',
        category: 'Vegetables',
        rating: 4.7,
        reviewsCount: 68,
        description: 'Crunchy farm broccoli crowns with dense, tender florets. Sourced directly from highland farms, rich in sulforaphane, iron, and fiber.',
      ),
      const GroceryItem(
        id: 'chicken_breast',
        name: 'Chicken Breast 1KG',
        unit: '1.50 lbs',
        price: 1450.00,
        circleColor: Color(0xFFEAF5E4),
        imageUrl: 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=600&q=80',
        category: 'Meat',
        rating: 4.5,
        reviewsCount: 85,
        description: 'Fresh chicken breast is carefully selected from quality poultry and prepared for your convenience. It is a clean and tender cut of chicken with a mild flavour, making it suitable for a wide variety of dishes. Chicken breast is perfect for grilling, frying, baking, curries, salads, sandwiches, and healthy meal preparations. It is freshly packed to help maintain its quality and freshness.',
      ),
      const GroceryItem(
        id: 'red_onion',
        name: 'Red Onion',
        unit: '250 g',
        price: 300.00,
        circleColor: Color(0xFFFBECEC),
        imageUrl: 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?auto=format&fit=crop&w=500&q=80',
        category: 'Vegetables',
        rating: 4.6,
        reviewsCount: 78,
        description: 'Firm and pungent red onions with crisp outer skins and aromatic layers. The backbone of traditional cooking and salad garnishes.',
      ),
      const GroceryItem(
        id: 'carrot',
        name: 'Carrot',
        unit: '250 g',
        price: 400.00,
        isNew: true,
        circleColor: Color(0xFFEBF7ED),
        imageUrl: 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?auto=format&fit=crop&w=500&q=80',
        category: 'Vegetables',
        rating: 4.8,
        reviewsCount: 62,
        description: 'Sweet and crunchy orange carrots freshly dug and washed. High in beta-carotene for eye health and culinary vibrancy.',
      ),
      const GroceryItem(
        id: 'beans',
        name: 'Beans',
        unit: '250 g',
        price: 750.00,
        isFavorite: true,
        circleColor: Color(0xFFEAF6EC),
        imageUrl: 'https://images.unsplash.com/photo-1567375698348-5d9d5ae99de0?auto=format&fit=crop&w=500&q=80',
        category: 'Vegetables',
        rating: 4.7,
        reviewsCount: 41,
        description: 'Tender stringless snap green beans harvested fresh at dawn. Crisp snap, delicate flavor, and zero stringiness.',
      ),
      const GroceryItem(
        id: 'tomato',
        name: 'Tomato',
        unit: '250 g',
        price: 150.00,
        discountPercent: 17,
        circleColor: Color(0xFFFDECEB),
        imageUrl: 'https://images.unsplash.com/photo-1546470427-0d4db154ceb7?auto=format&fit=crop&w=500&q=80',
        category: 'Vegetables',
        rating: 4.5,
        reviewsCount: 94,
        description: 'Juicy, plump vine-ripened tomatoes rich in lycopene. Imparts rich flavor and luscious red color to curries, sauces, and salads.',
      ),
      const GroceryItem(
        id: 'pumpkin',
        name: 'Pumpkin',
        unit: '250 g',
        price: 620.00,
        circleColor: Color(0xFFFFF6E6),
        imageUrl: 'https://images.unsplash.com/photo-1570586437263-ab629fccc818?auto=format&fit=crop&w=500&q=80',
        category: 'Vegetables',
        rating: 4.6,
        reviewsCount: 39,
        description: 'Rich, golden-fleshed local pumpkin chunk. Velvety sweet texture when steamed, stewed, or pureed into comforting soup.',
      ),
      const GroceryItem(
        id: 'black_grapes',
        name: 'Black Grapes',
        unit: '250g',
        price: 450.00,
        circleColor: Color(0xFFF2EAF8),
        imageUrl: 'https://images.unsplash.com/photo-1537640538966-79f369143f8f?auto=format&fit=crop&w=500&q=80',
        category: 'Fruits',
        rating: 4.8,
        reviewsCount: 52,
        description: 'Seedless dark purple black grapes bursting with sweet-tart natural juice. High in resveratrol and flavonoids.',
      ),
    ];

    // Seed default cart matching Figma design exactly:
    _cartQuantities['fresh_broccoli'] = 5;
    _cartQuantities['black_grapes'] = 5;
    _cartQuantities['avocado'] = 3;
    _cartQuantities['chicken_breast'] = 1;
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
      return null;
    }
  }

  List<GroceryItem> getCategoryItems(String category) {
    return _items.where((item) => item.category.toLowerCase() == category.toLowerCase()).toList();
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
    _items.insert(0, item);
    notifyListeners();

    final firestore = _firestore;
    if (firestore != null) {
      firestore.collection('products').doc(item.id).set(item.toMap()).catchError((e) {
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
        firestore.collection('products').doc(updatedItem.id).set(updatedItem.toMap()).catchError((e) {
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
  String placeOrder({
    required String customerName,
    required String customerPhone,
    required String pickupSlot,
    required double totalAmount,
    required String shopName,
    String? orderId,
  }) {
    final generatedId = orderId ?? '#FP-2028-0${142 + _sellerOrders.length + 1}';
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
    );

    _sellerOrders.insert(0, order);

    // Push notification for the seller
    final notification = SellerNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Order: $generatedId',
      message: '$customerName placed a pickup order for Rs. ${totalAmount.toStringAsFixed(0)} ($pickupSlot).',
      time: DateTime.now(),
      orderId: generatedId,
      isRead: false,
    );

    _sellerNotifications.insert(0, notification);
    clearCart();
    notifyListeners();
    return generatedId;
  }

  void toggleOrderReady(String orderId) {
    final index = _sellerOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _sellerOrders[index];
      final newStatus = order.status == 'Ready for Pickup' ? 'Pending' : 'Ready for Pickup';
      _sellerOrders[index] = order.copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final index = _sellerOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _sellerOrders[index] = _sellerOrders[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void markNotificationsRead() {
    for (int i = 0; i < _sellerNotifications.length; i++) {
      _sellerNotifications[i] = _sellerNotifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }
}
