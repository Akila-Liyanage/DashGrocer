import '../models/owner_profile.dart';
import '../models/product.dart';
import '../models/shop_order.dart';
import '../models/shop_profile.dart';

// Sample data matching the Figma screens. Times are relative to "now" so the
// countdown labels and the sales chart always look realistic.

/// Kamal Perera is the shop owner persona from Milestone 01.
OwnerProfile demoOwner(String userId) {
  return OwnerProfile(
    id: userId,
    fullName: 'Kamal Perera',
    email: 'kamalperera@gmail.com',
    phoneNumber: '071 234 5678',
  );
}

ShopProfile demoShop(String shopId) {
  return ShopProfile(
    id: shopId,
    name: 'Green Mart',
    address: '42 Temple Road, Nugegoda',
    addressNote: 'Front dispatch counter · Curbside rack',
    phone: '+94 11 281 9400',
    mobile: '077 458 1290',
  );
}

const OrderItem _sambaRice2kg =
    OrderItem(name: 'Samba Rice', quantity: 2, unit: 'kg', unitPrice: 245);
const OrderItem _sambaRice1kg =
    OrderItem(name: 'Samba Rice', quantity: 1, unit: 'kg', unitPrice: 245);
const OrderItem _milk =
    OrderItem(name: 'Fresh Milk', quantity: 1, unit: 'L', unitPrice: 450);
const OrderItem _bread = OrderItem(
  name: 'Sandwich Bread',
  quantity: 1,
  unit: 'loaf',
  unitPrice: 180,
);
const OrderItem _eggs = OrderItem(
  name: 'Brown Eggs (10 pk)',
  quantity: 1,
  unit: 'Pack',
  unitPrice: 355,
);
const OrderItem _tea = OrderItem(
  name: 'Ceylon Black Tea 200g',
  quantity: 1,
  unit: 'Pack',
  unitPrice: 470,
);
const OrderItem _onions =
    OrderItem(name: 'Red Onions', quantity: 1, unit: 'kg', unitPrice: 320);
const OrderItem _dhal =
    OrderItem(name: 'Mysore Dhal', quantity: 1, unit: 'kg', unitPrice: 390);
const OrderItem _oil = OrderItem(
  name: 'Coconut Oil',
  quantity: 1,
  unit: 'Bottle',
  unitPrice: 780,
);
const OrderItem _sugar =
    OrderItem(name: 'White Sugar', quantity: 1, unit: 'kg', unitPrice: 275);

double _sum(List<OrderItem> items) {
  return items.fold<double>(0, (total, item) => total + item.lineTotal);
}

