import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashgrocer/models/owner_profile.dart';
import 'package:dashgrocer/models/user_model.dart';
import 'package:dashgrocer/services/chat_service.dart';
import 'package:dashgrocer/services/mock_shop_repository.dart';
import 'package:dashgrocer/views/shop_owner/chat/shop_owner_chat_screen.dart';
import 'package:dashgrocer/views/shop_owner/shop_owner_shell.dart';
import 'package:dashgrocer/views/shop_owner/widgets/shop_owner_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    ChatService().clearChat();
  });

  tearDown(() {
    ChatService().cancelPendingTimers();
  });

  const testOwner = OwnerProfile(
    id: 'owner_01',
    fullName: 'Sunil Weerasinghe',
    email: 'sunil@greenleaf.lk',
    phoneNumber: '+94 71 987 6543',
  );

  group('Shop Owner Customer Chat Integration Tests', () {
    testWidgets('1. ShopOwnerChatScreen: renders customer header, messages, quick replies and input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShopOwnerChatScreen(
            customerName: 'Kasun Perera',
            customerPhone: '+94 77 123 4567',
            orderId: '#FP-2028-0142',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Customer header details
      expect(find.text('Kasun Perera'), findsOneWidget);
      expect(find.text('Customer • Online'), findsOneWidget);
      expect(find.text('KP'), findsOneWidget);
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);

      // Verify Order ribbon
      expect(find.textContaining('Order #FP-2028-0142'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);

      // Verify Quick replies and input field
      expect(find.text('👍 Your order is being prepared now!'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('2. ShopOwnerChatScreen: Seller can send message and customer message appears live', (tester) async {
      final chatService = ChatService();

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopOwnerChatScreen(
            customerName: 'Kasun Perera',
            customerPhone: '+94 77 123 4567',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type and send seller message
      await tester.enterText(find.byType(TextField), 'Your items are fresh and ready!');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Verify seller message is displayed
      expect(find.text('Your items are fresh and ready!'), findsOneWidget);
      expect(chatService.allMessages.any((m) => m.text == 'Your items are fresh and ready!'), isTrue);

      // Simulate incoming customer message
      await chatService.sendCustomerMessage(
        text: 'Great, I will be there in 10 minutes!',
        simulateAutoReply: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Great, I will be there in 10 minutes!'), findsOneWidget);
    });

    testWidgets('3. ShopOwnerAppBar: circular chat button is present with unread badge', (tester) async {
      final chatService = ChatService();
      // Add unread customer message
      await chatService.sendCustomerMessage(
        text: 'Hello, is the shop open?',
        simulateAutoReply: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ShopOwnerAppBar(
              owner: testOwner,
              onProfile: () {},
              onNotifications: () {},
              unreadCount: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify circular chat button icon
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      // Verify notification bell icon
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);

      // Tap circular chat button opens ShopOwnerChatScreen
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ShopOwnerChatScreen), findsOneWidget);
      expect(find.text('Kasun Perera'), findsOneWidget);
    });

    testWidgets('4. ShopOwnerShell: renders floating circular chat button with badge', (tester) async {
      final repository = MockShopRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ShopOwnerShell(
            repository: repository,
            shopId: 'shop_01',
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify floating circular chat button
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);

      // Tap floating circular chat button opens ShopOwnerChatScreen
      await tester.tap(find.byIcon(Icons.chat_bubble_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ShopOwnerChatScreen), findsOneWidget);
    });

    test('5. ChatService: Thank you acknowledgment is only sent once and does not repeat', () async {
      final chatService = ChatService();
      chatService.clearChat();

      // Send first message with auto reply
      await chatService.sendCustomerMessage(
        text: 'Hi',
        simulateAutoReply: true,
      );

      await Future.delayed(const Duration(milliseconds: 1700));

      final count1 = chatService.allMessages
          .where((m) => m.isFromSeller && m.text.contains('Thank you for your message'))
          .length;
      expect(count1, 1);

      // Send second message with auto reply
      await chatService.sendCustomerMessage(
        text: 'Aaa',
        simulateAutoReply: true,
      );

      await Future.delayed(const Duration(milliseconds: 1700));

      final count2 = chatService.allMessages
          .where((m) => m.isFromSeller && m.text.contains('Thank you for your message'))
          .length;
      // Must STILL be 1!
      expect(count2, 1);
    });
  });
}
