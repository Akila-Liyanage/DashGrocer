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
  final bool isRead;
  final bool isQuickInquiry;

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
    this.isRead = true,
    this.isQuickInquiry = false,
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
    bool? isRead,
    bool? isQuickInquiry,
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
      isRead: isRead ?? this.isRead,
      isQuickInquiry: isQuickInquiry ?? this.isQuickInquiry,
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
      'isRead': isRead,
      'isQuickInquiry': isQuickInquiry,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String? ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderRole: map['senderRole'] as String? ?? 'customer',
      text: map['text'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      productId: map['productId'] as String?,
      productName: map['productName'] as String?,
      productImageUrl: map['productImageUrl'] as String?,
      isRead: map['isRead'] as bool? ?? true,
      isQuickInquiry: map['isQuickInquiry'] as bool? ?? false,
    );
  }
}