List<ShopOrder> demoOrders(String shopId) {
  final now = DateTime.now();
  DateTime inMinutes(int minutes) => now.add(Duration(minutes: minutes));

  ShopOrder order({
    required String number,
    required String customerId,
    required String name,
    required String phone,
    required OrderStatus status,
    required DateTime pickup,
    required DateTime created,
    required List<OrderItem> items,
    String payment = 'Pay on Counter Pickup',
    List<int> packed = const <int>[],
    DateTime? completedAt,
  }) {
    return ShopOrder(
      id: 'demo_$number',
      orderNumber: number,
      shopId: shopId,
      customerId: customerId,
      customerName: name,
      customerPhone: phone,
      status: status,
      pickupTime: pickup,
      createdAt: created,
      items: items,
      total: _sum(items),
      paymentMethod: payment,
      packedIndexes: packed,
      completedAt: completedAt,
    );
  }

  final active = <ShopOrder>[
    order(
      number: 'LM1024',
      customerId: 'demo_customer_1',
      name: 'Sanduni Perera',
      phone: '077-458-1290',
      status: OrderStatus.newOrder,
      pickup: inMinutes(35),
      created: inMinutes(-70),
      items: const [_sambaRice2kg, _milk, _bread, _eggs],
    ),
    order(
      number: 'LM1025',
      customerId: 'demo_customer_2',
      name: 'Ruwan Silva',
      phone: '071-220-4518',
      status: OrderStatus.newOrder,
      pickup: inMinutes(65),
      created: inMinutes(-40),
      items: const [_milk, _tea],
      payment: 'Paid Online',
    ),
    order(
      number: 'LM1021',
      customerId: 'demo_customer_3',
      name: 'K. Perera',
      phone: '076-901-3344',
      status: OrderStatus.preparing,
      pickup: inMinutes(10),
      created: inMinutes(-95),
      items: const [_onions, _dhal, _oil, _sugar, _tea],
      packed: const [0, 1, 2],
    ),
    order(
      number: 'LM1019',
      customerId: 'demo_customer_4',
      name: 'Nimasha Perera',
      phone: '070-345-8821',
      status: OrderStatus.ready,
      pickup: inMinutes(20),
      created: inMinutes(-120),
      items: const [_sambaRice1kg, _milk],
      packed: const [0, 1],
    ),
  ];

  // Completed orders spread over the last 7 days, for the sales summary.
  const baskets = <List<OrderItem>>[
    [_sambaRice2kg, _eggs],
    [_milk, _bread, _tea],
    [_oil, _dhal],
    [_sambaRice1kg, _sugar, _onions],
    [_eggs, _milk],
    [_tea, _bread],
    [_oil, _sambaRice2kg, _milk],
  ];
  const customers = <String>[
    'Dilani Fernando',
    'Amal Jayasuriya',
    'Tharushi Bandara',
    'Nuwan Wickramasinghe',
  ];
  const ordersPerDay = <int>[2, 3, 1, 2, 3, 2, 1];

  final completed = <ShopOrder>[];
  var counter = 0;
  for (var daysAgo = 0; daysAgo < ordersPerDay.length; daysAgo++) {
    for (var n = 0; n < ordersPerDay[daysAgo]; n++) {
      final done = now.subtract(
        Duration(days: daysAgo, hours: 1 + n, minutes: 10 * n),
      );
      final items = baskets[counter % baskets.length];
      completed.add(
        order(
          number: 'LM${1000 - counter}',
          customerId: 'demo_customer_${5 + counter % customers.length}',
          name: customers[counter % customers.length],
          phone: '077-112-90${10 + counter}',
          status: OrderStatus.completed,
          pickup: done,
          created: done.subtract(const Duration(hours: 2)),
          items: items,
          payment: counter.isEven ? 'Pay on Counter Pickup' : 'Paid Online',
          packed: [for (var i = 0; i < items.length; i++) i],
          completedAt: done,
        ),
      );
      counter++;
    }
  }

  return [...active, ...completed];
}

List<Product> demoProducts(String shopId) {
  Product product(
    String id,
    String name,
    String category,
    String unit,
    double price,
    int stock, {
    int threshold = 10,
    String code = '',
    String barcode = '',
  }) {
    return Product(
      id: 'demo_$id',
      shopId: shopId,
      name: name,
      category: category,
      unit: unit,
      price: price,
      stock: stock,
      lowStockThreshold: threshold,
      code: code,
      barcode: barcode,
    );
  }

  return [
    product(
      'keeri_samba_5kg',
      'Keeri Samba Rice 5kg',
      'Rice & Grains',
      'Pack',
      1450,
      2,
      code: '88210',
      barcode: '79214051',
    ),
    product(
      'white_bread',
      'Traditional White Bread 450g',
      'Bakery',
      'Pcs',
      160,
      0,
      threshold: 5,
      code: '88304',
    ),
    product('samba_rice', 'Samba Rice', 'Rice & Grains', 'kg', 245, 45,
        code: '88201'),
    product('fresh_milk', 'Fresh Milk', 'Dairy & Eggs', 'L', 450, 24,
        code: '88120'),
    product('sandwich_bread', 'Sandwich Bread', 'Bakery', 'Pcs', 180, 12,
        threshold: 5, code: '88301'),
    product('brown_eggs', 'Brown Eggs (10 pk)', 'Dairy & Eggs', 'Pack', 355, 30,
        code: '88125'),
    product('black_tea', 'Ceylon Black Tea 200g', 'Beverages', 'Pack', 470, 18,
        code: '88410'),
    product('red_onions', 'Red Onions', 'Produce', 'kg', 320, 26,
        code: '88502'),
    product('mysore_dhal', 'Mysore Dhal', 'Rice & Grains', 'kg', 390, 34,
        code: '88205'),
    product('coconut_oil', 'Coconut Oil', 'Household', 'Bottle', 780, 15,
        threshold: 5, code: '88611'),
    product('white_sugar', 'White Sugar', 'Rice & Grains', 'kg', 275, 40,
        code: '88208'),
  ];
}
