enum MessageDeliveryStatus {
  sending,
  sent,
  delivered,
  read,
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'customer' or 'seller'
  final String text;
  final DateTime timestamp;
  final String? productId;
  final String? productName;
  final String? productImageUrl;
  final String? orderId;
  final bool isRead;
  final bool isQuickInquiry;
  final MessageDeliveryStatus deliveryStatus;
  final String? attachmentUrl;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.productId,
    this.productName,
    this.productImageUrl,
    this.orderId,
    this.isRead = true,
    this.isQuickInquiry = false,
    this.deliveryStatus = MessageDeliveryStatus.read,
    this.attachmentUrl,
    this.customerId,
    this.customerName,
    this.customerPhone,
  });

  bool get isFromCustomer => senderRole == 'customer';
  bool get isFromSeller => senderRole == 'seller';

  /// Resolves the customer ID associated with this chat thread
  String get effectiveCustomerId {
    if (customerId != null && customerId!.trim().isNotEmpty) {
      return customerId!.trim();
    }
    if (isFromCustomer && senderId.trim().isNotEmpty) {
      return senderId.trim();
    }
    return 'cust_kasun';
  }

  /// Resolves the customer name associated with this chat thread
  String get effectiveCustomerName {
    if (customerName != null && customerName!.trim().isNotEmpty) {
      return customerName!.trim();
    }
    if (isFromCustomer && senderName.trim().isNotEmpty) {
      return senderName.trim();
    }
    return 'Kasun Perera';
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? text,
    DateTime? timestamp,
    String? productId,
    String? productName,
    String? productImageUrl,
    String? orderId,
    bool? isRead,
    bool? isQuickInquiry,
    MessageDeliveryStatus? deliveryStatus,
    String? attachmentUrl,
    String? customerId,
    String? customerName,
    String? customerPhone,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      orderId: orderId ?? this.orderId,
      isRead: isRead ?? this.isRead,
      isQuickInquiry: isQuickInquiry ?? this.isQuickInquiry,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'orderId': orderId,
      'isRead': isRead,
      'isQuickInquiry': isQuickInquiry,
      'deliveryStatus': deliveryStatus.name,
      'attachmentUrl': attachmentUrl,
      'customerId': effectiveCustomerId,
      'customerName': effectiveCustomerName,
      'customerPhone': customerPhone,
    };
  }

  static DateTime _parseTimestamp(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    try {
      final dynamic dynamicVal = raw;
      final toDate = dynamicVal.toDate;
      if (toDate is Function) {
        final result = toDate();
        if (result is DateTime) return result;
      }
    } catch (_) {}
    return DateTime.now();
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final senderRole = map['senderRole'] as String? ?? 'customer';
    final senderId = map['senderId'] as String? ?? '';
    final senderName = map['senderName'] as String? ?? '';
    final explicitCustomerId = map['customerId'] as String?;
    final explicitCustomerName = map['customerName'] as String?;

    return ChatMessage(
      id: map['id'] as String? ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      text: map['text'] as String? ?? '',
      timestamp: _parseTimestamp(map['timestamp']),
      productId: map['productId'] as String?,
      productName: map['productName'] as String?,
      productImageUrl: map['productImageUrl'] as String?,
      orderId: map['orderId'] as String?,
      isRead: map['isRead'] as bool? ?? true,
      isQuickInquiry: map['isQuickInquiry'] as bool? ?? false,
      attachmentUrl: map['attachmentUrl'] as String?,
      deliveryStatus: map['deliveryStatus'] != null
          ? MessageDeliveryStatus.values.firstWhere(
              (e) => e.name == map['deliveryStatus'],
              orElse: () => MessageDeliveryStatus.read,
            )
          : MessageDeliveryStatus.read,
      customerId: explicitCustomerId ?? (senderRole == 'customer' ? senderId : null),
      customerName: explicitCustomerName ?? (senderRole == 'customer' ? senderName : null),
      customerPhone: map['customerPhone'] as String?,
    );
  }
}

/// Represents an aggregated conversation thread with a distinct customer
class ChatConversation {
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final ChatMessage lastMessage;
  final int unreadCount;
  final int totalMessages;
  final DateTime lastTimestamp;
  final String? latestOrderId;
  final String? latestProductName;

  const ChatConversation({
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.lastMessage,
    required this.unreadCount,
    required this.totalMessages,
    required this.lastTimestamp,
    this.latestOrderId,
    this.latestProductName,
  });

  /// Two-letter uppercase initials for avatar badge
  String get initials {
    final parts = customerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'CU';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// User-friendly relative time label
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(lastTimestamp);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastTimestamp.day}/${lastTimestamp.month}';
  }
}
