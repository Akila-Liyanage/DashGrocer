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
  });

  bool get isFromCustomer => senderRole == 'customer';
  bool get isFromSeller => senderRole == 'seller';

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
    return ChatMessage(
      id: map['id'] as String? ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderRole: map['senderRole'] as String? ?? 'customer',
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
    );
  }
}
