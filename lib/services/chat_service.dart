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
  bool _isCustomerTyping = false;
  bool _isBotAutoReplyEnabled = true;

  List<ChatMessage> get allMessages => List.unmodifiable(_messages);
  bool get isSellerTyping => _isSellerTyping;
  bool get isCustomerTyping => _isCustomerTyping;
  bool get isBotAutoReplyEnabled => _isBotAutoReplyEnabled;

  void toggleBotAutoReply([bool? value]) {
    _isBotAutoReplyEnabled = value ?? !_isBotAutoReplyEnabled;
    notifyListeners();
  }

  void initFirebaseListeners() {
    _listenToFirestore();
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
          final Map<String, ChatMessage> map = {
            for (final m in _messages) m.id: m,
          };
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              final msg = ChatMessage.fromMap(data);
              map[msg.id] = msg;
            } catch (e) {
              debugPrint('Error parsing chat message doc ${doc.id}: $e');
            }
          }
          final sorted = map.values.toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _messages.clear();
          _messages.addAll(sorted);
          notifyListeners();
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
        final docId = _messages[i].id;
        try {
          _firestore
              ?.collection('chat_messages')
              .doc(docId)
              .set({'isRead': true}, SetOptions(merge: true))
              .catchError((e) {
            debugPrint('Firestore update read notice: $e');
          });
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
        final docId = _messages[i].id;
        try {
          _firestore
              ?.collection('chat_messages')
              .doc(docId)
              .set({'isRead': true}, SetOptions(merge: true))
              .catchError((e) {
            debugPrint('Firestore update read notice: $e');
          });
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
        final docId = _messages[i].id;
        try {
          _firestore
              ?.collection('chat_messages')
              .doc(docId)
              .set({'isRead': true}, SetOptions(merge: true))
              .catchError((e) {
            debugPrint('Firestore update read notice: $e');
          });
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
    String? orderId,
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
      orderId: orderId,
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

    // Interactive customer response simulation
    if (_isBotAutoReplyEnabled) {
      _simulateCustomerReply(trimmed);
    }
  }

  Future<void> sendCustomerMessage({
    required String text,
    GroceryItem? product,
    bool isQuickInquiry = false,
    String? attachmentUrl,
    bool? simulateAutoReply,
    String? orderId,
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
      orderId: orderId,
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
        orderId: orderId ?? product?.id ?? '#INQUIRY',
      );
    } catch (_) {}

    // Auto-reply simulation
    final shouldSimulate = simulateAutoReply ?? _isBotAutoReplyEnabled;
    if (shouldSimulate) {
      _simulateSellerReply(trimmed, product);
    }
  }

  Timer? _typingTimer;
  Timer? _replyTimer;
  Timer? _customerTypingTimer;
  Timer? _customerReplyTimer;

  void cancelPendingTimers() {
    _typingTimer?.cancel();
    _replyTimer?.cancel();
    _customerTypingTimer?.cancel();
    _customerReplyTimer?.cancel();
    _isSellerTyping = false;
    _isCustomerTyping = false;
  }

  void _simulateCustomerReply(String sellerText) {
    _customerTypingTimer?.cancel();
    _customerReplyTimer?.cancel();

    final lower = sellerText.toLowerCase();
    String replyText;
    if (lower.contains('ready') || lower.contains('prepared') || lower.contains('packing') || lower.contains('start')) {
      replyText = 'Thank you so much Sunil! 🙏 I am on my way to pick it up.';
    } else if (lower.contains('fresh') || lower.contains('harvest') || lower.contains('organic')) {
      replyText = 'Sounds wonderful! Really appreciate the quality farm produce.';
    } else if (lower.contains('counter') || lower.contains('pickup') || lower.contains('arrive')) {
      replyText = 'Understood! I will come straight to counter #1 with my order ID.';
    } else if (lower.contains('bag') || lower.contains('pack')) {
      replyText = 'Thank you for packing it so carefully!';
    } else if (lower.contains('call') || lower.contains('phone')) {
      replyText = 'Noted, thank you for checking with me!';
    } else {
      replyText = 'Thank you for the update Sunil! See you at the store soon. 👍';
    }

    _customerTypingTimer = Timer(const Duration(milliseconds: 650), () {
      _isCustomerTyping = true;
      notifyListeners();

      _customerReplyTimer = Timer(const Duration(milliseconds: 1200), () {
        _isCustomerTyping = false;
        final custMsg = ChatMessage(
          id: 'msg_cust_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'cust_kasun',
          senderName: 'Kasun Perera',
          senderRole: 'customer',
          text: replyText,
          timestamp: DateTime.now(),
          isRead: false,
        );
        _messages.add(custMsg);
        notifyListeners();

        try {
          final db = _firestore;
          if (db != null) {
            db.collection('chat_messages').doc(custMsg.id).set(custMsg.toMap());
          }
        } catch (_) {}
      });
    });
  }

  void _simulateSellerReply(String query, GroceryItem? product) {
    cancelPendingTimers();
    final lower = query.toLowerCase();

    String replyText;
    final pName = product?.name ?? 'produce';

    if (lower.contains('ayubowan')) {
      replyText = 'Ayubowan! 🙏 Welcome to GreenLeaf Fresh Mart. How can we help you with your DashGrocer order or store pickup today?';
    } else if (lower.contains('kohomada') || lower.contains('saniipen')) {
      replyText = 'Saniipen innawa, sthuthiyi! Obe grocery pre-order eka sambandawa oneyma deyak ahananna. Api udaw karannam.';
    } else if (lower.contains('fp-2028-0142') || (lower.contains('order') && (lower.contains('status') || lower.contains('ready') || lower.contains('placed')))) {
      replyText = 'Yes Kasun! Your pickup order #FP-2028-0142 with highland carrots and fresh tomatoes is verified and ready for pickup at counter #1.';
    } else if (lower.contains('fresh') || lower.contains('harvest') || lower.contains('quality')) {
      replyText = 'Yes! All our $pName arrived directly from local organic farms at 6:00 AM today. They are crisp, 100% fresh, and pesticide-free.';
    } else if (lower.contains('pickup') || lower.contains('time') || lower.contains('mins') || lower.contains('hour') || lower.contains('counter')) {
      replyText = 'Yes, you can pick it up today! Orders are packed within 15 minutes of checkout at our Maharagama store. We are open until 9:30 PM.';
    } else if (lower.contains('portion') || lower.contains('cut') || lower.contains('half') || lower.contains('250g') || lower.contains('500g') || lower.contains('1kg')) {
      replyText = 'Certainly! We gladly pack smaller portions or custom sizes for you. Just leave a note at checkout or let us know here.';
    } else if (lower.contains('discount') || lower.contains('price') || lower.contains('bulk') || lower.contains('keeyada') || lower.contains('mila')) {
      replyText = 'We provide farm-direct prices plus an extra 5% discount for bulk orders over 3kg! Plus you can use your loyalty points at pickup.';
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
    } else if (lower.contains('hour') || lower.contains('open') || lower.contains('close')) {
      replyText = 'GreenLeaf Fresh Mart is open daily from 7:30 AM until 9:30 PM. Curbside pickup counters are staffed throughout open hours.';
    } else if (lower.contains('thanks') || lower.contains('thank') || lower.contains('sthuti')) {
      replyText = 'You are most welcome! 🙏 Looking forward to seeing you at GreenLeaf Fresh Mart.';
    } else {
      if (!_hasSentInitialThankYou) {
        replyText = 'Thank you for your message! Our team at GreenLeaf Fresh Mart has noted your inquiry about $pName. We have plenty in stock and ready for your order!';
      } else {
        replyText = 'Our team at GreenLeaf Fresh Mart has noted this. We are packing orders actively and ready to assist you at pickup counter #1!';
      }
    }

    _typingTimer = Timer(const Duration(milliseconds: 500), () {
      _isSellerTyping = true;
      notifyListeners();

      _replyTimer = Timer(const Duration(milliseconds: 800), () {
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
