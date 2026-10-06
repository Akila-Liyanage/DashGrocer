import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../models/grocery_item_model.dart';
import 'grocery_service.dart';

class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  ChatService._internal() {
    _initDefaultChat();
  }

  final List<ChatMessage> _messages = [];
  bool _isSellerTyping = false;

  List<ChatMessage> get allMessages => List.unmodifiable(_messages);
  bool get isSellerTyping => _isSellerTyping;

  void _initDefaultChat() {
    _messages.addAll([
      ChatMessage(
        id: 'msg_welcome',
        senderId: 'seller_sunil',
        senderName: 'Sunil Weerasinghe (GreenLeaf Mart)',
        senderRole: 'seller',
        text: 'Ayubowan! 🙏 Welcome to GreenLeaf Fresh Mart. Let us know if you have any questions about today\'s harvest or store pickup.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ]);
  }

  List<ChatMessage> getMessagesForProduct(String productId) {
    return _messages.where((m) => m.productId == null || m.productId == productId).toList();
  }

  int get unreadCount => _messages.where((m) => m.isFromSeller && !m.isRead).length;

  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _messages.length; i++) {
      if (!_messages[i].isRead) {
        _messages[i] = _messages[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  Future<void> sendCustomerMessage({
    required String text,
    GroceryItem? product,
    bool isQuickInquiry = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final customerMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'cust_kasun',
      senderName: 'Kasun Perera',
      senderRole: 'customer',
      text: trimmed,
      timestamp: DateTime.now(),
      productId: product?.id,
      productName: product?.name,
      productImageUrl: product?.imageUrl,
      isQuickInquiry: isQuickInquiry,
    );

    _messages.add(customerMsg);
    notifyListeners();

    // Trigger seller notification in GroceryService
    try {
      final groceryService = GroceryService();
      groceryService.addSellerNotification(
        title: 'New Customer Inquiry',
        message: 'Kasun Perera asked: "$trimmed"${product != null ? " regarding ${product.name}" : ""}',
        orderId: product?.id ?? '#INQUIRY',
      );
    } catch (_) {}

    // Simulate realistic intelligent seller reply
    _simulateSellerReply(trimmed, product);
  }

  Timer? _typingTimer;
  Timer? _replyTimer;

  void cancelPendingTimers() {
    _typingTimer?.cancel();
    _replyTimer?.cancel();
    _isSellerTyping = false;
  }

  void _simulateSellerReply(String query, GroceryItem? product) {
    cancelPendingTimers();
    final lower = query.toLowerCase();

    String replyText;
    final pName = product?.name ?? 'vegetables';

    if (lower.contains('fresh') || lower.contains('harvest') || lower.contains('quality')) {
      replyText = 'Yes! All our $pName arrived directly from local organic farms at 6:00 AM today. They are crisp, 100% fresh, and pesticide-free.';
    } else if (lower.contains('pickup') || lower.contains('time') || lower.contains('mins') || lower.contains('hour')) {
      replyText = 'Yes, you can pick it up today! Orders are packed within 15 minutes of checkout at our Maharagama store. We are open until 9:00 PM.';
    } else if (lower.contains('portion') || lower.contains('cut') || lower.contains('half') || lower.contains('250g')) {
      replyText = 'Certainly! We gladly pack smaller portions or custom sizes for you. Just leave a note at checkout or let us know here.';
    } else if (lower.contains('discount') || lower.contains('price') || lower.contains('bulk')) {
      replyText = 'We provide an extra 5% discount for bulk orders over 3kg! Plus you can use your loyalty points at pickup.';
    } else if (lower.contains('organic') || lower.contains('pesticide') || lower.contains('chemical')) {
      replyText = 'Absolutely! Our $pName is grown by certified eco-partner farmers without synthetic pesticides or harmful chemical sprays.';
    } else if (lower.contains('deliver') || lower.contains('shipping') || lower.contains('rider')) {
      replyText = 'We provide same-day express rider delivery within 5km, or quick 15-minute curbside pickup ready at our store counter.';
    } else if (lower.contains('refund') || lower.contains('return') || lower.contains('damaged') || lower.contains('guarantee')) {
      replyText = 'We provide a 100% freshness guarantee! If any item fails your quality expectations, we offer instant replacement or full credit at pickup.';
    } else {
      replyText = 'Thank you for your message! Our team at GreenLeaf Fresh Mart has noted your inquiry about $pName. We have plenty in stock and ready for your order!';
    }

    _typingTimer = Timer(const Duration(milliseconds: 600), () {
      _isSellerTyping = true;
      notifyListeners();

      _replyTimer = Timer(const Duration(milliseconds: 1000), () {
        _isSellerTyping = false;
        final sellerMsg = ChatMessage(
          id: 'msg_rep_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'seller_sunil',
          senderName: 'Sunil Weerasinghe (GreenLeaf Mart)',
          senderRole: 'seller',
          text: replyText,
          timestamp: DateTime.now(),
          productId: product?.id,
          productName: product?.name,
          productImageUrl: product?.imageUrl,
        );
        _messages.add(sellerMsg);
        notifyListeners();
      });
    });
  }

  void clearChat() {
    cancelPendingTimers();
    _messages.clear();
    _initDefaultChat();
    notifyListeners();
  }
}
