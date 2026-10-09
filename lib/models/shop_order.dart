import '../core/formatters.dart';
import 'firestore_dates.dart';

/// The stages an order moves through. [value] is what is saved in Firestore,
/// so the customer app must use the same words.
enum OrderStatus {
  newOrder('new', 'New'),
  preparing('preparing', 'Preparing'),
  ready('ready', 'Ready'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const OrderStatus(this.value, this.label);

  final String value;
  final String label;

  static OrderStatus fromValue(String? value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.newOrder,
    );
  }
}

class OrderItem {
  const OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.productId = '',
    this.unit = '',
  });

  final String productId;
  final String name;
  final num quantity;
  final String unit;
  final double unitPrice;

  double get lineTotal => unitPrice * quantity;

  /// "2 kg", or "x 2" when there is no unit.
  String get quantityLabel {
    final amount = formatQuantity(quantity);
    return unit.isEmpty ? 'x $amount' : '$amount $unit';
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? 'Item',
      quantity: map['quantity'] as num? ?? 1,
      unit: map['unit'] as String? ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
    };
  }
}

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.orderNumber,
    required this.shopId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.total,
    required this.status,
    required this.pickupTime,
    required this.createdAt,
    this.paymentMethod = 'Pay on Counter Pickup',
    this.packedIndexes = const <int>[],
    this.cancelReason,
    this.cancelledByCustomer = false,
    this.completedAt,
    this.itemsSummary,
    this.itemCountHint,
  });

  /// Firestore document id.
  final String id;

  /// Short number shown to people, for example "LM1024".
  final String orderNumber;
  final String shopId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final DateTime pickupTime;
  final DateTime createdAt;
  final String paymentMethod;

  /// Positions in [items] that are already ticked on the packing checklist.
  final List<int> packedIndexes;

  /// Why the shop rejected the order. Only set for cancelled orders.
  final String? cancelReason;

  /// True when the customer cancelled the order themselves, not the shop.
  final bool cancelledByCustomer;

  /// When the customer collected the order.
  final DateTime? completedAt;

  /// Text description of the items, for orders that arrive without an
  /// item-by-item list, for example "3 items (Carrots, Milk, Bread)".
  final String? itemsSummary;

  /// Number of items, for orders that arrive without an item-by-item list.
  final int? itemCountHint;

  /// True when the order has a real item list (needed for the checklist).
  bool get hasItemList => items.isNotEmpty;

  int get itemCount => items.isNotEmpty ? items.length : (itemCountHint ?? 0);

  String get itemCountLabel => itemCount == 1 ? '1 item' : '$itemCount items';

  /// New and Preparing orders are the ones the shop still has to work on.
  bool get needsAction =>
      status == OrderStatus.newOrder || status == OrderStatus.preparing;

  /// How many checklist items are ticked.
  int get packedCount => packedIndexes
      .where((index) => index >= 0 && index < items.length)
      .length;

  /// True when the customer has already paid in the app (card payment).
  bool get isPaidOnline {
    final method = paymentMethod.toLowerCase();
    return method.contains('online') || method.contains('card');
  }

  /// Short payment text for cards and lists.
  String get paymentLabel => isPaidOnline ? 'Paid Online' : 'Pay at Store';

  /// The day a completed order counts towards in the sales summary.
  DateTime get saleDate => completedAt ?? pickupTime;

  ShopOrder copyWith({
    OrderStatus? status,
    List<int>? packedIndexes,
    String? cancelReason,
    DateTime? completedAt,
  }) {
    return ShopOrder(
      id: id,
      orderNumber: orderNumber,
      shopId: shopId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      items: items,
      total: total,
      status: status ?? this.status,
      pickupTime: pickupTime,
      createdAt: createdAt,
      paymentMethod: paymentMethod,
      packedIndexes: packedIndexes ?? this.packedIndexes,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledByCustomer: cancelledByCustomer,
      completedAt: completedAt ?? this.completedAt,
      itemsSummary: itemsSummary,
      itemCountHint: itemCountHint,
    );
  }

  factory ShopOrder.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    final rawItems = map['items'] as List<dynamic>? ?? const <dynamic>[];
    final rawPacked =
        map['packedIndexes'] as List<dynamic>? ?? const <dynamic>[];

    return ShopOrder(
      id: id,
      orderNumber: map['orderNumber'] as String? ?? id,
      shopId: map['shopId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? 'Customer',
      customerPhone: map['customerPhone'] as String? ?? '',
      items: rawItems
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      total: (map['total'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.fromValue(map['status'] as String?),
      pickupTime: readDate(map['pickupTime']) ?? now,
      createdAt: readDate(map['createdAt']) ?? now,
      paymentMethod:
          map['paymentMethod'] as String? ?? 'Pay on Counter Pickup',
      packedIndexes:
          rawPacked.whereType<num>().map((n) => n.toInt()).toList(),
      cancelReason: map['cancelReason'] as String?,
      completedAt: readDate(map['completedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'shopId': shopId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'itemCount': itemCount,
      'total': total,
      'status': status.value,
      'pickupTime': writeDate(pickupTime),
      'createdAt': writeDate(createdAt),
      'paymentMethod': paymentMethod,
      'packedIndexes': packedIndexes,
      'cancelReason': cancelReason,
      'completedAt': writeDate(completedAt),
    };
  }
}
