import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashgrocer/models/grocery_item_model.dart';
import 'package:dashgrocer/models/user_model.dart';
import 'package:dashgrocer/services/auth_service.dart';
import 'package:dashgrocer/services/grocery_service.dart';
import 'package:dashgrocer/views/customer/customer_dashboard.dart';
import 'package:dashgrocer/views/customer/pickup_time_screen.dart';
import 'package:dashgrocer/views/customer/order_history_screen.dart';
import 'package:dashgrocer/views/customer/reviews_screen.dart';
import 'package:dashgrocer/views/shop_owner/shop_owner_dashboard.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AuthService.simulatedDelay = Duration.zero;
  });

  const testCustomer = UserModel(
    id: 'cust_01',
    email: 'customer@dashgrocer.com',
    fullName: 'Kasun Perera',
    phoneNumber: '+94 77 123 4567',
    role: UserRole.customer,
  );

  const testSeller = UserModel(
    id: 'owner_01',
    email: 'owner@dashgrocer.com',
    fullName: 'Sunil Weerasinghe',
    phoneNumber: '+94 71 987 6543',
    role: UserRole.shopOwner,
    shopName: 'GreenLeaf Fresh Mart',
    shopAddress: 'No. 42, High Level Road, Maharagama',
  );

  group('Complete End-to-End System & Flow Verification', () {
    testWidgets('Flow 1: Customer Cart Checkout -> Pickup Time Selection -> Order Confirmed -> Track Order', (WidgetTester tester) async {
      PickupTimeScreen.clock = () => DateTime(2026, 10, 12, 8, 0);
      addTearDown(() => PickupTimeScreen.clock = DateTime.now);
      final groceryService = GroceryService();
      groceryService.addToCart('pumpkin', 2);

      await tester.pumpWidget(
        const MaterialApp(
          home: PickupTimeScreen(
            shopName: 'Green mart',
            shopAddress: '123 Main Street • Open until 9 PM',
            totalAmount: 2900.0,
          ),
        ),
      );
      await tester.pump();

      // Verify Pickup screen elements
      expect(find.text('Pickup Time'), findsOneWidget);
      expect(find.text('Green mart'), findsOneWidget);
      expect(find.text('Today , Mon 12 Oct'), findsOneWidget);
      expect(find.text('Continue to Payment'), findsOneWidget);

      // Select time slot
      await tester.tap(find.text('2.00 PM').first); // today's slot (listed first)
      await tester.pump();

      // Tap Continue to Payment
      await tester.tap(find.text('Continue to Payment'));
      await tester.pumpAndSettle();

      // Payment Method screen: choose Pay at Store and place the order
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('Pay at Store'), findsOneWidget);
      expect(find.text('Credit Card'), findsOneWidget);
      await tester.tap(find.text('Pay at Store'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify navigation to Order Confirmation screen
      expect(find.text('Order Confirmed'), findsOneWidget);
      expect(find.text('Thank You!'), findsOneWidget);
      expect(find.text('Track Order'), findsOneWidget);

      // Tap Track Order
      await tester.tap(find.text('Track Order'));
      await tester.pumpAndSettle();

      // Verify Track Order screen with timeline steps
      expect(find.text('Track Order'), findsWidgets);
      expect(find.text('Order Placed'), findsOneWidget);
      expect(find.text('Order Confirmed'), findsWidgets);
      expect(find.text('Order Prepared'), findsOneWidget);
      expect(find.text('Ready for Pickup'), findsOneWidget);
    });

    testWidgets('Flow 2: Customer Order creates incoming order in Seller Dashboard and triggers Notification', (WidgetTester tester) async {
      final groceryService = GroceryService();
      final beforeNotifCount = groceryService.unreadNotificationsCount;

      // Simulate customer placing order
      final orderId = groceryService.placeOrder(
        customerName: 'Anuki Jayawardena',
        customerPhone: '+94 77 444 8899',
        pickupSlot: 'Today, 5.00 PM',
        totalAmount: 1850.0,
        shopName: 'GreenLeaf Fresh Mart',
      );

      // Verify unread notifications increased
      expect(groceryService.unreadNotificationsCount, beforeNotifCount + 1);

      // Render Seller Dashboard
      await tester.pumpWidget(
        const MaterialApp(
          home: ShopOwnerDashboard(user: testSeller),
        ),
      );
      await tester.pump();

      // Verify incoming order appears in orders list
      expect(find.text(orderId), findsOneWidget);
      expect(find.text('Anuki Jayawardena'), findsOneWidget);
      expect(find.text('Incoming Pickup Orders'), findsOneWidget);

      // Tap Mark Ready for Pickup
      await tester.tap(find.text('Mark Ready for Pickup').first);
      await tester.pump();

      // Verify status changed to Ready for Pickup
      expect(groceryService.sellerOrders.first.status, 'Ready for Pickup');
    });

    testWidgets('Flow 3: Seller publishes a new product and it reflects immediately on Customer Catalog', (WidgetTester tester) async {
      final groceryService = GroceryService();

      const newStrawberry = GroceryItem(
        id: 'strawberries_fresh',
        name: 'Fresh Organic Strawberries',
        unit: '250g',
        price: 950.0,
        category: 'Fruits',
        imageUrl: 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?auto=format&fit=crop&w=500&q=80',
        sellerId: 'owner_01',
        sellerName: 'GreenLeaf Fresh Mart',
      );

      groceryService.addProduct(newStrawberry);

      // Render Customer Dashboard
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerDashboard(user: testCustomer),
        ),
      );
      await tester.pump();

      // Verify customer can see the new product on home screen
      expect(find.text('Fresh Organic Strawberries'), findsOneWidget);
      expect(find.text('Rs 950.00'), findsOneWidget);
    });

    testWidgets('Flow 4: Customer Order History & Reviews Screen verification', (WidgetTester tester) async {
      // Test Order History Screen
      await tester.pumpWidget(
        const MaterialApp(
          home: OrderHistoryScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Order History'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Track Order'), findsWidgets);

      // Test Reviews Screen
      await tester.pumpWidget(
        const MaterialApp(
          home: ReviewsScreen(productName: 'Fresh Chicken Breast'),
        ),
      );
      await tester.pump();

      expect(find.text('Reviews'), findsOneWidget);
      expect(find.text('4.7'), findsOneWidget); // worked out from the 125 earlier reviews
      expect(find.text('Write a review'), findsOneWidget);
      expect(find.text('Back To Home'), findsOneWidget);
    });
  });
}
