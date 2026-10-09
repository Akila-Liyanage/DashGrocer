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

  void initFirebaseListeners() {
    _listenToFirestoreProducts();
    _listenToFirestoreOrders();
  }

  bool _hasInitialFirestoreProductsSync = false;

  void _listenToFirestoreProducts() {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      _productsSub?.cancel();
      _productsSub = firestore.collection('products').snapshots().listen((snapshot) {
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
          firestoreItems.sort((a, b) {
            final aTime = a.createdAt?.millisecondsSinceEpoch ?? (a.isNew ? 9999999999999 : 0);
            final bTime = b.createdAt?.millisecondsSinceEpoch ?? (b.isNew ? 9999999999999 : 0);
            return bTime.compareTo(aTime);
          });
          _items = firestoreItems;
          notifyListeners();
        } else if (snapshot.docs.isEmpty && _hasInitialFirestoreProductsSync) {
          // If Firestore collection is empty, retain local demo catalog or trigger seeder
          if (_items.isEmpty) {
            _initializeDefaultData();
            notifyListeners();
          }
        }
        _hasInitialFirestoreProductsSync = true;
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
                cancelReason: data['cancelReason'] as String?,
                cancelledByCustomer: data['cancelledByCustomer'] as bool? ?? false,
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

  void markAllCustomerNotificationsAsRead() {
    for (int i = 0; i < _customerNotifications.length; i++) {
      _customerNotifications[i] = _customerNotifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void addCustomerNotification({
    required String title,
    required String message,
    String? orderId,
  }) {
    _customerNotifications.insert(
      0,
      CustomerNotification(
        id: 'cust_notif_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        timeAgo: 'Just now',
        time: DateTime.now(),
        orderId: orderId,
        isRead: false,
      ),
    );
    notifyListeners();
  }

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
        paymentMethod: 'Pay at Store',
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
        paymentMethod: 'Paid Online (Card)',
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
        paymentMethod: 'Paid Online (Card)',
      ),
      StoreOrder(
        id: '#FP-2028-0139',
        customerName: 'Ayesha Madushani',
        customerPhone: '+94 72 345 6789',
        itemsSummary: '4 items (Yogurt, Butter, Tea, Sugar)',
        totalAmount: 3250.0,
        pickupSlot: '3 days ago, 11:00 AM - 11:30 AM',
        shopName: 'GreenLeaf Fresh Mart',
        status: 'Completed',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
        paymentMethod: 'Paid Online (Card)',
      ),
      StoreOrder(
        id: '#DS-2028-0098',
        customerName: 'Sunil Weerasinghe',
        customerPhone: '+94 77 999 1122',
        itemsSummary: '6 items (Cooking Oil, Flour, Oats, Biscuits)',
        totalAmount: 4200.0,
        pickupSlot: 'Today, 2:00 PM - 2:30 PM',
        shopName: 'Daily Superette',
        status: 'Completed',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: true,
        paymentMethod: 'Paid Online (Card)',
      ),
      StoreOrder(
        id: '#DS-2028-0097',
        customerName: 'Ruwan Kumara',
        customerPhone: '+94 75 123 9876',
        itemsSummary: '3 items (Pumpkin, Leeks, Tomatoes)',
        totalAmount: 1120.0,
        pickupSlot: 'Today, 6:00 PM - 6:30 PM',
        shopName: 'Daily Superette',
        status: 'Ready for Pickup',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        paymentMethod: 'Pay at Store',
      ),
      StoreOrder(
        id: '#DS-2028-0096',
        customerName: 'Priyanka Senanayake',
        customerPhone: '+94 71 456 7890',
        itemsSummary: '4 items (Coconut Milk, Spices, Noodles)',
        totalAmount: 2150.0,
        pickupSlot: '2 days ago, 4:00 PM - 4:30 PM',
        shopName: 'Daily Superette',
        status: 'Completed',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
        paymentMethod: 'Paid Online (Card)',
      ),
      StoreOrder(
        id: '#FK-2028-0051',
        customerName: 'Dilan Jayasuriya',
        customerPhone: '+94 78 333 4455',
        itemsSummary: '5 items (Strawberries, Mangoes, Bananas)',
        totalAmount: 3100.0,
        pickupSlot: 'Yesterday, 1:30 PM - 2:00 PM',
        shopName: 'Fresh Express Kandy',
        status: 'Completed',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
        paymentMethod: 'Paid Online (Card)',
      ),
      StoreOrder(
        id: '#FK-2028-0050',
        customerName: 'Manel Abeywickrama',
        customerPhone: '+94 70 888 5544',
        itemsSummary: '3 items (Passion Fruit, Avocados, Mint)',
        totalAmount: 1450.0,
        pickupSlot: 'Today, 5:30 PM - 6:00 PM',
        shopName: 'Fresh Express Kandy',
        status: 'Pending',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        isRead: false,
        paymentMethod: 'Pay at Store',
      ),
      StoreOrder(
        id: '#SO-2028-0022',
        customerName: 'Anura Wickramasinghe',
        customerPhone: '+94 77 666 7788',
        itemsSummary: '4 items (Organic Honey, Green Tea, Chia Seeds)',
        totalAmount: 3900.0,
        pickupSlot: '4 days ago, 10:00 AM - 10:30 AM',
        shopName: 'Sunrise Organics',
        status: 'Completed',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        isRead: true,
        paymentMethod: 'Paid Online (Card)',
      ),
      StoreOrder(
        id: '#SO-2028-0021',
        customerName: 'Kavindi Perera',
        customerPhone: '+94 76 111 2233',
        itemsSummary: '2 items (Brown Rice 5kg, Coconut Sugar)',
        totalAmount: 1750.0,
        pickupSlot: '5 days ago, 3:00 PM - 3:30 PM',
        shopName: 'Sunrise Organics',
        status: 'Completed',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isRead: true,
        paymentMethod: 'Pay at Store',
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

    _customerNotifications.addAll([
      CustomerNotification(
        id: 'cust_notif_1',
        title: 'Order Placed: #FP-2028-0142',
        message: 'Your order at Green mart was placed successfully. Pickup: Today, 4.00 PM. Total: Rs. 870.',
        timeAgo: '2h ago',
        time: DateTime.now().subtract(const Duration(hours: 2)),
        orderId: '#FP-2028-0142',
        isRead: false,
      ),
      CustomerNotification(
        id: 'cust_notif_2',
        title: 'Order Placed: #FP-2028-0142',
        message: 'Your order at Green mart was placed successfully. Pickup: Today, 4.00 PM. Total: Rs. 870.',
        timeAgo: '2h ago',
        time: DateTime.now().subtract(const Duration(hours: 2)),
        orderId: '#FP-2028-0142',
        isRead: false,
      ),
      CustomerNotification(
        id: 'cust_notif_3',
        title: 'Order Placed: #FP-2028-0142',
        message: 'Your order at Green mart was placed successfully. Pickup: Today, 11.00 AM. Total: Rs. 3050.',
        timeAgo: '2h ago',
        time: DateTime.now().subtract(const Duration(hours: 2)),
        orderId: '#FP-2028-0142',
        isRead: false,
      ),
    ]);

    _items = _buildDemoCatalog();
    // The cart starts empty: it only holds what the customer adds.
  }

  /// A fresh copy of the demo products (the catalog the app starts with). It is
  /// used to fill an empty Firestore catalog, so it never depends on `_items`,
  /// which Firestore replaces.
  List<GroceryItem> get demoCatalog => _buildDemoCatalog();

  List<GroceryItem> _buildDemoCatalog() {
    return [
      // =================== VEGETABLES ===================
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
        sellerId: 'owner_01',
        sellerShopName: 'GreenLeaf Fresh Mart',
        sellerName: 'Sunil Weerasinghe',
        sellerPhone: '+94 71 987 6543',
        sellerAddress: 'No. 42, High Level Road, Maharagama',
        sellerRating: 4.9,
        sellerResponseTime: 'Usually responds in 5m',
        stockQuantity: 45,
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
        sellerId: 'owner_01',
        sellerShopName: 'GreenLeaf Fresh Mart',
        sellerName: 'Sunil Weerasinghe',
        sellerPhone: '+94 71 987 6543',
        sellerAddress: 'No. 42, High Level Road, Maharagama',
        sellerRating: 4.9,
        sellerResponseTime: 'Usually responds in 5m',
        stockQuantity: 60,
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
        sellerId: 'shop_dailysuperette',
        sellerShopName: 'Daily Superette',
        sellerName: 'Kamal Perera',
        sellerPhone: '+94 77 234 5678',
        sellerAddress: 'No. 18, Station Road, Maharagama',
        sellerRating: 4.8,
        sellerResponseTime: 'Usually responds in 10m',
        stockQuantity: 80,
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
        sellerId: 'owner_01',
        sellerShopName: 'GreenLeaf Fresh Mart',
        sellerName: 'Sunil Weerasinghe',
        sellerPhone: '+94 71 987 6543',
        sellerAddress: 'No. 42, High Level Road, Maharagama',
        sellerRating: 4.9,
        sellerResponseTime: 'Usually responds in 5m',
        stockQuantity: 35,
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
        sellerId: 'owner_kandy',
        sellerShopName: 'Fresh Express Kandy',
        sellerName: 'Mahesh Jayawardena',
        sellerPhone: '+94 81 234 5678',
        sellerAddress: 'No. 12, Dalada Veediya, Kandy',
        sellerRating: 4.7,
        sellerResponseTime: 'Usually responds in 15m',
        stockQuantity: 50,
      ),
      const GroceryItem(
        id: 'kandy_leeks',
        name: 'Crisp Highland Leeks',
        unit: '500 g',
        price: 310.00,
        originalPrice: 350.00,
        discountPercent: 11,
        circleColor: Color(0xFFE8F6EB),
        imageUrl: 'assets/images/beans.png',
        category: 'Vegetables',
        rating: 4.6,
        reviewsCount: 38,
        description: 'Tender highland green leeks with long, sweet white stalks. Freshly harvested from Nuwara Eliya and Kandy slopes.',
        sellerId: 'owner_kandy',
        sellerShopName: 'Fresh Express Kandy',
        sellerName: 'Mahesh Jayawardena',
        sellerPhone: '+94 81 234 5678',
        sellerAddress: 'No. 12, Dalada Veediya, Kandy',
        sellerRating: 4.7,
        sellerResponseTime: 'Usually responds in 15m',
        stockQuantity: 40,
      ),
      const GroceryItem(
        id: 'organic_capsicum',
        name: 'Organic Green Capsicum',
        unit: '250 g',
        price: 290.00,
        originalPrice: 330.00,
        discountPercent: 12,
        circleColor: Color(0xFFE8F6EB),
        imageUrl: 'assets/images/pumpkin.png',
        category: 'Vegetables',
        rating: 4.8,
        reviewsCount: 44,
        description: 'Pesticide-free bell capsicum peppers, crunchy and thick-fleshed. Great for stir fries, salads, and curries.',
        sellerId: 'owner_sunrise',
        sellerShopName: 'Sunrise Organics',
        sellerName: 'Anura Wickramasinghe',
        sellerPhone: '+94 11 456 7890',
        sellerAddress: 'No. 88, Galle Road, Colombo 03',
        sellerRating: 4.9,
        sellerResponseTime: 'Usually responds in 5m',
        stockQuantity: 30,
      ),

      // =================== FRUITS ===================
      const GroceryItem(
        id: 'cavendish_banana',
        name: 'Cavendish Sweet Bananas',
        unit: '1 kg',
        price: 360.00,
        originalPrice: 420.00,
        discountPercent: 14,
        isFavorite: true,
        circleColor: Color(0xFFFFF9C4),
        imageUrl: 'assets/images/banana.jpg',
        category: 'Fruits',
        rating: 4.9,
        reviewsCount: 142,
        description: 'Naturally ripened, sweet, golden Cavendish bananas. Rich in potassium, energy, and dietary fiber. Sourced directly from local fruit orchards.',
        sellerId: 'owner_01',
        sellerShopName: 'GreenLeaf Fresh Mart',
        sellerName: 'Sunil Weerasinghe',
        sellerPhone: '+94 71 987 6543',
        sellerAddress: 'No. 42, High Level Road, Maharagama',
        sellerRating: 4.9,
        sellerResponseTime: 'Usually responds in 5m',
        stockQuantity: 70,
      ),
      const GroceryItem(
        id: 'karthakolomban_mango',
        name: 'Karthakolomban Mangoes',
        unit: '1 kg',
        price: 750.00,
        originalPrice: 850.00,
        discountPercent: 12,
        isNew: true,
        circleColor: Color(0xFFFFF3E0),
        imageUrl: 'assets/images/mango.jpg',
        category: 'Fruits',
        rating: 4.9,
        reviewsCount: 168,
        description: 'King of Sri Lankan mangoes! Luscious, intensely sweet, aromatic golden Karthakolomban mangoes with rich juicy pulp and minimal fiber.',
        sellerId: 'shop_dailysuperette',
        sellerShopName: 'Daily Superette',
        sellerName: 'Kamal Perera',
        sellerPhone: '+94 77 234 5678',
        sellerAddress: 'No. 18, Station Road, Maharagama',
        sellerRating: 4.8,
        sellerResponseTime: 'Usually responds in 10m',
        stockQuantity: 55,
      ),
      const GroceryItem(
        id: 'gala_apples',
        name: 'Royal Gala Red Apples',
        unit: '1 kg (approx 6 pcs)',
        price: 980.00,
        originalPrice: 1100.00,
        discountPercent: 11,
        circleColor: Color(0xFFFDECEB),
        imageUrl: 'assets/images/apple.jpg',
        category: 'Fruits',
        rating: 4.8,
        reviewsCount: 92,
        description: 'Crisp, juicy Royal Gala apples with sweet floral notes and thin bright red skins. Hand-sorted for premium size and superior crunch.',
        sellerId: 'owner_sunrise',
        sellerShopName: 'Sunrise Organics',
        sellerName: 'Anura Wickramasinghe',
        sellerPhone: '+94 11 456 7890',
        sellerAddress: 'No. 88, Galle Road, Colombo 03',
        sellerRating: 4.9,
        sellerResponseTime: 'Usually responds in 5m',
        stockQuantity: 40,
      ),
      const GroceryItem(
        id: 'red_papaya',
        name: 'Red Lady Sweet Papaya',
        unit: '1 pc (approx 1.2 kg)',
        price: 320.00,
        originalPrice: 380.00,
        discountPercent: 15,
        circleColor: Color(0xFFFFF0E6),
        imageUrl: 'assets/images/pumpkin.png',
        category: 'Fruits',
        rating: 4.7,
        reviewsCount: 51,
        description: 'Deep red flesh, soft and melt-in-the-mouth sweet. Loaded with Vitamin C, digestive enzymes (papain), and beta-carotene.',
        sellerId: 'owner_kandy',
        sellerShopName: 'Fresh Express Kandy',
        sellerName: 'Mahesh Jayawardena',
        sellerPhone: '+94 81 234 5678',
        sellerAddress: 'No. 12, Dalada Veediya, Kandy',
        sellerRating: 4.7,
        sellerResponseTime: 'Usually responds in 15m',
        stockQuantity: 25,
      ),

      // =================== BEVERAGES ===================
      const GroceryItem(
        id: 'fresh_milk',
        name: 'Fresh Dairy Whole Milk',
        unit: '1 L Glass Bottle',
        price: 450.00,
        originalPrice: 500.00,
        discountPercent: 10,
        isNew: true,
        isFavorite: true,
        circleColor: Color(0xFFE3F2FD),
        imageUrl: 'assets/images/milk.jpg',
        category: 'Beverages',
        rating: 4.9,
        reviewsCount: 120,
        description: 'Pure, fresh pasteurized whole dairy milk rich in calcium, protein, and essential nutrients. Daily morning delivery from local highland dairy farms in sterilized eco-bottles.',
        sellerId: 'shop_dailysuperette',
        sellerShopName: 'Daily Superette',
        sellerName: 'Kamal Perera',
        sellerPhone: '+94 77 234 5678',
        sellerAddress: 'No. 18, Station Road, Maharagama',
        sellerRating: 4.8,
        sellerResponseTime: 'Usually responds in 10m',
        stockQuantity: 60,
      ),
      const GroceryItem(
        id: 'ceylon_tea',
        name: 'Royal Ceylon BOPF Black Tea',
        unit: '400 g Pack',
        price: 680.00,
        originalPrice: 750.00,
        discountPercent: 9,
        isFavorite: true,
        circleColor: Color(0xFFEFEBE9),
        imageUrl: 'assets/images/tea.jpg',
        category: 'Beverages',
        rating: 5.0,
        reviewsCount: 215,
        description: 'Finest single-origin Ceylon BOPF black tea leaves from misty hill country estates in Nuwara Eliya. Rich malty body, amber gold liquor, and invigorating aroma.',
        sellerId: 'owner_kandy',
        sellerShopName: 'Fresh Express Kandy',
        sellerName: 'Mahesh Jayawardena',
        sellerPhone: '+94 81 234 5678',
        sellerAddress: 'No. 12, Dalada Veediya, Kandy',
        sellerRating: 4.7,
        sellerResponseTime: 'Usually responds in 15m',
        stockQuantity: 100,
      ),
      const GroceryItem(
        id: 'organic_green_tea',
        name: 'Organic Ceylon Green Tea',
        unit: '200 g Canister',
        price: 790.00,
        originalPrice: 890.00,
        discountPercent: 11,
        circleColor: Color(0xFFE8F5E9),
        imageUrl: 'assets/images/tea.jpg',
        category: 'Beverages',
        rating: 4.8,
        reviewsCount: 48,
        description: 'Pure organic steamed Ceylon green tea packed with natural polyphenols, antioxidants, and soothing delicate aroma.',
        sellerId: 'owner_sunrise',
        sellerShopName: 'Sunrise Organics',
        sellerName: 'Anura Wickramasinghe',
        sellerPhone: '+94 11 456 7890',
        sellerAddress: 'No. 88, Galle Road, Colombo 03',
        sellerRating: 4.9,
        sellerResponseTime: 'Usually responds in 5m',
        stockQuantity: 40,
      ),

      // =================== GROCERY ===================
      const GroceryItem(
        id: 'keeri_samba',
        name: 'Ceylon Keeri Samba White Rice',
        unit: '5 kg Pack',
        price: 1350.00,
        originalPrice: 1500.00,
        discountPercent: 10,
        isFavorite: true,
        circleColor: Color(0xFFFFF8E1),
        imageUrl: 'assets/images/rice.jpg',
        category: 'Grocery',
        rating: 4.9,
        reviewsCount: 185,
        description: 'SLS certified premium polished Ceylon Keeri Samba rice. Fine aromatic short grains that cook up fluffy, separate, and delightfully fragrant. Perfect for Sri Lankan rice & curry feasts.',
        sellerId: 'owner_01',
        sellerShopName: 'GreenLeaf Fresh Mart',
        sellerName: 'Sunil Weerasinghe',
        sellerPhone: '+94 71 987 6543',
        sellerAddress: 'No. 42, High Level Road, Maharagama',
        sellerRating: 4.9,
        sellerResponseTime: 'Usually responds in 5m',
        stockQuantity: 65,
      ),
      const GroceryItem(
        id: 'mysore_dhal',
        name: 'Mysore Red Dhal (Lentils)',
        unit: '1 kg',
        price: 390.00,
        originalPrice: 430.00,
        discountPercent: 9,
        circleColor: Color(0xFFFFF0E6),
        imageUrl: 'assets/images/red_onion.png',
        category: 'Grocery',
        rating: 4.7,
        reviewsCount: 78,
        description: 'Triple-cleaned, premium imported Mysore red lentils. Cook fast with a silky texture, packed with dietary iron and plant proteins for everyday dhal curry.',
        sellerId: 'shop_dailysuperette',
        sellerShopName: 'Daily Superette',
        sellerName: 'Kamal Perera',
        sellerPhone: '+94 77 234 5678',
        sellerAddress: 'No. 18, Station Road, Maharagama',
        sellerRating: 4.8,
        sellerResponseTime: 'Usually responds in 10m',
        stockQuantity: 90,
      ),
      const GroceryItem(
        id: 'farm_eggs',
        name: 'Farm Fresh Brown Eggs',
        unit: '10 Pack Tray',
        price: 560.00,
        originalPrice: 620.00,
        discountPercent: 10,
        circleColor: Color(0xFFFFF3E0),
        imageUrl: 'assets/images/carrot.png',
        category: 'Grocery',
        rating: 4.8,
        reviewsCount: 94,
        description: 'Grade-A farm fresh brown eggs with rich golden yolks, high in protein and choline. Sourced daily from certified bio-secure poultry farms.',
        sellerId: 'shop_dailysuperette',
        sellerShopName: 'Daily Superette',
        sellerName: 'Kamal Perera',
        sellerPhone: '+94 77 234 5678',
        sellerAddress: 'No. 18, Station Road, Maharagama',
        sellerRating: 4.8,
        sellerResponseTime: 'Usually responds in 10m',
        stockQuantity: 50,
      ),
      const GroceryItem(
        id: 'rathu_kekulu',
        name: 'Organic Red Raw Rice (Rathu Kekulu)',
        unit: '5 kg Pack',
        price: 1420.00,
        originalPrice: 1580.00,
        discountPercent: 10,
        isNew: true,
        circleColor: Color(0xFFFBE9E7),
        imageUrl: 'assets/images/rice.jpg',
        category: 'Grocery',
        rating: 4.9,
        reviewsCount: 62,
        description: 'Unpolished traditional organic Sri Lankan red raw rice rich in anthocyanins, low glycemic index, and wholesome natural nutrients.',
        sellerId: 'owner_sunrise',
        sellerShopName: 'Sunrise Organics',
        sellerName: 'Anura Wickramasinghe',
        sellerPhone: '+94 11 456 7890',
        sellerAddress: 'No. 88, Galle Road, Colombo 03',
        sellerRating: 4.9,
        sellerResponseTime: 'Usually responds in 5m',
        stockQuantity: 40,
      ),

      // =================== EDIBLE OIL ===================
      const GroceryItem(
        id: 'pure_coconut_oil',
        name: 'Pure Coconut Cooking Oil',
        unit: '1 L Bottle',
        price: 890.00,
        originalPrice: 990.00,
        discountPercent: 10,
        isFavorite: true,
        circleColor: Color(0xFFE0F7FA),
        imageUrl: 'assets/images/cooking_oil.jpg',
        category: 'Edible oil',
        rating: 4.9,
        reviewsCount: 116,
        description: 'Traditional Sri Lankan expeller-pressed pure coconut oil. High smoke point, rich coconut aroma, free from chemical preservatives and cholesterol.',
        sellerId: 'owner_01',
        sellerShopName: 'GreenLeaf Fresh Mart',
        sellerName: 'Sunil Weerasinghe',
        sellerPhone: '+94 71 987 6543',
        sellerAddress: 'No. 42, High Level Road, Maharagama',
        sellerRating: 4.9,
        sellerResponseTime: 'Usually responds in 5m',
        stockQuantity: 55,
      ),
      const GroceryItem(
        id: 'sunflower_oil',
        name: 'Refined Sunflower Cooking Oil',
        unit: '1 L Bottle',
        price: 820.00,
        originalPrice: 920.00,
        discountPercent: 11,
        circleColor: Color(0xFFFFFDE7),
        imageUrl: 'assets/images/cooking_oil.jpg',
        category: 'Edible oil',
        rating: 4.7,
        reviewsCount: 54,
        description: 'Light, clear, high-smoke-point sunflower cooking oil enriched with Vitamin E. Great for shallow frying and baking.',
        sellerId: 'shop_dailysuperette',
        sellerShopName: 'Daily Superette',
        sellerName: 'Kamal Perera',
        sellerPhone: '+94 77 234 5678',
        sellerAddress: 'No. 18, Station Road, Maharagama',
        sellerRating: 4.8,
        sellerResponseTime: 'Usually responds in 10m',
        stockQuantity: 45,
      ),
      const GroceryItem(
        id: 'virgin_coconut_oil',
        name: 'Extra Virgin Cold Pressed Coconut Oil',
        unit: '500 ml Glass Jar',
        price: 1150.00,
        originalPrice: 1300.00,
        discountPercent: 12,
        isNew: true,
        circleColor: Color(0xFFE0F2F1),
        imageUrl: 'assets/images/cooking_oil.jpg',
        category: 'Edible oil',
        rating: 4.9,
        reviewsCount: 77,
        description: 'Certified organic cold-pressed extra virgin coconut oil. Raw, unrefined, retaining natural medium-chain triglycerides (MCTs).',
        sellerId: 'owner_sunrise',
        sellerShopName: 'Sunrise Organics',
        sellerName: 'Anura Wickramasinghe',
        sellerPhone: '+94 11 456 7890',
        sellerAddress: 'No. 88, Galle Road, Colombo 03',
        sellerRating: 4.9,
        sellerResponseTime: 'Usually responds in 5m',
        stockQuantity: 35,
      ),

      // =================== HOUSEHOLD ===================
      const GroceryItem(
        id: 'citrus_dishwash',
        name: 'Citrus Dishwashing Liquid',
        unit: '750 ml Bottle',
        price: 490.00,
        originalPrice: 550.00,
        discountPercent: 11,
        isFavorite: true,
        circleColor: Color(0xFFE8F5E9),
        imageUrl: 'assets/images/dishwash.jpg',
        category: 'Household',
        rating: 4.8,
        reviewsCount: 134,
        description: 'Plant-based biodegradable grease-cutting formula powered by natural lime and lemon essential oils. Tough on oily curry pots, gentle on sensitive hands.',
        sellerId: 'shop_dailysuperette',
        sellerShopName: 'Daily Superette',
        sellerName: 'Kamal Perera',
        sellerPhone: '+94 77 234 5678',
        sellerAddress: 'No. 18, Station Road, Maharagama',
        sellerRating: 4.8,
        sellerResponseTime: 'Usually responds in 10m',
        stockQuantity: 85,
      ),
      const GroceryItem(
        id: 'eco_cleaner',
        name: 'Natural Multi-Surface Surface Cleaner',
        unit: '1 L Spray Bottle',
        price: 680.00,
        originalPrice: 760.00,
        discountPercent: 11,
        isNew: true,
        circleColor: Color(0xFFE3F2FD),
        imageUrl: 'assets/images/dishwash.jpg',
        category: 'Household',
        rating: 4.7,
        reviewsCount: 42,
        description: 'Eco-certified surface sanitizing cleaner with antibacterial tea tree and eucalyptus extract. Safe around children and pets.',
        sellerId: 'owner_sunrise',
        sellerShopName: 'Sunrise Organics',
        sellerName: 'Anura Wickramasinghe',
        sellerPhone: '+94 11 456 7890',
        sellerAddress: 'No. 88, Galle Road, Colombo 03',
        sellerRating: 4.9,
        sellerResponseTime: 'Usually responds in 5m',
        stockQuantity: 40,
      ),
      const GroceryItem(
        id: 'pine_floor_cleaner',
        name: 'Lemon & Pine Disinfectant Floor Cleaner',
        unit: '1 L Bottle',
        price: 520.00,
        originalPrice: 590.00,
        discountPercent: 12,
        circleColor: Color(0xFFFFFDE7),
        imageUrl: 'assets/images/dishwash.jpg',
        category: 'Household',
        rating: 4.6,
        reviewsCount: 39,
        description: 'Deep cleaning floor cleaner that cuts grease, kills 99.9% germs, and leaves a refreshing citrus pine fragrance throughout your home.',
        sellerId: 'owner_kandy',
        sellerShopName: 'Fresh Express Kandy',
        sellerName: 'Mahesh Jayawardena',
        sellerPhone: '+94 81 234 5678',
        sellerAddress: 'No. 12, Dalada Veediya, Kandy',
        sellerRating: 4.7,
        sellerResponseTime: 'Usually responds in 15m',
        stockQuantity: 50,
      ),
    ];
  }

  // Cart operations
  int getQuantity(String itemId) => _cartQuantities[itemId] ?? 0;

  /// Number of items in the cart. A product that is no longer in the catalog
  /// (for example the shop deleted it) is not counted.
  int get totalCartItemCount {
    var total = 0;
    _cartQuantities.forEach((id, qty) {
      if (qty > 0 && getItemById(id) != null) total += qty;
    });
    return total;
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
    return _items.where((element) => element.isFavorite && element.isAvailable).toList();
  }

  /// The product with this id, or null when there is none. (It used to return
  /// the first product instead, which showed the wrong item and price.)
  GroceryItem? getItemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<GroceryItem> getCategoryItems(String category) {
    final cat = category.toLowerCase().trim();
    if (cat.isEmpty || cat == 'all') {
      return _items.where((it) => it.isAvailable).toList();
    }
    final filtered = _items.where((item) => item.isAvailable && item.category.toLowerCase() == cat).toList();
    return filtered;
  }

  /// Returns all products belonging to a specific shop.
  /// When [activeOnly] is true, only products with isAvailable = true are returned.
  List<GroceryItem> getItemsByShop(String shopName, {bool activeOnly = false}) {
    final target = shopName.trim().toLowerCase();
    if (target.isEmpty) {
      return activeOnly ? _items.where((it) => it.isAvailable).toList() : _items;
    }
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

    if (activeOnly) {
      return matched.where((item) => item.isAvailable).toList();
    }
    return matched;
  }

  /// Returns all products belonging to a specific shop by shopId, shopName, or owner details.
  /// If the shop is a newly registered or demo store with no items yet, supplies realistic initial catalog items.
  List<GroceryItem> getItemsForShop({
    required String shopId,
    required String shopName,
    String? ownerName,
    String? ownerEmail,
  }) {
    final targetId = shopId.trim().toLowerCase();
    final targetName = shopName.trim().toLowerCase();
    final targetOwner = (ownerName ?? '').trim().toLowerCase();

    // 1. Direct match on sellerId, sellerShopName, displaySellerShopName, or sellerName
    final matched = _items.where((item) {
      final sId = (item.sellerId ?? '').trim().toLowerCase();
      if (targetId.isNotEmpty && sId == targetId) return true;

      final itemShop = item.displaySellerShopName.trim().toLowerCase();
      final itemSellerShop = (item.sellerShopName ?? '').trim().toLowerCase();
      final itemSeller = (item.sellerName ?? '').trim().toLowerCase();

      if (targetName.isNotEmpty) {
        if (itemShop == targetName || itemSellerShop == targetName) return true;
        if (itemShop.contains(targetName) || targetName.contains(itemShop)) return true;
      }
      if (targetOwner.isNotEmpty && itemSeller == targetOwner) return true;

      final isGreenLeaf = targetName.contains('greenleaf') ||
          targetName.contains('green leaf') ||
          targetName.contains('green mart');
      if (isGreenLeaf &&
          (itemSellerShop.isEmpty ||
              itemSellerShop == 'greenleaf fresh mart' ||
              itemSellerShop == 'green mart')) {
        return true;
      }
      return false;
    }).toList();

    if (matched.isNotEmpty) return matched;

    // 2. Try getItemsByShop
    final byName = getItemsByShop(shopName);
    if (byName.isNotEmpty) return byName;

    // 3. Fallback to realistic demo store catalog so admin always sees items for any shop
    return _generateFallbackItemsForShop(
      shopId: shopId,
      shopName: shopName,
      ownerName: ownerName,
    );
  }

  List<GroceryItem> _generateFallbackItemsForShop({
    required String shopId,
    required String shopName,
    String? ownerName,
  }) {
    final sName = shopName.isNotEmpty ? shopName : 'Partner Grocery';
    final oName = (ownerName != null && ownerName.isNotEmpty) ? ownerName : 'Store Operator';

    return [
      GroceryItem(
        id: '${shopId}_item_1',
        name: 'Keeri Samba Rice 5kg',
        unit: '5 kg Pack',
        price: 1450.00,
        originalPrice: 1600.00,
        discountPercent: 9,
        category: 'Grocery',
        imageUrl: 'assets/images/pumpkin.png',
        description: 'Super-clean premium Keeri Samba grain from local highland mills with guaranteed quality.',
        sellerId: shopId,
        sellerShopName: sName,
        sellerName: oName,
        stockQuantity: 35,
        rating: 4.8,
        reviewsCount: 38,
      ),
      GroceryItem(
        id: '${shopId}_item_2',
        name: 'Fresh Dairy Milk 1L',
        unit: '1 L',
        price: 450.00,
        category: 'Beverages',
        imageUrl: 'assets/images/pumpkin.png',
        description: 'Pure, fresh pasteurized whole dairy milk delivered daily from local farms.',
        sellerId: shopId,
        sellerShopName: sName,
        sellerName: oName,
        stockQuantity: 24,
        rating: 4.9,
        reviewsCount: 45,
      ),
      GroceryItem(
        id: '${shopId}_item_3',
        name: 'Farm Fresh Brown Eggs (10 pk)',
        unit: '10 Pack',
        price: 560.00,
        originalPrice: 620.00,
        discountPercent: 10,
        category: 'Grocery',
        imageUrl: 'assets/images/carrot.png',
        description: 'Grade-A farm eggs with rich golden yolks, sourced daily from certified farms.',
        sellerId: shopId,
        sellerShopName: sName,
        sellerName: oName,
        stockQuantity: 30,
        rating: 4.7,
        reviewsCount: 29,
      ),
      GroceryItem(
        id: '${shopId}_item_4',
        name: 'Ceylon Premium BOPF Tea 200g',
        unit: '200 g',
        price: 470.00,
        category: 'Beverages',
        imageUrl: 'assets/images/beans.png',
        description: 'Handpicked Ceylon black tea leaves with authentic mountain aroma.',
        sellerId: shopId,
        sellerShopName: sName,
        sellerName: oName,
        stockQuantity: 18,
        rating: 4.9,
        reviewsCount: 52,
      ),
      GroceryItem(
        id: '${shopId}_item_5',
        name: 'Cleaned Mysore Red Dhal 1kg',
        unit: '1 kg',
        price: 390.00,
        category: 'Grocery',
        imageUrl: 'assets/images/red_onion.png',
        description: 'Premium red lentils, quick cooking and high in natural protein.',
        sellerId: shopId,
        sellerShopName: sName,
        sellerName: oName,
        stockQuantity: 40,
        rating: 4.8,
        reviewsCount: 31,
      ),
      GroceryItem(
        id: '${shopId}_item_6',
        name: 'Highland Farm Carrots 500g',
        unit: '500 g',
        price: 340.00,
        originalPrice: 380.00,
        discountPercent: 10,
        category: 'Vegetables',
        imageUrl: 'assets/images/carrot.png',
        description: 'Crisp highland carrots, sweet and rich in vitamins.',
        sellerId: shopId,
        sellerShopName: sName,
        sellerName: oName,
        stockQuantity: 15,
        rating: 4.8,
        reviewsCount: 22,
      ),
    ];
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
      if (!item.isAvailable) return false;
      return item.name.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();
  }

  // Seller Product Management (Adds directly to live catalog for Customers)
  void addProduct(GroceryItem item) {
    final withTime = item.createdAt == null ? item.copyWith(createdAt: DateTime.now()) : item;
    final index = _items.indexWhere((it) => it.id == withTime.id);
    if (index == -1) {
      _items.insert(0, withTime);
    } else {
      _items[index] = withTime;
    }
    notifyListeners();

    final firestore = _firestore;
    if (firestore != null) {
      firestore.collection('products').doc(withTime.id).set(withTime.toMap(), SetOptions(merge: true)).catchError((e) {
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

  /// Toggle product availability (Active <-> Inactive / Online Catalog Visibility)
  void toggleProductAvailability(String id) {
    final index = _items.indexWhere((it) => it.id == id);
    if (index != -1) {
      final current = _items[index];
      final updated = current.copyWith(isAvailable: !current.isAvailable);
      _items[index] = updated;
      notifyListeners();

      final firestore = _firestore;
      if (firestore != null) {
        firestore
            .collection('products')
            .doc(id)
            .set(updated.toMap(), SetOptions(merge: true))
            .catchError((e) {
          debugPrint('Firestore toggle availability error: $e');
        });
      }
    }
  }

  /// Explicitly set product active/inactive state
  void setProductAvailability(String id, bool isAvailable) {
    final index = _items.indexWhere((it) => it.id == id);
    if (index != -1) {
      final current = _items[index];
      final updated = current.copyWith(isAvailable: isAvailable);
      _items[index] = updated;
      notifyListeners();

      final firestore = _firestore;
      if (firestore != null) {
        firestore
            .collection('products')
            .doc(id)
            .set(updated.toMap(), SetOptions(merge: true))
            .catchError((e) {
          debugPrint('Firestore set availability error: $e');
        });
      }
    }
  }

  /// Update stock quantity directly (0 marks as out-of-stock / inactive)
  void setProductStock(String id, int stockQuantity) {
    final index = _items.indexWhere((it) => it.id == id);
    if (index != -1) {
      final current = _items[index];
      final qty = stockQuantity < 0 ? 0 : stockQuantity;
      final updated = current.copyWith(
        stockQuantity: qty,
        isAvailable: qty > 0,
      );
      _items[index] = updated;
      notifyListeners();

      final firestore = _firestore;
      if (firestore != null) {
        firestore
            .collection('products')
            .doc(id)
            .set(updated.toMap(), SetOptions(merge: true))
            .catchError((e) {
          debugPrint('Firestore set stock error: $e');
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
      'cancelReason': order.cancelReason,
      'cancelledByCustomer': order.cancelledByCustomer,
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

    // Push notification for customer
    final customerNotif = CustomerNotification(
      id: 'cust_notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Order Placed: $generatedId',
      message: 'Your order at $shopName was placed successfully. Pickup: $pickupSlot. Total: Rs. ${totalAmount.toStringAsFixed(0)}.',
      timeAgo: 'Just now',
      time: DateTime.now(),
      orderId: generatedId,
      isRead: false,
    );
    _customerNotifications.insert(0, customerNotif);

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

  /// The customer can confirm they collected the order once the shop says it is
  /// ready for pickup.
  bool canCustomerConfirmPickup(StoreOrder? order) {
    return order != null && order.status == 'Ready for Pickup';
  }

  /// The customer says they collected the order: it becomes Completed, the
  /// shop is told and the customer gets a thank-you. Returns false when the
  /// order is not ready for pickup.
  bool confirmPickupByCustomer(String orderId) {
    final order = orderById(orderId);
    if (!canCustomerConfirmPickup(order)) return false;

    updateOrderStatus(orderId, 'Completed');

    _sellerNotifications.insert(
      0,
      SellerNotification(
        id: 'notif_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Order Collected: $orderId',
        message: '${order!.customerName} confirmed they collected this order (${order.formattedTotal}).',
        time: DateTime.now(),
        orderId: orderId,
        isRead: false,
      ),
    );
    _customerNotifications.insert(
      0,
      CustomerNotification(
        id: 'cust_notif_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Order Collected: $orderId',
        message: 'Thank you for shopping at ${order.shopName}! We hope you enjoy your groceries.',
        timeAgo: 'Just now',
        time: DateTime.now(),
        orderId: orderId,
        isRead: false,
      ),
    );
    notifyListeners();
    return true;
  }

  /// A customer can still cancel while the shop has not finished packing the
  /// order, which means it is Pending or Preparing.
  bool canCustomerCancel(StoreOrder? order) {
    return order != null && (order.status == 'Pending' || order.status == 'Preparing');
  }

  /// Cancels an order for the customer. The shop is told and the customer gets
  /// a confirmation. Returns false when the order can no longer be cancelled
  /// (already ready for pickup, completed or cancelled).
  bool cancelOrderByCustomer(String orderId, {String? reason}) {
    final index = _sellerOrders.indexWhere((o) => o.id == orderId);
    if (index == -1 || !canCustomerCancel(_sellerOrders[index])) return false;

    final order = _sellerOrders[index];
    final cleanReason = (reason == null || reason.trim().isEmpty) ? null : reason.trim();
    _sellerOrders[index] = order.copyWith(
      status: 'Cancelled',
      cancelReason: cleanReason,
      cancelledByCustomer: true,
    );

    final firestore = _firestore;
    if (firestore != null) {
      firestore
          .collection('orders')
          .doc(orderId)
          .set(_orderToMap(_sellerOrders[index]), SetOptions(merge: true))
          .catchError((e) {
        debugPrint('Firestore cancel order error: $e');
      });
    }

    _sellerNotifications.insert(
      0,
      SellerNotification(
        id: 'notif_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Order Cancelled: $orderId',
        message: '${order.customerName} cancelled this order (${order.formattedTotal}).'
            '${cleanReason == null ? '' : ' Reason: $cleanReason.'}',
        time: DateTime.now(),
        orderId: orderId,
        isRead: false,
      ),
    );
    _customerNotifications.insert(
      0,
      CustomerNotification(
        id: 'cust_notif_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Order Cancelled: $orderId',
        message: 'You cancelled your order at ${order.shopName}. '
            '${order.paymentMethod.toLowerCase().contains('online') ? 'Your card payment will be refunded.' : 'Nothing was charged.'}',
        timeAgo: 'Just now',
        time: DateTime.now(),
        orderId: orderId,
        isRead: false,
      ),
    );
    notifyListeners();
    return true;
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
