class StoreOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  final String itemsSummary;
  final double totalAmount;
  final String pickupSlot;
  final String shopName;
  final String status; // 'Pending', 'Preparing', 'Ready for Pickup', 'Completed', 'Cancelled'
  final DateTime createdAt;
  final bool isRead;
  final String paymentMethod; // 'Pay at Store' or 'Paid Online (Card)'

  /// Why the order was cancelled (only set for cancelled orders).
  final String? cancelReason;

  /// True when the customer cancelled it themselves (not the shop).
  final bool cancelledByCustomer;

  /// How many of each product (by product id) the order took from stock.
  /// Used to put the stock back if the order is cancelled.
  final Map<String, int> itemQuantities;

  const StoreOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.itemsSummary,
    required this.totalAmount,
    required this.pickupSlot,
    required this.shopName,
    this.status = 'Pending',
    required this.createdAt,
    this.isRead = false,
    this.paymentMethod = 'Pay at Store',
    this.cancelReason,
    this.cancelledByCustomer = false,
    this.itemQuantities = const <String, int>{},
  });

  bool get isReady => status == 'Ready for Pickup';
  bool get isCompleted => status == 'Completed';

  StoreOrder copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? itemsSummary,
    double? totalAmount,
    String? pickupSlot,
    String? shopName,
    String? status,
    DateTime? createdAt,
    bool? isRead,
    String? paymentMethod,
    String? cancelReason,
    bool? cancelledByCustomer,
  }) {
    return StoreOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      itemsSummary: itemsSummary ?? this.itemsSummary,
      totalAmount: totalAmount ?? this.totalAmount,
      pickupSlot: pickupSlot ?? this.pickupSlot,
      shopName: shopName ?? this.shopName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledByCustomer: cancelledByCustomer ?? this.cancelledByCustomer,
      itemQuantities: itemQuantities,
    );
  }

  String get formattedTotal => 'Rs. ${totalAmount.toStringAsFixed(0)}';

  /// The pickup time with a day that is right today. The slot is saved as
  /// "Today, 4.00 PM", but "Today" meant the day the order was placed, so this
  /// works out the real date: "Today, 4.00 PM", "Tomorrow, 9.00 AM",
  /// "Yesterday, 4.00 PM" or "Mon 12 Oct, 4.00 PM".
  String pickupLabel({DateTime? now}) {
    final timeMatch = RegExp(r'(\d{1,2}[.:]\d{2}\s*[AaPp][Mm])').firstMatch(pickupSlot);
    if (timeMatch == null) return pickupSlot;
    final time = timeMatch.group(1)!.replaceAll(RegExp(r'\s+'), ' ').toUpperCase();

    final slot = pickupSlot.toLowerCase();
    final offsetFromPlaced = slot.contains('tomorrow')
        ? 1
        : slot.contains('yesterday')
            ? -1
            : 0;
    final placedDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final pickupDay = DateTime(placedDay.year, placedDay.month, placedDay.day + offsetFromPlaced);

    final today = now ?? DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final daysAway = pickupDay.difference(todayDay).inDays;

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final String day;
    if (daysAway == 0) {
      day = 'Today';
    } else if (daysAway == 1) {
      day = 'Tomorrow';
    } else if (daysAway == -1) {
      day = 'Yesterday';
    } else {
      day = '${weekdays[pickupDay.weekday - 1]} ${pickupDay.day} ${months[pickupDay.month - 1]}';
    }
    return '$day, $time';
  }
}

class SellerNotification {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final String? orderId;
  final bool isRead;

  const SellerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.orderId,
    this.isRead = false,
  });

  SellerNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? time,
    String? orderId,
    bool? isRead,
  }) {
    return SellerNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      orderId: orderId ?? this.orderId,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// A notification shown to the customer (e.g. "Order Placed").
class CustomerNotification {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final DateTime time;
  final String? orderId;
  final bool isRead;

  const CustomerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.time,
    this.orderId,
    this.isRead = false,
  });

  CustomerNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? timeAgo,
    DateTime? time,
    String? orderId,
    bool? isRead,
  }) {
    return CustomerNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      time: time ?? this.time,
      orderId: orderId ?? this.orderId,
      isRead: isRead ?? this.isRead,
    );
  }
}
