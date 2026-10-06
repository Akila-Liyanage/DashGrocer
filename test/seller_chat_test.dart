import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashgrocer/models/grocery_item_model.dart';
import 'package:dashgrocer/services/chat_service.dart';
import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/customer/product_detail_screen.dart';
import 'package:dashgrocer/views/customer/seller_chat_screen.dart';

void main() {
  group('Seller Details & Live Chat Tests', () {
    late GroceryItem testPumpkin;

    setUp(() {
      final groceryService = GroceryService();
      testPumpkin = groceryService.getItemById('pumpkin')!;
    });

    testWidgets('1. Product Detail Screen displays rich Seller & Store Information card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailScreen(item: testPumpkin),
        ),
      );
      await tester.pumpAndSettle();

      // Verify seller card elements
      expect(find.text('Seller & Store Information'), findsOneWidget);
      expect(find.text('Verified Seller'), findsOneWidget);
      expect(find.text('GreenLeaf Fresh Mart'), findsOneWidget);
      expect(find.text('Posted by Sunil Weerasinghe'), findsOneWidget);
      expect(find.text('Store Rating'), findsOneWidget);
      expect(find.text('Chat with Seller'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
    });

    testWidgets('2. Tapping Chat with Seller opens SellerChatScreen with Pinned Product Banner', (tester) async {
      final chatService = ChatService();
      chatService.clearChat();

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailScreen(item: testPumpkin),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on-screen Chat with Seller icon button
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded).first);
      await tester.pumpAndSettle();

      // Verify SellerChatScreen elements
      expect(find.byType(SellerChatScreen), findsOneWidget);
      expect(find.text('INQUIRING PRODUCT'), findsOneWidget);
      expect(find.text('Fresh Pumpkin'), findsOneWidget);
      expect(find.text('Sunil Weerasinghe • Online'), findsOneWidget);
      expect(find.text('🌱 Is this freshly harvested today?'), findsOneWidget);

      chatService.cancelPendingTimers();
    });

    testWidgets('3. Sending a quick inquiry pill adds customer message and updates chat', (tester) async {
      final chatService = ChatService();
      chatService.clearChat();

      await tester.pumpWidget(
        MaterialApp(
          home: SellerChatScreen(
            product: testPumpkin,
            shopName: 'GreenLeaf Fresh Mart',
            sellerName: 'Sunil Weerasinghe',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on quick inquiry chip
      final quickChip = find.text('🌱 Is this freshly harvested today?');
      expect(quickChip, findsOneWidget);
      await tester.tap(quickChip);
      await tester.pump();

      // Verify message appears in conversation
      expect(find.text('🌱 Is this freshly harvested today?'), findsWidgets);

      // Advance clock to let seller reply complete
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 1100));

      chatService.cancelPendingTimers();
    });

    testWidgets('4. In-chat search filters messages and popup menu opens clear chat dialog', (tester) async {
      final chatService = ChatService();
      chatService.clearChat();

      await tester.pumpWidget(
        MaterialApp(
          home: SellerChatScreen(
            product: testPumpkin,
            shopName: 'GreenLeaf Fresh Mart',
            sellerName: 'Sunil Weerasinghe',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap search icon in AppBar
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      // Verify search input field is visible
      expect(find.byType(TextField), findsNWidgets(2)); // search field + message input field

      // Close search to restore full AppBar actions
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Open clear chat dialog via popup menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Clear Chat History'), findsOneWidget);
      await tester.tap(find.text('Clear Chat History'));
      await tester.pumpAndSettle();

      expect(find.text('Clear Conversation?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      chatService.cancelPendingTimers();
    });
  });
}
