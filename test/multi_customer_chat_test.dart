import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dashgrocer/services/chat_service.dart';
import 'package:dashgrocer/views/shop_owner/chat/shop_owner_conversations_screen.dart';
import 'package:dashgrocer/views/shop_owner/dashboard/widgets/customer_inquiries_section.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    ChatService().clearChat();
  });

  tearDown(() {
    ChatService().cancelPendingTimers();
  });

  group('Multi-Customer Chat Isolation & Seller Dashboard Display Tests', () {
    testWidgets('1. Different customers have separate conversation threads in ChatService', (tester) async {
      final chatService = ChatService();
      chatService.clearChat();

      // Customer 1: Amal Perera sends a message
      await chatService.sendCustomerMessage(
        text: 'Do you have red onions in stock?',
        customerId: 'cust_amal_123',
        customerName: 'Amal Perera',
        customerPhone: '+94 77 999 8888',
        simulateAutoReply: false,
      );

      // Customer 2: Nimalka Silva sends a message
      await chatService.sendCustomerMessage(
        text: 'Can I pick up my order around 7 PM?',
        customerId: 'cust_nimalka_456',
        customerName: 'Nimalka Silva',
        customerPhone: '+94 71 555 4444',
        simulateAutoReply: false,
      );

      // Get grouped conversations for seller dashboard
      final conversations = chatService.getCustomerConversations();

      // Must have conversations for both Amal, Nimalka and default Kasun
      final amalConv = conversations.firstWhere((c) => c.customerId == 'cust_amal_123');
      final nimalkaConv = conversations.firstWhere((c) => c.customerId == 'cust_nimalka_456');

      expect(amalConv.customerName, 'Amal Perera');
      expect(amalConv.lastMessage.text, 'Do you have red onions in stock?');
      expect(amalConv.unreadCount, 1);

      expect(nimalkaConv.customerName, 'Nimalka Silva');
      expect(nimalkaConv.lastMessage.text, 'Can I pick up my order around 7 PM?');
      expect(nimalkaConv.unreadCount, 1);

      // Verify thread isolation: Amal only has 1 message
      final amalMessages = chatService.getMessagesForCustomer('cust_amal_123');
      expect(amalMessages.any((m) => m.text == 'Do you have red onions in stock?'), isTrue);
      expect(amalMessages.any((m) => m.text == 'Can I pick up my order around 7 PM?'), isFalse);

      // Verify thread isolation: Nimalka only has 1 message
      final nimalkaMessages = chatService.getMessagesForCustomer('cust_nimalka_456');
      expect(nimalkaMessages.any((m) => m.text == 'Can I pick up my order around 7 PM?'), isTrue);
      expect(nimalkaMessages.any((m) => m.text == 'Do you have red onions in stock?'), isFalse);
    });

    testWidgets('2. CustomerInquiriesSection on Seller Dashboard shows each customer name and message', (tester) async {
      final chatService = ChatService();
      chatService.clearChat();

      await chatService.sendCustomerMessage(
        text: 'Do you have fresh organic spinach?',
        customerId: 'cust_amal_123',
        customerName: 'Amal Perera',
        customerPhone: '+94 77 999 8888',
        simulateAutoReply: false,
      );

      await chatService.sendCustomerMessage(
        text: 'Please pack in extra paper bags.',
        customerId: 'cust_nimalka_456',
        customerName: 'Nimalka Silva',
        customerPhone: '+94 71 555 4444',
        simulateAutoReply: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomerInquiriesSection(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Customer Inquiries header is rendered
      expect(find.text('Customer Inquiries'), findsOneWidget);

      // Verify Customer Names are explicitly shown
      expect(find.text('Amal Perera'), findsOneWidget);
      expect(find.text('Nimalka Silva'), findsOneWidget);

      // Verify messages are rendered with customer attribution
      expect(find.textContaining('Do you have fresh organic spinach?'), findsOneWidget);
      expect(find.textContaining('Please pack in extra paper bags.'), findsOneWidget);

      // Verify initials
      expect(find.text('AP'), findsOneWidget);
      expect(find.text('NS'), findsWidgets);
    });

    testWidgets('3. ShopOwnerConversationsScreen lists all distinct customer conversations with search', (tester) async {
      final chatService = ChatService();
      chatService.clearChat();

      await chatService.sendCustomerMessage(
        text: 'Are highland carrots available?',
        customerId: 'cust_amal_123',
        customerName: 'Amal Perera',
        simulateAutoReply: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopOwnerConversationsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Customer Messages'), findsOneWidget);
      expect(find.text('Amal Perera'), findsOneWidget);
      expect(find.text('Are highland carrots available?'), findsOneWidget);

      // Test Search
      await tester.enterText(find.byType(TextField), 'Amal');
      await tester.pumpAndSettle();
      expect(find.text('Amal Perera'), findsOneWidget);
    });

    testWidgets('4. Seller reply to Customer A does not leak to Customer B', (tester) async {
      final chatService = ChatService();
      chatService.clearChat();

      // Customer A message
      await chatService.sendCustomerMessage(
        text: 'Can I pick up at 5 PM?',
        customerId: 'cust_amal_123',
        customerName: 'Amal Perera',
        simulateAutoReply: false,
      );

      // Customer B message
      await chatService.sendCustomerMessage(
        text: 'Are eggs fresh?',
        customerId: 'cust_nimalka_456',
        customerName: 'Nimalka Silva',
        simulateAutoReply: false,
      );

      // Seller replies to Customer A (Amal)
      await chatService.sendSellerMessage(
        text: 'Yes Amal, counter #1 will have it ready at 5 PM!',
        customerId: 'cust_amal_123',
        customerName: 'Amal Perera',
        simulateAutoReply: false,
      );

      // Check Amal's messages
      final amalMsgs = chatService.getMessagesForCustomer('cust_amal_123');
      expect(amalMsgs.any((m) => m.text.contains('Yes Amal')), isTrue);

      // Check Nimalka's messages: Seller reply to Amal MUST NOT appear
      final nimalkaMsgs = chatService.getMessagesForCustomer('cust_nimalka_456');
      expect(nimalkaMsgs.any((m) => m.text.contains('Yes Amal')), isFalse);
    });
  });
}
