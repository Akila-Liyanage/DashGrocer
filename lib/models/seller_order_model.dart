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
    );
  }

  String get formattedTotal => 'Rs. ${totalAmount.toStringAsFixed(0)}';
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

class CustomerNotification {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final String? orderId;
  final bool isRead;

  const CustomerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.orderId,
    this.isRead = false,
  });

  CustomerNotification copyWith({bool? isRead}) {
    return CustomerNotification(
      id: id,
      title: title,
      message: message,
      time: time,
      orderId: orderId,
      isRead: isRead ?? this.isRead,
    );
  }
}
