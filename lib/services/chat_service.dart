import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../models/grocery_item_model.dart';
import 'grocery_service.dart';

class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  ChatService._internal() {
    _initDefaultChat();
    _listenToFirestore();
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSub;
  final List<ChatMessage> _messages = [];
  bool _isSellerTyping = false;
  bool _isBotAutoReplyEnabled = false;

  List<ChatMessage> get allMessages => List.unmodifiable(_messages);
  bool get isSellerTyping => _isSellerTyping;
  bool get isBotAutoReplyEnabled => _isBotAutoReplyEnabled;

  void toggleBotAutoReply([bool? value]) {
    _isBotAutoReplyEnabled = value ?? !_isBotAutoReplyEnabled;
    notifyListeners();
  }

  void _listenToFirestore() {
    final db = _firestore;
    if (db == null) return;
    try {
      _firestoreSub?.cancel();
      _firestoreSub = db
          .collection('chat_messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final firestoreMessages = <ChatMessage>[];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              firestoreMessages.add(ChatMessage.fromMap(data));
            } catch (e) {
              debugPrint('Error parsing chat message doc ${doc.id}: $e');
            }
          }
          if (firestoreMessages.isNotEmpty) {
            _messages.clear();
            _messages.addAll(firestoreMessages);
            notifyListeners();
          }
        }
      }, onError: (err) {
        debugPrint('[ChatService] Firestore listener notice: $err');
      });
    } catch (e) {
      debugPrint('[ChatService] Could not initialize Firestore listener: $e');
    }
  }

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
      ChatMessage(
        id: 'msg_kasun_inquiry',
        senderId: 'cust_kasun',
        senderName: 'Kasun Perera',
        senderRole: 'customer',
        text: 'Hello! I placed pickup order #FP-2028-0142. Are the highland carrots and tomatoes ready?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        isRead: false,
      ),
    ]);
  }

  List<ChatMessage> getMessagesForProduct(String productId) {
    return _messages.where((m) => m.productId == null || m.productId == productId).toList();
  }

  int get customerUnreadCount => _messages.where((m) => m.isFromSeller && !m.isRead).length;
  int get sellerUnreadCount => _messages.where((m) => m.isFromCustomer && !m.isRead).length;
  int get unreadCount => customerUnreadCount;

  void markAllAsReadBySeller() {
    bool changed = false;
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].isFromCustomer && !_messages[i].isRead) {
        _messages[i] = _messages[i].copyWith(isRead: true);
        changed = true;
        try {
          _firestore?.collection('chat_messages').doc(_messages[i].id).update({'isRead': true});
        } catch (_) {}
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void markAllAsReadByCustomer() {
    bool changed = false;
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].isFromSeller && !_messages[i].isRead) {
        _messages[i] = _messages[i].copyWith(isRead: true);
        changed = true;
        try {
          _firestore?.collection('chat_messages').doc(_messages[i].id).update({'isRead': true});
        } catch (_) {}
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _messages.length; i++) {
      if (!_messages[i].isRead) {
        _messages[i] = _messages[i].copyWith(isRead: true);
        changed = true;
        try {
          _firestore?.collection('chat_messages').doc(_messages[i].id).update({'isRead': true});
        } catch (_) {}
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  Future<void> sendSellerMessage({
    required String text,
    String? sellerName,
    String? attachmentUrl,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final sellerMsg = ChatMessage(
      id: 'msg_seller_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'seller_sunil',
      senderName: sellerName ?? 'Sunil Weerasinghe (GreenLeaf Mart)',
      senderRole: 'seller',
      text: trimmed,
      timestamp: DateTime.now(),
      isRead: false,
      attachmentUrl: attachmentUrl,
    );

    _messages.add(sellerMsg);
    notifyListeners();

    // Persist to Cloud Firestore for real-time multi-device sync
    try {
      final db = _firestore;
      if (db != null) {
        await db.collection('chat_messages').doc(sellerMsg.id).set(sellerMsg.toMap());
      }
    } catch (_) {}
  }

  Future<void> sendCustomerMessage({
    required String text,
    GroceryItem? product,
    bool isQuickInquiry = false,
    String? attachmentUrl,
    bool? simulateAutoReply,
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
      attachmentUrl: attachmentUrl,
      isRead: false,
    );

    _messages.add(customerMsg);
    notifyListeners();

    // Persist to Cloud Firestore for real-time multi-device sync
    try {
      final db = _firestore;
      if (db != null) {
        await db.collection('chat_messages').doc(customerMsg.id).set(customerMsg.toMap());
      }
    } catch (_) {}

    // Trigger seller notification in GroceryService
    try {
      final groceryService = GroceryService();
      groceryService.addSellerNotification(
        title: 'New Customer Inquiry',
        message: 'Kasun Perera asked: "$trimmed"${product != null ? " regarding ${product.name}" : ""}',
        orderId: product?.id ?? '#INQUIRY',
      );
    } catch (_) {}

    // Only auto-reply if explicitly requested or if bot mode is turned on
    final shouldSimulate = simulateAutoReply ?? _isBotAutoReplyEnabled;
    if (shouldSimulate) {
      _simulateSellerReply(trimmed, product);
    }
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
    } else if (lower.contains('pay') || lower.contains('card') || lower.contains('cash') || lower.contains('koko')) {
      replyText = 'We accept all Visa/Mastercard payments online, as well as Cash or Card on Store Pickup. We also support Koko installment checkouts!';
    } else if (lower.contains('bag') || lower.contains('pack') || lower.contains('paper') || lower.contains('plastic')) {
      replyText = 'Yes! We pack all produce in eco-friendly biodegradable craft paper bags and recyclable containers with zero plastic waste.';
    } else if (lower.contains('hour') || lower.contains('open') || lower.contains('close') || lower.contains('time')) {
      replyText = 'GreenLeaf Fresh Mart is open daily from 7:30 AM until 9:30 PM. Curbside pickup counters are staffed throughout open hours.';
    } else {
      // Show initial Thank You acknowledgement only ONCE; do not repeat for every subsequent message
      if (_hasSentInitialThankYou) {
        return;
      }
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

        // Also sync to Cloud Firestore
        try {
          final db = _firestore;
          if (db != null) {
            db.collection('chat_messages').doc(sellerMsg.id).set(sellerMsg.toMap());
          }
        } catch (_) {}
      });
    });
  }

  bool get _hasSentInitialThankYou => _messages.any((m) =>
      m.isFromSeller &&
      (m.text.toLowerCase().contains('thank you for your message') ||
       m.text.toLowerCase().contains('noted your inquiry')));

  void clearChat() {
    cancelPendingTimers();
    _messages.clear();
    _initDefaultChat();
    notifyListeners();
  }
}
